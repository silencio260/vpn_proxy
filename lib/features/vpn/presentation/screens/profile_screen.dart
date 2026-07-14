import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/routes_manager.dart';
import '../../../../../config/theme_cubit.dart';
import '../../../../../core/ads/ads_dev_control.dart';
import '../../../../../core/dev/dev_ip_check.dart';
import '../../../../../core/dev/proxy_display_dev_control.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../proxy/presentation/bloc/proxy_connection_bloc/proxy_connection_bloc.dart';
import '../../../settings/domain/entities/connection_settings_entity.dart';
import '../../../settings/presentation/cubit/connection_settings_cubit.dart';
import '../bloc/vpn_connection_bloc/vpn_connection_bloc.dart';

class ProfileScreen extends StatelessWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: embedded
          ? null
          : AppBar(
              backgroundColor: palette.background,
              leading: IconButton(
                icon:
                    Icon(Icons.arrow_back_rounded, color: palette.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Profile',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
      body: SafeArea(
        top: embedded,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            if (embedded)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Center(
                  child: Text(
                    'Profile',
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            _ThemeTile(palette: palette),
            _VpnModeTile(palette: palette),
            if (Platform.isAndroid)
              _Tile(
                icon: Icons.call_split_rounded,
                label: 'Split Tunneling',
                palette: palette,
                onTap: () =>
                    Navigator.pushNamed(context, Routes.splitTunneling),
              ),
            const SizedBox(height: 8),
            _Tile(
              icon: Icons.speed_rounded,
              label: 'Speed Test',
              palette: palette,
              onTap: () => Navigator.pushNamed(context, Routes.speedTest),
            ),
            _Tile(
              icon: Icons.public_rounded,
              label: 'Server List',
              palette: palette,
              onTap: () => Navigator.pushNamed(context, Routes.location),
            ),
            // _Tile(
            //   icon: Icons.language_rounded,
            //   label: 'Language',
            //   palette: palette,
            //   onTap: () {},
            // ),
            _Tile(
              icon: Icons.shield_rounded,
              label: 'Privacy Policy',
              palette: palette,
              onTap: () {},
            ),
            _Tile(
              icon: Icons.info_outline_rounded,
              label: 'About',
              palette: palette,
              onTap: () {},
            ),
            // Developer tools — debug builds only. Gated on kDebugMode (a
            // compile-time const that is false in release builds regardless of
            // which env file is used), so this never ships to users.
            if (kDebugMode) _DevSection(palette: palette),
          ],
        ),
      ),
    );
  }
}

/// Debug-only tools: IP/location check and runtime ad switches.
class _DevSection extends StatelessWidget {
  final AppPalette palette;
  const _DevSection({required this.palette});

  void _openIpCheck(BuildContext context) {
    final connected =
        context.read<ProxyConnectionBloc>().state.stage == VpnStage.connected;
    showDialog<void>(
      context: context,
      builder: (_) => _IpCheckDialog(palette: palette, connected: connected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 20, bottom: 4),
          child: Text(
            'Developer',
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        _Tile(
          icon: Icons.my_location_rounded,
          label: 'What\'s my IP & location',
          palette: palette,
          onTap: () => _openIpCheck(context),
        ),
        _DevSwitchTile(
          icon: Icons.visibility_off_rounded,
          label: 'Disable ad display',
          subtitle: 'Ads are still requested but never shown.',
          palette: palette,
          listenable: AdsDevControl.instance.displayDisabled,
          valueOf: () => AdsDevControl.instance.displayDisabled.value,
          onChanged: AdsDevControl.instance.setDisplayDisabled,
        ),
        _DevSwitchTile(
          icon: Icons.cloud_off_rounded,
          label: 'Disable ad requests & display',
          subtitle: 'No ad requests at all. Applies on next launch.',
          palette: palette,
          listenable: AdsDevControl.instance.requestsDisabled,
          valueOf: () => AdsDevControl.instance.requestsDisabled.value,
          onChanged: AdsDevControl.instance.setRequestsDisabled,
        ),
        _DevSwitchTile(
          icon: Icons.dns_rounded,
          label: 'Show proxy IP address',
          subtitle: 'Server list also shows the raw IP below the state.',
          palette: palette,
          listenable: ProxyDisplayDevControl.instance.showProxyIp,
          valueOf: () => ProxyDisplayDevControl.instance.showProxyIp.value,
          onChanged: ProxyDisplayDevControl.instance.setShowProxyIp,
        ),
      ],
    );
  }
}

/// In-app IP/location check for the dev section. Shows two lookups side by
/// side: the real network path (this app bypasses the tunnel) and the tunnel
/// path (proxied through the local Xray HTTP inbound), so the tunnel's egress
/// IP/location can be verified without leaving the app.
class _IpCheckDialog extends StatefulWidget {
  final AppPalette palette;
  final bool connected;
  const _IpCheckDialog({required this.palette, required this.connected});

  @override
  State<_IpCheckDialog> createState() => _IpCheckDialogState();
}

class _IpCheckDialogState extends State<_IpCheckDialog> {
  late Future<DevIpResult> _real;
  Future<DevIpResult>? _tunnel;

  @override
  void initState() {
    super.initState();
    _real = DevIpCheck.fetch(viaTunnel: false);
    if (widget.connected) {
      _tunnel = DevIpCheck.fetch(viaTunnel: true);
    }
  }

  void _refresh() {
    setState(() {
      _real = DevIpCheck.fetch(viaTunnel: false);
      if (widget.connected) _tunnel = DevIpCheck.fetch(viaTunnel: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return AlertDialog(
      backgroundColor: palette.card,
      title: Text(
        'IP & Location',
        style: TextStyle(
          color: palette.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IpRow(
            label: 'Real network (bypasses tunnel)',
            future: _real,
            palette: palette,
          ),
          const SizedBox(height: 14),
          if (_tunnel != null)
            _IpRow(
              label: 'Through tunnel (exit node)',
              future: _tunnel!,
              palette: palette,
            )
          else
            Text(
              'Not connected — connect to see the tunnel exit IP.',
              style: TextStyle(color: palette.textSecondary, fontSize: 12),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: _refresh, child: const Text('Refresh')),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _IpRow extends StatelessWidget {
  final String label;
  final Future<DevIpResult> future;
  final AppPalette palette;
  const _IpRow({
    required this.label,
    required this.future,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: palette.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        FutureBuilder<DevIpResult>(
          future: future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.primary,
                ),
              );
            }
            if (snap.hasError) {
              return Text(
                'Failed: ${snap.error}',
                style: TextStyle(color: palette.textSecondary, fontSize: 12),
              );
            }
            final r = snap.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  r.ip,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  r.location,
                  style:
                      TextStyle(color: palette.textSecondary, fontSize: 12),
                ),
                if (r.isp.isNotEmpty)
                  Text(
                    r.isp,
                    style:
                        TextStyle(color: palette.textSecondary, fontSize: 11),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// A card row with a title/subtitle and a [Switch] driven by a [ValueNotifier].
class _DevSwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final AppPalette palette;
  final Listenable listenable;
  final bool Function() valueOf;
  final Future<void> Function(bool) onChanged;
  const _DevSwitchTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.palette,
    required this.listenable,
    required this.valueOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: palette.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: listenable,
            builder: (context, _) => Switch(
              value: valueOf(),
              activeThumbColor: palette.primary,
              onChanged: (v) => onChanged(v),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final AppPalette palette;
  const _ThemeTile({required this.palette});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        final isDark = mode == ThemeMode.dark;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: palette.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Dark Mode',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: isDark,
                activeThumbColor: palette.primary,
                onChanged: (_) => context.read<ThemeCubit>().toggle(),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Mutually exclusive connection-mode switch: OFF = stealth/proxy mode
/// (default — traffic disguised as ordinary HTTPS), ON = VPN mode. Flipping it
/// while a session is active restarts the connection with the new mode.
class _VpnModeTile extends StatelessWidget {
  final AppPalette palette;
  const _VpnModeTile({required this.palette});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionSettingsCubit, ConnectionSettingsEntity>(
      builder: (context, settings) {
        final isVpn = settings.mode == ConnectionMode.vpn;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Icon(
                isVpn ? Icons.vpn_lock_rounded : Icons.visibility_off_rounded,
                color: palette.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VPN Mode',
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isVpn
                          ? 'Standard encrypted tunnel'
                          : 'Stealth mode: traffic disguised as normal HTTPS',
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isVpn,
                activeThumbColor: palette.primary,
                onChanged: (enabled) {
                  context
                      .read<ConnectionSettingsCubit>()
                      .toggleVpnMode(enabled);
                  // Auto-reconnect so the mode change takes effect right away.
                  final connectionBloc = context.read<ProxyConnectionBloc>();
                  final stage = connectionBloc.state.stage;
                  if (stage == VpnStage.connected ||
                      stage == VpnStage.connecting) {
                    connectionBloc.add(const ReconnectWithSettingsEvent());
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppPalette palette;
  final VoidCallback onTap;
  const _Tile({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: palette.primary),
        title: Text(
          label,
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded,
            color: palette.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
