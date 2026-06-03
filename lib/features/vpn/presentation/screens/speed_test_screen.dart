import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_colors.dart';
import '../bloc/vpn_connection_bloc/vpn_connection_bloc.dart';

class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _needle;
  double _result = 0;
  int _ping = 0;
  int _down = 0;
  int _up = 0;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _needle = Tween<double>(begin: 0, end: 0).animate(_controller);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    final rng = Random();
    final target = 35 + rng.nextInt(70).toDouble();
    setState(() {
      _running = true;
      _result = 0;
      _ping = 0;
      _down = 0;
      _up = 0;
    });
    _needle = Tween<double>(begin: 0, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    )..addListener(() => setState(() => _result = _needle.value));
    _controller.forward(from: 0).then((_) {
      setState(() {
        _running = false;
        _ping = 8 + rng.nextInt(20);
        _down = target.round();
        _up = (target * 0.6).round();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: palette.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Speed Tester',
          style: TextStyle(
            color: palette.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Pill(
                      icon: Icons.south_rounded,
                      label: 'Download',
                      value: '$_down Mbps',
                      palette: palette,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Pill(
                      icon: Icons.north_rounded,
                      label: 'Upload',
                      value: '$_up Mbps',
                      palette: palette,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _PingRow(ping: _ping, down: _down, up: _up, palette: palette),
              const SizedBox(height: 32),
              SizedBox(
                width: 260,
                height: 260,
                child: CustomPaint(
                  painter: _GaugePainter(
                    progress: _running ? _result / 120 : _result / 120,
                    palette: palette,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _result.toStringAsFixed(1),
                          style: TextStyle(
                            color: palette.primary,
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Mbps',
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              _LocationCard(palette: palette),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _running ? null : _start,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(_running ? 'Testing…' : 'Start Test Again'),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final AppPalette palette;
  const _Pill({
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
              Text(label,
                  style: TextStyle(
                      color: palette.textSecondary, fontSize: 11)),
              Text(value,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _PingRow extends StatelessWidget {
  final int ping;
  final int down;
  final int up;
  final AppPalette palette;
  const _PingRow({
    required this.ping,
    required this.down,
    required this.up,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, int value, IconData icon, Color color) =>
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              '$value',
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Ping Ms',
          style: TextStyle(color: palette.textSecondary, fontSize: 13),
        ),
        const SizedBox(width: 12),
        chip('Ping', ping, Icons.swap_horiz_rounded, palette.primary),
        const SizedBox(width: 16),
        chip('Up', up, Icons.north_rounded, palette.success),
        const SizedBox(width: 16),
        chip('Down', down, Icons.south_rounded, palette.warning),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  final AppPalette palette;
  const _LocationCard({required this.palette});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VpnConnectionBloc, VpnConnectionState>(
      builder: (context, state) {
        final ip = state.ipDetails.query.isEmpty
            ? '192.120.188.0'
            : state.ipDetails.query;
        final loc = state.ipDetails.country.isEmpty
            ? 'United State'
            : state.ipDetails.country;
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Location',
                        style: TextStyle(
                            color: palette.textSecondary, fontSize: 11)),
                    Text(
                      loc,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('IP Address',
                      style: TextStyle(
                          color: palette.textSecondary, fontSize: 11)),
                  Text(
                    ip,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress; // 0..1
  final AppPalette palette;
  _GaugePainter({required this.progress, required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 12;
    final track = Paint()
      ..color = palette.primary.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final arc = Paint()
      ..color = palette.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    const start = 0.75 * pi;
    const sweep = 1.5 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      track,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep * progress.clamp(0.0, 1.0),
      false,
      arc,
    );

    // Tick marks
    final tickPaint = Paint()
      ..color = palette.textSecondary.withValues(alpha: 0.4)
      ..strokeWidth = 2;
    for (int i = 0; i <= 10; i++) {
      final a = start + sweep * (i / 10);
      final p1 = center + Offset(cos(a), sin(a)) * (radius - 22);
      final p2 = center + Offset(cos(a), sin(a)) * (radius - 32);
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Needle
    final needleAngle = start + sweep * progress.clamp(0.0, 1.0);
    final needleEnd =
        center + Offset(cos(needleAngle), sin(needleAngle)) * (radius - 18);
    final needlePaint = Paint()
      ..color = palette.accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 6, Paint()..color = palette.primary);
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
