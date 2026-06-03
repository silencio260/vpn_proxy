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

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final active = switch (state.stage) {
      VpnStage.connected => palette.success,
      VpnStage.connecting || VpnStage.disconnecting => palette.warning,
      _ => palette.primary,
    };
    final label = switch (state.stage) {
      VpnStage.connected => 'Tap To Disconnect',
      VpnStage.connecting => 'Connecting…',
      VpnStage.disconnecting => 'Disconnecting…',
      _ => 'Tap To Connect',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: state.stage == VpnStage.disconnecting ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active.withValues(alpha: 0.08),
            ),
            child: Center(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active.withValues(alpha: 0.14),
                ),
                child: Center(
                  child: Container(
                    width: 124,
                    height: 124,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [active, active.withValues(alpha: 0.75)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: active.withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.power_settings_new_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          label,
          style: TextStyle(
            color: palette.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
