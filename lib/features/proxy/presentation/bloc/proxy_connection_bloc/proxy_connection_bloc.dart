import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/analytics/app_analytics_service.dart';
import '../../../../../core/dev/proxy_health_dev_control.dart';
import '../../../../settings/domain/entities/connection_settings_entity.dart';
import '../../../../settings/presentation/cubit/connection_settings_cubit.dart';
import '../../../../vpn/domain/entities/vpn_status_entity.dart';
import '../../../../vpn/presentation/bloc/vpn_connection_bloc/vpn_connection_bloc.dart';
import '../../../domain/entities/proxy_entity.dart';
import '../../../services/proxy_availability_service.dart';
import '../../../services/proxy_engine_service.dart';

part 'proxy_connection_event.dart';

/// Owns the live proxy session. Database health is never accepted as proof of
/// availability: candidates are checked on-device before connection and the
/// running outbound is monitored while connected.
class ProxyConnectionBloc
    extends Bloc<ProxyConnectionEvent, VpnConnectionState> {
  final ProxyEngineService engine;
  final ProxyAvailabilityService availability;
  final ConnectionSettingsCubit settings;

  StreamSubscription<String>? _stageSub;
  StreamSubscription<dynamic>? _statusSub;
  Timer? _connectTimeout;
  Timer? _healthTimer;
  DateTime? _suppressExitUntil;

  ProxyEntity? _activeProxy;
  List<ProxyEntity> _candidateSnapshot = const [];
  final Set<String> _failedProxyIds = {};
  int _operationId = 0;
  int _consecutiveHealthFailures = 0;
  bool _healthCheckInFlight = false;

  static const _connectTimeoutDuration = Duration(seconds: 12);
  static const _restartSuppressWindow = Duration(seconds: 3);
  static const _healthCheckInterval = Duration(seconds: 8);

  ProxyConnectionBloc({
    required this.engine,
    required this.availability,
    required this.settings,
  }) : super(const VpnConnectionState()) {
    on<ConnectProxyEvent>(_onConnect);
    on<FindAndConnectProxyEvent>(_onFindAndConnect);
    on<ReconnectToAvailableProxyEvent>(_onReconnectToAvailable);
    on<FindDeadProxyAndConnectEvent>(_onFindDeadAndConnect);
    on<RunProxyHealthCheckNowEvent>(_onRunHealthCheckNow);
    on<ClearSimulatedProxyFailureEvent>(_onClearSimulatedFailure);
    on<DisconnectProxyEvent>(_onDisconnect);
    on<ReconnectWithSettingsEvent>(_onReconnectWithSettings);
    on<ProxyStageChangedEvent>(_onStageChanged);
    on<ProxyStatusUpdatedEvent>(_onStatusUpdated);
    on<ProxyForegroundChangedEvent>(_onForegroundChanged);
    on<_ValidateConnectedProxyEvent>(_onValidateConnected);
    on<_MonitorConnectedProxyEvent>(_onMonitorConnected);

    _stageSub = engine.stageStream.listen(
      (stage) => add(ProxyStageChangedEvent(stage)),
    );
    _statusSub = engine.statusStream.listen(
      (status) => add(ProxyStatusUpdatedEvent(status)),
    );
  }

  Future<void> _onConnect(
    ConnectProxyEvent event,
    Emitter<VpnConnectionState> emit,
  ) async {
    if (event.candidates.isNotEmpty) _candidateSnapshot = event.candidates;
    final operationId = await _beginAttempt(emit);
    if (!await _requireDirectInternet(operationId, emit)) return;

    emit(
      state.copyWith(
        stage: VpnStage.finding,
        activeProxyId: event.proxy.id,
        failureKind: ConnectionFailureKind.none,
        errorMessage: null,
      ),
    );
    final result = await availability.verifyProxy(event.proxy);
    if (operationId != _operationId) return;
    if (!result.alive) {
      _activeProxy = event.proxy;
      _failedProxyIds.add(event.proxy.id);
      await _emitProxyUnavailable(emit, activeProxyId: event.proxy.id);
      return;
    }
    await _startProxy(result.proxy, operationId, emit);
  }

  Future<void> _onFindAndConnect(
    FindAndConnectProxyEvent event,
    Emitter<VpnConnectionState> emit,
  ) async {
    _candidateSnapshot = event.candidates;
    final operationId = await _beginAttempt(emit);
    if (!await _requireDirectInternet(operationId, emit)) return;

    emit(
      state.copyWith(
        stage: VpnStage.finding,
        activeProxyId: null,
        failureKind: ConnectionFailureKind.none,
        errorMessage: null,
      ),
    );
    final result = await availability.findAvailable(
      _eligibleAutoCandidates(event.candidates),
      excludedIds: _failedProxyIds,
    );
    if (operationId != _operationId) return;
    if (result == null) {
      await _emitProxyUnavailable(emit);
      return;
    }
    await _startProxy(result.proxy, operationId, emit);
  }

  Future<void> _onReconnectToAvailable(
    ReconnectToAvailableProxyEvent event,
    Emitter<VpnConnectionState> emit,
  ) async {
    if (event.candidates.isNotEmpty) _candidateSnapshot = event.candidates;
    final failedProxy = _activeProxy;
    if (failedProxy != null) _failedProxyIds.add(failedProxy.id);
    if (kDebugMode && ProxyHealthDevControl.instance.simulationEnabled.value) {
      ProxyHealthDevControl.instance.clearSimulation();
    }

    final operationId = await _beginAttempt(emit);
    if (!await _requireDirectInternet(operationId, emit)) return;
    emit(
      state.copyWith(
        stage: VpnStage.finding,
        failureKind: ConnectionFailureKind.none,
        errorMessage: null,
      ),
    );

    final all = _eligibleAutoCandidates(_candidateSnapshot);
    final country = failedProxy?.deep?.egressCountry;
    ProxyProbeResult? result;
    if (country != null && country.isNotEmpty) {
      result = await availability.findAvailable(
        all.where((proxy) => proxy.deep?.egressCountry == country),
        excludedIds: _failedProxyIds,
      );
    }
    if (operationId != _operationId) return;
    result ??= await availability.findAvailable(
      all.where(
        (proxy) =>
            country == null ||
            country.isEmpty ||
            proxy.deep?.egressCountry != country,
      ),
      excludedIds: _failedProxyIds,
    );
    if (operationId != _operationId) return;
    if (result == null) {
      await _emitProxyUnavailable(
        emit,
        activeProxyId: failedProxy?.id,
        message: 'No working proxy is available. Tap to try again.',
      );
      return;
    }
    await _startProxy(result.proxy, operationId, emit);
  }

  Future<void> _onFindDeadAndConnect(
    FindDeadProxyAndConnectEvent event,
    Emitter<VpnConnectionState> emit,
  ) async {
    if (!kDebugMode) return;
    final devControl = ProxyHealthDevControl.instance;
    devControl.clearSimulation();
    devControl.report('Searching for a genuinely bad server…');
    _candidateSnapshot = event.candidates;

    final operationId = await _beginAttempt(emit);
    if (!await _requireDirectInternet(operationId, emit)) {
      devControl.report('Dead-server search stopped: no internet connection.');
      return;
    }
    final candidates = _eligibleAutoCandidates(event.candidates);
    final deadProxy = await availability.findUnavailable(candidates);
    if (operationId != _operationId) return;

    if (deadProxy != null) {
      devControl.report(
        'Bad server found. Attempting to connect so the failure flow can run.',
      );
      // Deliberately skip normal pre-connect rejection. This debug action is
      // specifically meant to exercise startup/active-tunnel failure handling.
      await _startProxy(deadProxy, operationId, emit);
      return;
    }

    devControl.report('Bad server not found. Connecting to a good proxy.');
    final healthy = await availability.findAvailable(
      candidates,
      excludedIds: _failedProxyIds,
    );
    if (operationId != _operationId) return;
    if (healthy == null) {
      devControl.report(
        'Bad server not found, and no healthy proxy is currently available.',
      );
      await _emitProxyUnavailable(
        emit,
        message: 'No working proxy is currently available.',
      );
      return;
    }
    await _startProxy(healthy.proxy, operationId, emit);
  }

  Future<void> _onRunHealthCheckNow(
    RunProxyHealthCheckNowEvent event,
    Emitter<VpnConnectionState> emit,
  ) async {
    if (!kDebugMode) return;
    final devControl = ProxyHealthDevControl.instance;
    if (_activeProxy == null ||
        (state.stage != VpnStage.connected &&
            state.stage != VpnStage.unhealthy)) {
      devControl.report('Connect to a proxy before running a health check.');
      return;
    }
    devControl.report('Running active proxy health check…');
    final operationId = _operationId;
    final alive = await _isActiveProxyAlive();
    if (operationId != _operationId) return;

    if (alive) {
      _consecutiveHealthFailures = 0;
      devControl.report('Active proxy is healthy.');
      if (state.stage == VpnStage.unhealthy) {
        emit(
          state.copyWith(
            stage: VpnStage.connected,
            failureKind: ConnectionFailureKind.none,
            errorMessage: null,
          ),
        );
        _startHealthMonitor(operationId);
      }
      return;
    }

    _consecutiveHealthFailures = event.bypassDebounce
        ? 2
        : _consecutiveHealthFailures + 1;
    devControl.report('Active proxy health check failed.');
    if (_consecutiveHealthFailures >= 2) {
      await _classifyActiveFailure(emit);
    }
  }

  void _onClearSimulatedFailure(
    ClearSimulatedProxyFailureEvent event,
    Emitter<VpnConnectionState> emit,
  ) {
    if (!kDebugMode) return;
    final devControl = ProxyHealthDevControl.instance;
    final simulatedId = devControl.simulatedFailedProxyId.value;
    if (simulatedId != null) _failedProxyIds.remove(simulatedId);
    devControl.clearSimulation();
    if (state.stage == VpnStage.connected ||
        state.stage == VpnStage.unhealthy) {
      add(const RunProxyHealthCheckNowEvent());
    }
  }

  Future<int> _beginAttempt(Emitter<VpnConnectionState> emit) async {
    final operationId = ++_operationId;
    _connectTimeout?.cancel();
    _healthTimer?.cancel();
    _consecutiveHealthFailures = 0;

    final shouldStop =
        state.stage == VpnStage.connected ||
        state.stage == VpnStage.unhealthy ||
        state.stage == VpnStage.connecting ||
        state.stage == VpnStage.validating;
    emit(
      state.copyWith(
        stage: VpnStage.finding,
        failureKind: ConnectionFailureKind.none,
        errorMessage: null,
      ),
    );
    if (shouldStop) {
      _suppressExitUntil = DateTime.now().add(_restartSuppressWindow);
      try {
        await engine.stopProxy();
      } catch (_) {}
    }
    return operationId;
  }

  Future<bool> _requireDirectInternet(
    int operationId,
    Emitter<VpnConnectionState> emit,
  ) async {
    final online = await availability.hasDirectInternet();
    if (operationId != _operationId) return false;
    if (online) return true;
    emit(
      state.copyWith(
        stage: VpnStage.error,
        failureKind: ConnectionFailureKind.noInternet,
        errorMessage: 'No internet connection. Check your network and retry.',
      ),
    );
    return false;
  }

  List<ProxyEntity> _eligibleAutoCandidates(Iterable<ProxyEntity> candidates) {
    if (settings.state.mode != ConnectionMode.stealth) {
      return candidates.where((proxy) => !proxy.isEmpty).toList();
    }
    return candidates.where((proxy) => !proxy.isEmpty && proxy.tls).toList();
  }

  Future<void> _startProxy(
    ProxyEntity proxy,
    int operationId,
    Emitter<VpnConnectionState> emit,
  ) async {
    if (operationId != _operationId) return;
    _activeProxy = proxy;
    AppAnalyticsService.instance.logProxyConnectTapped(
      proxy,
      mode: settings.state.mode.name,
    );
    emit(
      state.copyWith(
        stage: VpnStage.connecting,
        activeProxyId: proxy.id,
        failureKind: ConnectionFailureKind.none,
        errorMessage: null,
      ),
    );
    _armConnectTimeout(operationId);
    try {
      await engine.startProxy(
        proxy,
        blockedApps: settings.state.excludedApps.toList(),
      );
    } catch (error) {
      if (operationId != _operationId) return;
      _connectTimeout?.cancel();
      final message = error.toString();
      final lower = message.toLowerCase();
      final failure = lower.contains('permission')
          ? ConnectionFailureKind.permissionDenied
          : lower.contains('invalid') || lower.contains('argument')
          ? ConnectionFailureKind.invalidConfig
          : ConnectionFailureKind.proxyUnavailable;
      if (failure == ConnectionFailureKind.proxyUnavailable) {
        await _emitProxyUnavailable(emit, activeProxyId: proxy.id);
        return;
      }
      emit(
        state.copyWith(
          stage: VpnStage.error,
          failureKind: failure,
          errorMessage: failure == ConnectionFailureKind.permissionDenied
              ? 'VPN permission is required to connect.'
              : 'This proxy configuration is invalid.',
        ),
      );
    }
  }

  void _armConnectTimeout(int operationId) {
    _connectTimeout?.cancel();
    _connectTimeout = Timer(_connectTimeoutDuration, () {
      if (operationId == _operationId &&
          (state.stage == VpnStage.connecting ||
              state.stage == VpnStage.validating)) {
        add(const ProxyStageChangedEvent('__timeout__'));
      }
    });
  }

  Future<void> _onDisconnect(
    DisconnectProxyEvent event,
    Emitter<VpnConnectionState> emit,
  ) async {
    ++_operationId;
    _connectTimeout?.cancel();
    _healthTimer?.cancel();
    AppAnalyticsService.instance.logProxyDisconnected();
    emit(state.copyWith(stage: VpnStage.disconnecting, errorMessage: null));
    try {
      await engine.stopProxy();
    } catch (_) {}
    _activeProxy = null;
    emit(
      state.copyWith(
        stage: VpnStage.disconnected,
        activeProxyId: null,
        failureKind: ConnectionFailureKind.none,
        errorMessage: null,
      ),
    );
  }

  void _onReconnectWithSettings(
    ReconnectWithSettingsEvent event,
    Emitter<VpnConnectionState> emit,
  ) {
    final proxy = _activeProxy;
    if (proxy == null || proxy.isEmpty) return;
    if (state.stage != VpnStage.connected &&
        state.stage != VpnStage.connecting &&
        state.stage != VpnStage.validating) {
      return;
    }
    add(ConnectProxyEvent(proxy, candidates: _candidateSnapshot));
  }

  Future<void> _onStageChanged(
    ProxyStageChangedEvent event,
    Emitter<VpnConnectionState> emit,
  ) async {
    final raw = event.stage.toLowerCase();
    final suppressing =
        _suppressExitUntil != null &&
        DateTime.now().isBefore(_suppressExitUntil!);
    if (suppressing &&
        (raw == 'disconnected' || raw == 'idle' || raw == 'no_connection')) {
      return;
    }
    if ((state.stage == VpnStage.connecting ||
            state.stage == VpnStage.validating) &&
        (raw == 'disconnected' || raw == 'no_connection' || raw == 'idle')) {
      return;
    }

    if (raw == 'connected') {
      if (state.stage != VpnStage.connecting) return;
      _connectTimeout?.cancel();
      emit(
        state.copyWith(
          stage: VpnStage.validating,
          errorMessage: null,
          failureKind: ConnectionFailureKind.none,
        ),
      );
      add(_ValidateConnectedProxyEvent(_operationId));
      return;
    }

    if (raw == '__timeout__' ||
        raw == 'denied' ||
        raw == 'error' ||
        raw == 'invalid') {
      _connectTimeout?.cancel();
      final operationId = _operationId;
      final directInternet = await availability.hasDirectInternet();
      if (operationId != _operationId) return;
      if (directInternet) {
        await _emitProxyUnavailable(
          emit,
          activeProxyId: _activeProxy?.id,
          message: raw == '__timeout__'
              ? 'The proxy connection timed out. Tap to reconnect.'
              : 'The proxy connection failed. Tap to reconnect.',
        );
      } else {
        emit(
          state.copyWith(
            stage: VpnStage.error,
            failureKind: ConnectionFailureKind.noInternet,
            errorMessage:
                'No internet connection. Check your network and retry.',
          ),
        );
      }
      return;
    }

    if ((raw == 'disconnected' || raw == 'idle' || raw == 'no_connection') &&
        state.stage == VpnStage.disconnecting) {
      emit(state.copyWith(stage: VpnStage.disconnected));
      return;
    }
    if ((raw == 'disconnected' || raw == 'idle' || raw == 'no_connection') &&
        state.stage == VpnStage.connected) {
      await _classifyActiveFailure(emit);
    }
  }

  Future<void> _onValidateConnected(
    _ValidateConnectedProxyEvent event,
    Emitter<VpnConnectionState> emit,
  ) async {
    if (event.operationId != _operationId) return;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    var alive = await _isActiveProxyAlive();
    if (event.operationId != _operationId) return;
    // The local HTTP inbound can trail the native "connected" event briefly.
    // Retry once before showing a maintenance warning for a new connection.
    if (!alive) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (event.operationId != _operationId) return;
      alive = await _isActiveProxyAlive();
      if (event.operationId != _operationId) return;
    }
    if (!alive) {
      await _classifyActiveFailure(emit);
      return;
    }
    _consecutiveHealthFailures = 0;
    final proxy = _activeProxy;
    if (proxy != null) {
      AppAnalyticsService.instance.logProxyConnected(
        proxy,
        mode: settings.state.mode.name,
      );
    }
    emit(
      state.copyWith(
        stage: VpnStage.connected,
        failureKind: ConnectionFailureKind.none,
        errorMessage: null,
      ),
    );
    _startHealthMonitor(event.operationId);
  }

  void _startHealthMonitor(int operationId) {
    _healthTimer?.cancel();
    _healthTimer = Timer.periodic(
      _healthCheckInterval,
      (_) => add(_MonitorConnectedProxyEvent(operationId)),
    );
  }

  Future<void> _onMonitorConnected(
    _MonitorConnectedProxyEvent event,
    Emitter<VpnConnectionState> emit,
  ) async {
    if (event.operationId != _operationId ||
        state.stage != VpnStage.connected ||
        _healthCheckInFlight) {
      return;
    }
    _healthCheckInFlight = true;
    try {
      final alive = await _isActiveProxyAlive();
      if (event.operationId != _operationId) return;
      if (alive) {
        _consecutiveHealthFailures = 0;
        return;
      }
      // The active check already probes two independent HTTPS endpoints
      // through the tunnel. If both fail while direct internet still works,
      // there is no need to keep a broken tunnel alive for another interval.
      _consecutiveHealthFailures = 1;
      await _classifyActiveFailure(emit);
    } finally {
      _healthCheckInFlight = false;
    }
  }

  Future<bool> _isActiveProxyAlive() {
    if (kDebugMode &&
        ProxyHealthDevControl.instance.shouldFail(_activeProxy?.id)) {
      return Future<bool>.value(false);
    }
    return availability.isConnectedProxyAlive();
  }

  Future<void> _classifyActiveFailure(Emitter<VpnConnectionState> emit) async {
    _healthTimer?.cancel();
    final operationId = _operationId;
    final directInternet = await availability.hasDirectInternet();
    if (operationId != _operationId) return;
    final proxy = _activeProxy;
    if (directInternet) {
      if (proxy != null) {
        _failedProxyIds.add(proxy.id);
        AppAnalyticsService.instance.logProxyConnectFailed(
          proxy,
          reason: 'active_proxy_unhealthy',
          mode: settings.state.mode.name,
        );
      }
      emit(
        state.copyWith(
          stage: VpnStage.unhealthy,
          failureKind: ConnectionFailureKind.proxyUnavailable,
          errorMessage:
              'The server is currently undergoing maintenance. Refresh and connect to another server.',
        ),
      );
      await _stopEnginePreservingFailureState();
    } else {
      emit(
        state.copyWith(
          stage: VpnStage.error,
          failureKind: ConnectionFailureKind.noInternet,
          errorMessage: 'Your internet connection is unavailable.',
        ),
      );
    }
  }

  Future<void> _emitProxyUnavailable(
    Emitter<VpnConnectionState> emit, {
    String? activeProxyId,
    String message =
        'The server is currently undergoing maintenance. Refresh and connect to another server.',
  }) async {
    final proxy = _activeProxy;
    if (proxy != null) {
      AppAnalyticsService.instance.logProxyConnectFailed(
        proxy,
        reason: 'proxy_unavailable',
        mode: settings.state.mode.name,
      );
    }
    emit(
      state.copyWith(
        stage: VpnStage.unhealthy,
        activeProxyId: activeProxyId,
        failureKind: ConnectionFailureKind.proxyUnavailable,
        errorMessage: message,
      ),
    );
    await _stopEnginePreservingFailureState();
  }

  /// Stops the native proxy without replacing the red unhealthy UI with the
  /// engine's normal disconnected state. The failed proxy is intentionally
  /// retained so a user-approved reconnect can exclude it and prefer another
  /// server in the same location.
  Future<void> _stopEnginePreservingFailureState() async {
    _connectTimeout?.cancel();
    _healthTimer?.cancel();
    _suppressExitUntil = DateTime.now().add(_restartSuppressWindow);
    try {
      await engine.stopProxy();
    } catch (_) {}
  }

  void _onStatusUpdated(
    ProxyStatusUpdatedEvent event,
    Emitter<VpnConnectionState> emit,
  ) {
    emit(state.copyWith(status: event.status));
  }

  void _onForegroundChanged(
    ProxyForegroundChangedEvent event,
    Emitter<VpnConnectionState> emit,
  ) {
    if (!event.isForeground) {
      _healthTimer?.cancel();
      return;
    }
    if (state.stage == VpnStage.connected) {
      add(_MonitorConnectedProxyEvent(_operationId));
      _startHealthMonitor(_operationId);
    }
  }

  @override
  Future<void> close() {
    ++_operationId;
    _connectTimeout?.cancel();
    _healthTimer?.cancel();
    _stageSub?.cancel();
    _statusSub?.cancel();
    return super.close();
  }
}
