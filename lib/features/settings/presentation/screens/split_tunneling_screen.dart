import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../container_injector.dart';
import '../../../../core/analytics/app_analytics_service.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../proxy/presentation/bloc/proxy_connection_bloc/proxy_connection_bloc.dart';
import '../../../vpn/presentation/bloc/vpn_connection_bloc/vpn_connection_bloc.dart';
import '../../data/datasources/installed_apps_data_source.dart';
import '../../domain/entities/connection_settings_entity.dart';
import '../../domain/entities/installed_app_entity.dart';
import '../cubit/connection_settings_cubit.dart';

/// Split tunneling: pick which installed apps are EXCLUDED from the tunnel
/// (their traffic uses the normal network instead of the proxy).
///
/// Toggles persist immediately via [ConnectionSettingsCubit]; if the exclusion
/// set changed while a session is active, one reconnect is triggered when the
/// user leaves the screen (not per tap) so the engine picks up the new list.
class SplitTunnelingScreen extends StatefulWidget {
  const SplitTunnelingScreen({super.key});

  @override
  State<SplitTunnelingScreen> createState() => _SplitTunnelingScreenState();
}

class _SplitTunnelingScreenState extends State<SplitTunnelingScreen> {
  late final Future<List<InstalledAppEntity>> _appsFuture;
  late final ConnectionSettingsCubit _settings;
  late final ProxyConnectionBloc _connectionBloc;
  late final Set<String> _initialExclusions;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _appsFuture = sl<InstalledAppsDataSource>().getInstalledApps();
    _settings = context.read<ConnectionSettingsCubit>();
    _connectionBloc = context.read<ProxyConnectionBloc>();
    _initialExclusions = Set.of(_settings.state.excludedApps);
  }

  @override
  void dispose() {
    // Apply once on exit: both blocs are app-level singletons/providers that
    // outlive this screen, so it's safe to poke them here.
    final current = _settings.state.excludedApps;
    if (!setEquals(current, _initialExclusions)) {
      AppAnalyticsService.instance
          .logSplitTunnelUpdated(excludedCount: current.length);
      final stage = _connectionBloc.state.stage;
      if (stage == VpnStage.connected || stage == VpnStage.connecting) {
        _connectionBloc.add(const ReconnectWithSettingsEvent());
      }
    }
    super.dispose();
  }

  static bool setEquals(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

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
          'Split Tunneling',
          style: TextStyle(
            color: palette.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Excluded apps bypass the tunnel and use your normal '
                'connection.',
                style: TextStyle(color: palette.textSecondary, fontSize: 13),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v.trim()),
                style: TextStyle(color: palette.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search apps',
                  hintStyle: TextStyle(color: palette.textSecondary),
                  prefixIcon:
                      Icon(Icons.search_rounded, color: palette.textSecondary),
                  filled: true,
                  fillColor: palette.card,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: palette.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: palette.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: palette.primary),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<InstalledAppEntity>>(
                future: _appsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Center(
                      child: CircularProgressIndicator(color: palette.primary),
                    );
                  }
                  final apps = snapshot.data ?? const <InstalledAppEntity>[];
                  if (apps.isEmpty) {
                    return Center(
                      child: Text(
                        snapshot.hasError
                            ? 'Could not load installed apps'
                            : 'No apps found',
                        style: TextStyle(color: palette.textSecondary),
                      ),
                    );
                  }
                  final q = _query.toLowerCase();
                  final visible = q.isEmpty
                      ? apps
                      : apps
                          .where((a) =>
                              a.name.toLowerCase().contains(q) ||
                              a.packageName.toLowerCase().contains(q))
                          .toList();
                  return BlocBuilder<ConnectionSettingsCubit,
                      ConnectionSettingsEntity>(
                    builder: (context, settings) {
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final app = visible[index];
                          return _AppTile(
                            app: app,
                            excluded:
                                settings.excludedApps.contains(app.packageName),
                            palette: palette,
                            onChanged: (_) => context
                                .read<ConnectionSettingsCubit>()
                                .toggleAppExclusion(app.packageName),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  final InstalledAppEntity app;
  final bool excluded;
  final AppPalette palette;
  final ValueChanged<bool> onChanged;
  const _AppTile({
    required this.app,
    required this.excluded,
    required this.palette,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final icon = app.icon;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: icon != null && icon.isNotEmpty
                ? Image.memory(icon, width: 34, height: 34, gaplessPlayback: true)
                : Icon(Icons.android_rounded,
                    size: 34, color: palette.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  app.packageName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(color: palette.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: excluded,
            activeThumbColor: palette.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
