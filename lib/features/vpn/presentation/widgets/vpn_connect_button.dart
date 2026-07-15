import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../../../../../core/utils/app_colors.dart';
import '../bloc/vpn_connection_bloc/vpn_connection_bloc.dart';

class VpnConnectButton extends StatefulWidget {
  final VpnConnectionState state;
  final VoidCallback onTap;

  const VpnConnectButton({super.key, required this.state, required this.onTap});

  @override
  State<VpnConnectButton> createState() => _VpnConnectButtonState();
}

class _VpnConnectButtonState extends State<VpnConnectButton>
    with SingleTickerProviderStateMixin {
  // Button size, with another 0.5x of it around for the shadow / wave halo.
  static const _buttonSize = 186.0;
  static const _haloSize = _buttonSize * 2; // 0.5x of button on each side

  late final AnimationController _pulseController;

  bool get _shouldPulse => switch (widget.state.stage) {
    VpnStage.connected ||
    VpnStage.unhealthy ||
    VpnStage.error ||
    VpnStage.finding ||
    VpnStage.connecting ||
    VpnStage.validating ||
    VpnStage.disconnecting => true,
    _ => false,
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(VpnConnectButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    if (_shouldPulse) {
      if (!_pulseController.isAnimating) _pulseController.repeat();
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final active = switch (widget.state.stage) {
      VpnStage.connected => palette.success,
      VpnStage.unhealthy || VpnStage.error => AppColors.criticalRed,
      VpnStage.finding ||
      VpnStage.connecting ||
      VpnStage.validating ||
      VpnStage.disconnecting => palette.warning,
      _ => palette.primary,
    };
    final label = switch (widget.state.stage) {
      VpnStage.connected => 'Tap To Disconnect',
      VpnStage.unhealthy => 'Refresh And Reconnect',
      VpnStage.finding => 'Finding A Server…',
      VpnStage.connecting => 'Connecting…',
      VpnStage.validating => 'Validating…',
      VpnStage.disconnecting => 'Disconnecting…',
      VpnStage.error => 'Retry Connection',
      _ => 'Tap To Connect',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.state.stage == VpnStage.disconnecting
              ? null
              : widget.onTap,
          child: SizedBox(
            width: _buttonSize,
            height: _buttonSize,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Waves overflow the button's box instead of reserving
                // layout space, so surrounding content stays in view.
                if (_shouldPulse)
                  Positioned(
                    left: -(_haloSize - _buttonSize) / 2,
                    top: -(_haloSize - _buttonSize) / 2,
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) => CustomPaint(
                          size: const Size(_haloSize, _haloSize),
                          painter: _FluidWavePainter(
                            progress: _pulseController.value,
                            color: active,
                            innerRadius: _buttonSize / 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: _buttonSize,
                  height: _buttonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [active, active.withValues(alpha: 0.75)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: active.withValues(alpha: 0.35),
                        blurRadius: _buttonSize * 0.25,
                        spreadRadius: _buttonSize * 0.06,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.power_settings_new_rounded,
                    size: 84,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
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

/// Paints a dot-matrix wave cloud around the button, like a topographic
/// point mesh: concentric rings of tiny dots, dense and bright against the
/// button's edge, thinning and loosening as they spread out. Layered sine
/// folds displace each ring per-angle — outer rings wave more than inner
/// ones — so the whole cloud undulates organically instead of pulsing.
/// All time terms are whole multiples of one 2*pi cycle so the loop never
/// visibly restarts.
class _FluidWavePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double innerRadius;

  _FluidWavePainter({
    required this.progress,
    required this.color,
    required this.innerRadius,
  });

  static const _rings = 16;
  static const _dotSpacing = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.width / 2;
    final span = maxRadius - innerRadius;
    final t = progress * 2 * math.pi;

    for (var i = 0; i < _rings; i++) {
      final f = i / (_rings - 1); // 0 at the button edge, 1 farthest out
      final base = innerRadius + 5 + span * 0.78 * f;

      // Outer rings fold more deeply than inner ones, so the cloud's edge
      // waves while the core stays anchored to the button.
      final amp = span * (0.04 + 0.17 * f);

      final count = (2 * math.pi * base / _dotSpacing).round();
      final points = <Offset>[];
      for (var k = 0; k < count; k++) {
        // Slight per-ring twist keeps dots from lining up on rigid spokes.
        final theta = 2 * math.pi * k / count + f * 0.5;
        final fold =
            0.5 * math.sin(2 * theta + t + f * 4.0) +
            0.3 * math.sin(3 * theta - t + f * 7.0) +
            0.2 * math.sin(5 * theta + 2 * t + f * 2.0);
        final r = base + amp * fold;
        points.add(center + Offset(math.cos(theta), math.sin(theta)) * r);
      }

      // Dense and bright near the button, dissolving toward the edge,
      // with a gentle shimmer drifting through the rings.
      final shimmer = 0.85 + 0.15 * math.sin(t * 2 + f * 6.0);
      final opacity = math.pow(1.0 - f, 1.6) * 0.5 * shimmer + 0.02;
      final paint = Paint()
        ..color = color.withValues(alpha: opacity.toDouble())
        ..strokeWidth = 2.2 - 0.8 * f
        ..strokeCap = StrokeCap.round;
      canvas.drawPoints(PointMode.points, points, paint);
    }
  }

  @override
  bool shouldRepaint(_FluidWavePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
