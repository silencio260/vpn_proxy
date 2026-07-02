import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/utils/app_colors.dart';
import '../bloc/vpn_connection_bloc/vpn_connection_bloc.dart';

class VpnConnectButton extends StatefulWidget {
  final VpnConnectionState state;
  final VoidCallback onTap;

  const VpnConnectButton({
    super.key,
    required this.state,
    required this.onTap,
  });

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
        VpnStage.connecting ||
        VpnStage.disconnecting =>
          true,
        _ => false,
      };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
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
      VpnStage.connecting || VpnStage.disconnecting => palette.warning,
      _ => palette.primary,
    };
    final label = switch (widget.state.stage) {
      VpnStage.connected => 'Tap To Disconnect',
      VpnStage.connecting => 'Connecting…',
      VpnStage.disconnecting => 'Disconnecting…',
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

/// Draws soft, organic wave rings that drift outward from the button like
/// flowing fluid: each ring is a circle perturbed by overlapping sine bands
/// whose phases rotate as the ring expands, so the crests appear to flow
/// around the button rather than pulse as rigid circles.
class _FluidWavePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double innerRadius;

  _FluidWavePainter({
    required this.progress,
    required this.color,
    required this.innerRadius,
  });

  static const _waveCount = 3;
  static const _segments = 90;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.width / 2;

    for (var i = 0; i < _waveCount; i++) {
      final waveProgress = (progress + i / _waveCount) % 1.0;
      final baseRadius =
          innerRadius + (maxRadius - innerRadius) * waveProgress;
      // Quadratic fade so waves dissolve softly well before the edge.
      final fade = (1.0 - waveProgress) * (1.0 - waveProgress);
      final opacity = fade * 0.32;
      if (opacity < 0.005) continue;

      // Amplitude grows as the wave travels, so ripples loosen up like
      // fluid spreading out. Phases drift in opposite directions per band
      // to give a flowing, non-repeating feel.
      final amplitude = 3.0 + 9.0 * waveProgress;
      final drift = progress * 2 * math.pi;
      final phaseA = drift + i * 2.1;
      final phaseB = -drift * 1.6 + i * 4.2;

      final path = Path();
      for (var s = 0; s <= _segments; s++) {
        final theta = 2 * math.pi * s / _segments;
        final wobble = amplitude *
            (0.6 * math.sin(3 * theta + phaseA) +
                0.4 * math.sin(5 * theta + phaseB));
        final r = baseRadius + wobble;
        final point = center + Offset(math.cos(theta), math.sin(theta)) * r;
        if (s == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * fade + 0.8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_FluidWavePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
