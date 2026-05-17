import 'package:flutter/material.dart';

import '../../../../../core/utils/app_colors.dart';
import '../bloc/vpn_connection_bloc/vpn_connection_bloc.dart';

class VpnConnectButton extends StatelessWidget {
  final VpnConnectionState state;
  final VoidCallback onTap;

  const VpnConnectButton({
    super.key,
    required this.state,
    required this.onTap,
  });

  Color get _activeColor => state.isConnected
      ? AppColors.connected
      : state.isConnecting
          ? AppColors.connecting
          : AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: state.stage == VpnStage.disconnecting ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              _activeColor.withValues(alpha: 0.15),
              _activeColor.withValues(alpha: 0.5),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: _activeColor.withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
          border: Border.all(color: _activeColor, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.isConnected
                  ? Icons.power_settings_new
                  : Icons.power_settings_new_outlined,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              state.stage == VpnStage.disconnecting
                  ? 'Disconnecting'
                  : state.stage == VpnStage.connecting
                      ? 'Connecting...'
                      : state.isConnected
                          ? 'Connected'
                          : 'Tap to Connect',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
