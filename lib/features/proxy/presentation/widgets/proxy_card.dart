import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../../../core/dev/proxy_display_dev_control.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/country_util.dart';
import '../../domain/entities/proxy_entity.dart';

class ProxyCard extends StatelessWidget {
  final ProxyEntity proxy;
  final bool isSelected;
  final VoidCallback onTap;

  const ProxyCard({
    super.key,
    required this.proxy,
    required this.isSelected,
    required this.onTap,
  });

  String? get _countryCode => proxy.deep?.egressCountry;

  String get _title {
    final country = CountryUtil.name(_countryCode);
    if (country.isNotEmpty) return country;
    return proxy.remark.isEmpty ? proxy.address : proxy.remark;
  }

  /// Only show the address when it's a bare IPv4-style value (digits and dots).
  /// Hostnames / anything else are hidden from the user.
  bool get _showAddress => RegExp(r'^[0-9.]+$').hasMatch(proxy.address);

  /// Top-level administrative division of the exit node (US state, CA
  /// province, etc.) — surfaced as the "state" under the country name.
  String? get _state {
    final region = proxy.deep?.egressRegion;
    return (region != null && region.isNotEmpty) ? region : null;
  }

  Widget _buildStateLine(AppPalette palette) {
    final state = _state;
    if (state == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        state,
        style: TextStyle(color: palette.textHint, fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Additional developer-only line shown below the state. The state remains
  /// visible regardless of this switch; turning the switch off removes only
  /// the IP line.
  Widget _buildDebugIpLine(AppPalette palette) {
    final showIp =
        kDebugMode && ProxyDisplayDevControl.instance.showProxyIp.value;
    if (!showIp || !_showAddress) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        'IP ${proxy.address}',
        style: TextStyle(color: palette.textHint, fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  int? get _latency => proxy.health?.latencyMs;

  String get _latencyLabel {
    final latency = _latency;
    if (latency == null || latency <= 0) return '—';
    return '${latency}ms';
  }

  /// 1-4 signal strength from latency (lower latency = stronger).
  int get _signalBars {
    final p = _latency ?? 0;
    if (p <= 0) return 0;
    if (p < 60) return 4;
    if (p < 120) return 3;
    if (p < 200) return 2;
    return 1;
  }

  Color _statusColor(AppPalette palette) {
    switch (proxy.health?.status) {
      case 'alive':
        return palette.success;
      case 'dead':
        return palette.error;
      default:
        return palette.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
            // Country flag (proxies are identified by their egress country).
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.surface,
              ),
              child: Text(
                CountryUtil.flagEmoji(_countryCode),
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: 12),
            // Country name + address.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // The exit-node state is always shown. Debug builds can add
                  // the raw server IP as a separate line beneath it.
                  _buildStateLine(palette),
                  AnimatedBuilder(
                    animation: ProxyDisplayDevControl.instance.listenable,
                    builder: (context, _) => _buildDebugIpLine(palette),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Signal bars + latency.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SignalBars(bars: _signalBars, color: _statusColor(palette)),
                const SizedBox(width: 6),
                Text(
                  _latencyLabel,
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: palette.primary,
                  ),
                ],
              ],
            ),
          ],
        ),
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
