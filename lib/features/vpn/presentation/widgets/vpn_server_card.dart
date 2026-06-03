import 'package:flutter/material.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../domain/entities/vpn_server_entity.dart';
import '../../domain/entities/vpn_server_health_entity.dart';

class VpnServerCard extends StatelessWidget {
  final VpnServerEntity server;
  final VpnServerHealthEntity? health;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;

  const VpnServerCard({
    super.key,
    required this.server,
    this.health,
    required this.isSelected,
    required this.onTap,
    this.isLocked = false,
  });

  String get _flagEmoji {
    if (server.countryShort.isEmpty) return '🌐';
    return server.countryShort
        .toUpperCase()
        .runes
        .map((r) => String.fromCharCode(r - 0x41 + 0x1F1E6))
        .join();
  }

  /// 1-4 signal strength from ping (lower ping = stronger).
  int get _signalBars {
    final p = health?.latencyMs ?? int.tryParse(server.ping) ?? 0;
    if (p == 0) return 2;
    if (p < 60) return 4;
    if (p < 120) return 3;
    if (p < 200) return 2;
    return 1;
  }

  String get _latencyLabel {
    final latency = health?.latencyMs ?? int.tryParse(server.ping);
    if (latency == null || latency <= 0) return 'Ping —';
    return '${latency}ms';
  }

  String get _downloadLabel {
    if (server.speed <= 0) return 'Down —';
    final mbps = server.speed / 1000000;
    final value =
        mbps >= 10 ? mbps.toStringAsFixed(0) : mbps.toStringAsFixed(1);
    return 'Down $value Mbps';
  }

  String get _statusLabel {
    return switch (health?.status ?? VpnServerHealthStatus.unknown) {
      VpnServerHealthStatus.online => 'Online',
      VpnServerHealthStatus.offline => 'Dead',
      VpnServerHealthStatus.checking => 'Checking',
      VpnServerHealthStatus.unknown => 'Unknown',
    };
  }

  Color _statusColor(AppPalette palette) {
    return switch (health?.status ?? VpnServerHealthStatus.unknown) {
      VpnServerHealthStatus.online => palette.success,
      VpnServerHealthStatus.offline => palette.error,
      VpnServerHealthStatus.checking => palette.warning,
      VpnServerHealthStatus.unknown => palette.textHint,
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? palette.primary.withValues(alpha: 0.10)
                  : palette.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? palette.primary : palette.border,
            width: isSelected ? 1.4 : 1,
          ),
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
              child: Text(_flagEmoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    server.countryLong.isEmpty
                        ? server.hostname
                        : server.countryLong,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    server.hostname,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _MetricChip(
                        text: _latencyLabel,
                        icon: Icons.speed_rounded,
                        color: palette.primary,
                      ),
                      _MetricChip(
                        text: _downloadLabel,
                        icon: Icons.south_rounded,
                        color: palette.success,
                      ),
                      _MetricChip(
                        text: 'Up —',
                        icon: Icons.north_rounded,
                        color: palette.textHint,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _HealthBadge(
                  label: _statusLabel,
                  color: _statusColor(palette),
                  palette: palette,
                ),
                const SizedBox(height: 10),
                _SignalBars(bars: _signalBars, color: palette.primary),
                const SizedBox(height: 10),
                if (isLocked)
                  Icon(Icons.lock_rounded, size: 18, color: palette.accent)
                else if (isSelected)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.primary,
                    ),
                  )
                else
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.border),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthBadge extends StatelessWidget {
  final String label;
  final Color color;
  final AppPalette palette;

  const _HealthBadge({
    required this.label,
    required this.color,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color == palette.textHint ? palette.textSecondary : color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _MetricChip({
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  final int bars;
  final Color color;
  const _SignalBars({required this.bars, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final active = i < bars;
        return Container(
          width: 3,
          height: 4.0 + i * 3,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: active ? color : color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
