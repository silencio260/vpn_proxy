import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:genrevibes_starter_kit/starter_kit.dart';

import '../../../../../config/app_env.dart';
import '../../../../../config/routes_manager.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/country_util.dart';
import '../../../proxy/domain/entities/proxy_entity.dart';
import '../../../proxy/presentation/bloc/proxy_bloc/proxy_bloc.dart';
import '../../../proxy/presentation/bloc/proxy_connection_bloc/proxy_connection_bloc.dart';
import '../../../settings/domain/entities/connection_settings_entity.dart';
import '../../../settings/presentation/cubit/connection_settings_cubit.dart';
// VpnConnectionBloc is imported for the shared VpnConnectionState/VpnStage
// types (declared in its library); the connect flow is driven by
// ProxyConnectionBloc.
import '../bloc/vpn_connection_bloc/vpn_connection_bloc.dart';
import '../widgets/vpn_connect_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  VpnStage? _lastStage;
  bool _autoConnecting = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final stage = context.read<ProxyConnectionBloc>().state.stage;
      if (stage == VpnStage.connected) {
        setState(() => _elapsed += const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatTimer(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(d.inHours);
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: BlocConsumer<ProxyConnectionBloc, VpnConnectionState>(
          listener: (context, state) {
            if (_lastStage != state.stage) {
              if (state.stage == VpnStage.connected &&
                  _lastStage != VpnStage.connected) {
                setState(() => _elapsed = Duration.zero);
                // Show an interstitial once a connection is established. The
                // AdsBloc gates on premium, suppression and the configured
                // interval, so we just request it here.
                StarterKit.adsBloc.add(const AdsShowInterstitial());
              } else if (state.stage == VpnStage.disconnected) {
                setState(() => _elapsed = Duration.zero);
              }
              _lastStage = state.stage;
            }
          },
          builder: (context, connectionState) {
            return Column(
              children: [
                _AppBar(palette: palette),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        VpnConnectButton(
                          state: connectionState,
                          onTap: () => _onConnectTap(context, connectionState),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          _statusLabel(connectionState.stage),
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _formatTimer(_elapsed),
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 56),
                        _SelectedServerCard(palette: palette),
                        if (connectionState.stage == VpnStage.connected) ...[
                          const SizedBox(height: 36),
                          _SpeedRow(state: connectionState, palette: palette),
                        ],
                        const SizedBox(height: 56),
                      ],
                    ),
                  ),
                ),
                // Anchored banner ad. Hidden automatically for premium users
                // and when no banner ad unit id is configured.
                StarterKit.bannerAd(adUnitId: AppEnv.bannerAdIdOrNull),
              ],
            );
          },
        ),
      ),
    );
  }

  String _statusLabel(VpnStage stage) => switch (stage) {
        VpnStage.connected => 'Connected',
        VpnStage.connecting => 'Connecting',
        VpnStage.disconnecting => 'Disconnecting',
        VpnStage.error => 'Error',
        _ => 'Disconnected',
      };

  void _onConnectTap(BuildContext context, VpnConnectionState state) {
    final bloc = context.read<ProxyConnectionBloc>();
    if (state.stage == VpnStage.connecting ||
        state.stage == VpnStage.connected) {
      bloc.add(const DisconnectProxyEvent());
      return;
    }
    final proxyState = context.read<ProxyBloc>().state;
    final selected =
        proxyState is ProxyLoaded ? proxyState.selectedProxy : null;
    if (selected != null && !selected.isEmpty) {
      bloc.add(ConnectProxyEvent(selected));
    } else {
      _autoSelectAndConnect(context);
    }
  }

  Future<void> _autoSelectAndConnect(BuildContext context) async {
    if (_autoConnecting) return;
    _autoConnecting = true;
    final proxyBloc = context.read<ProxyBloc>();
    final connectionBloc = context.read<ProxyConnectionBloc>();
    final settingsCubit = context.read<ConnectionSettingsCubit>();
    try {
      if (proxyBloc.state is! ProxyLoading) {
        proxyBloc.add(const FetchProxiesEvent());
      }
      var result = await proxyBloc.stream
          .firstWhere((s) => s is! ProxyLoading)
          .timeout(const Duration(seconds: 20));
      if (result is ProxyInitial) {
        // A cached-db load was in flight and came back empty — fall
        // through to a network fetch.
        proxyBloc.add(const FetchProxiesEvent());
        result = await proxyBloc.stream
            .firstWhere((s) => s is ProxyLoaded || s is ProxyError)
            .timeout(const Duration(seconds: 20));
      }
      if (!mounted) return;
      if (result is ProxyLoaded && !result.selectedProxy.isEmpty) {
        final candidate = _preferredProxy(result, settingsCubit.state.mode);
        if (candidate.id != result.selectedProxy.id) {
          proxyBloc.add(SelectProxyEvent(candidate));
        }
        connectionBloc.add(ConnectProxyEvent(candidate));
      }
    } on TimeoutException {
      // The card's spinner is driven by ProxyBloc state; nothing else to do.
    } finally {
      _autoConnecting = false;
    }
  }

  /// In stealth mode the auto-picked server should be TLS-camouflaged so
  /// tunnel traffic is indistinguishable from ordinary HTTPS; fall back to the
  /// default selection when no TLS server is available. VPN mode (and explicit
  /// user selections, which never reach this path) are unrestricted.
  ProxyEntity _preferredProxy(ProxyLoaded loaded, ConnectionMode mode) {
    if (mode != ConnectionMode.stealth || loaded.selectedProxy.tls) {
      return loaded.selectedProxy;
    }
    return loaded.proxies.firstWhere(
      (p) => p.tls && !p.isEmpty,
      orElse: () => loaded.selectedProxy,
    );
  }
}

class _AppBar extends StatelessWidget {
  final AppPalette palette;
  const _AppBar({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Mash ',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: 'VPN',
                  style: TextStyle(
                    color: palette.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, Routes.location),
            child: Icon(
              Icons.language,
              color: palette.textPrimary,
              size: 26,
            ),
          ),
          const SizedBox(width: 18),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, Routes.profile),
            child: Icon(
              Icons.person_rounded,
              color: palette.textPrimary,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedRow extends StatelessWidget {
  final VpnConnectionState state;
  final AppPalette palette;
  const _SpeedRow({required this.state, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SpeedPill(
            icon: Icons.south_rounded,
            label: 'Download',
            value: _normalize(state.status.byteIn),
            palette: palette,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SpeedPill(
            icon: Icons.north_rounded,
            label: 'Upload',
            value: _normalize(state.status.byteOut),
            palette: palette,
          ),
        ),
      ],
    );
  }

  String _normalize(String? raw) {
    if (raw == null || raw.isEmpty) return '00 Mbps';
    return raw;
  }
}

class _SpeedPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final AppPalette palette;
  const _SpeedPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: palette.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: palette.success),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectedServerCard extends StatelessWidget {
  final AppPalette palette;
  const _SelectedServerCard({required this.palette});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProxyBloc, ProxyState>(
      builder: (context, state) {
        final isLoading = state is ProxyLoading;
        final proxy = state is ProxyLoaded ? state.selectedProxy : null;
        final hasProxy = proxy != null && !proxy.isEmpty;
        final code = proxy?.deep?.egressCountry;
        final country = CountryUtil.name(code);
        final title =
            hasProxy
                ? (country.isNotEmpty
                    ? country
                    : (proxy.remark.isEmpty ? proxy.address : proxy.remark))
                : isLoading
                    ? 'Loading servers…'
                    : 'Tap to select a server';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Selected Server',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, Routes.location),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.surface,
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: palette.primary,
                              ),
                            )
                          : Text(
                              CountryUtil.flagEmoji(hasProxy ? code : null),
                              style: const TextStyle(fontSize: 22),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Auto ',
                                  style: TextStyle(
                                    color: palette.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Fast Server',
                                  style: TextStyle(
                                    color: palette.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            title,
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: palette.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
