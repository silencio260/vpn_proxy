import 'package:flutter/foundation.dart';

/// In-memory, debug-only controls for exercising proxy failure paths without
/// changing Firestore health or disabling the device's real internet access.
class ProxyHealthDevControl {
  ProxyHealthDevControl._();

  static final ProxyHealthDevControl instance = ProxyHealthDevControl._();

  final ValueNotifier<bool> simulationEnabled = ValueNotifier(false);
  final ValueNotifier<bool> findDeadServerEnabled = ValueNotifier(false);
  final ValueNotifier<String?> simulatedFailedProxyId = ValueNotifier(null);
  final ValueNotifier<String?> statusMessage = ValueNotifier(null);

  bool shouldFail(String? proxyId) {
    return kDebugMode &&
        simulationEnabled.value &&
        proxyId != null &&
        proxyId == simulatedFailedProxyId.value;
  }

  void simulateFailure(String proxyId) {
    if (!kDebugMode) return;
    simulationEnabled.value = true;
    simulatedFailedProxyId.value = proxyId;
    statusMessage.value = 'Active proxy failure is being simulated.';
  }

  void clearSimulation() {
    simulationEnabled.value = false;
    simulatedFailedProxyId.value = null;
    statusMessage.value = 'Simulated proxy failure cleared.';
  }

  void setFindDeadServerEnabled(bool enabled) {
    if (!kDebugMode) return;
    findDeadServerEnabled.value = enabled;
    statusMessage.value = enabled
        ? 'Find-dead-server mode enabled.'
        : 'Find-dead-server mode disabled.';
  }

  void report(String message) {
    if (!kDebugMode) return;
    statusMessage.value = message;
  }
}
