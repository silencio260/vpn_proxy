import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/routes_manager.dart';
import '../../../../../config/theme_cubit.dart';
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
          ],
        ),
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
