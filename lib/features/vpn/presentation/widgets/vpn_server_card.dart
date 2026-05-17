import 'package:flutter/material.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../domain/entities/vpn_server_entity.dart';

class VpnServerCard extends StatelessWidget {
  final VpnServerEntity server;
  final bool isSelected;
  final VoidCallback onTap;

  const VpnServerCard({
    super.key,
    required this.server,
    required this.isSelected,
    required this.onTap,
  });

  String get _flagEmoji {
    return server.countryShort.toUpperCase().runes
        .map((r) => String.fromCharCode(r - 0x41 + 0x1F1E6))
        .join();
  }

  String get _pingLabel {
    final p = int.tryParse(server.ping) ?? 0;
    if (p == 0) return '—';
    return '${p}ms';
  }

  String get _speedLabel {
    final s = server.speed;
    if (s <= 0) return '—';
    if (s >= 1000000) return '${(s / 1000000).toStringAsFixed(1)} Gbps';
    if (s >= 1000) return '${(s / 1000).toStringAsFixed(0)} Mbps';
    return '$s Kbps';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                _flagEmoji,
                style: const TextStyle(fontSize: 32),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    server.countryLong,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    server.hostname,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Chip(label: _pingLabel, icon: Icons.network_ping),
                const SizedBox(height: 4),
                _Chip(label: _speedLabel, icon: Icons.speed),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _Chip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.45)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
