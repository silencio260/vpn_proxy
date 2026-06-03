import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/routes_manager.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../domain/vpn_server_quality_sorter.dart';
import '../../domain/entities/vpn_server_entity.dart';
import '../bloc/vpn_servers_bloc/vpn_servers_bloc.dart';
import '../widgets/vpn_server_card.dart';

/// Free vs Premium split — first [_kFreeCount] servers (after sorting) count
/// as Free; the rest require premium and are shown locked.
const int _kFreeCount = 8;

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    final state = context.read<VpnServersBloc>().state;
    if (state is! VpnServersLoaded) {
      context.read<VpnServersBloc>().add(const FetchVpnServersEvent());
    }
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
          'Select Server',
          style: TextStyle(
            color: palette.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: palette.primary),
            onPressed:
                () => context.read<VpnServersBloc>().add(
                  const FetchVpnServersEvent(forceHealthRefresh: true),
                ),
          ),
        ],
      ),
      body: BlocBuilder<VpnServersBloc, VpnServersState>(
        builder: (context, state) {
          if (state is VpnServersLoading) {
            return Center(
              child: CircularProgressIndicator(color: palette.primary),
            );
          }
          if (state is VpnServersError) {
            return _ErrorView(
              message: state.message,
              palette: palette,
              onRetry:
                  () => context.read<VpnServersBloc>().add(
                    const FetchVpnServersEvent(forceHealthRefresh: true),
                  ),
            );
          }
          if (state is VpnServersLoaded) {
            final all = state.servers;
            if (all.isEmpty) {
              return _ErrorView(
                message: 'No servers available',
                palette: palette,
                onRetry:
                    () => context.read<VpnServersBloc>().add(
                      const FetchVpnServersEvent(forceHealthRefresh: true),
                    ),
              );
            }
            final filtered =
                _query.isEmpty
                    ? all.toList()
                    : all
                        .where(
                          (s) =>
                              s.countryLong.toLowerCase().contains(
                                _query.toLowerCase(),
                              ) ||
                              s.hostname.toLowerCase().contains(
                                _query.toLowerCase(),
                              ),
                        )
                        .toList();

            final freeKeys =
                all
                    .take(_kFreeCount)
                    .map(VpnServerQualitySorter.keyForServer)
                    .toSet();
            final free =
                filtered
                    .where(
                      (s) => freeKeys.contains(
                        VpnServerQualitySorter.keyForServer(s),
                      ),
                    )
                    .toList()
                  ..sort(
                    (a, b) => VpnServerQualitySorter.compare(
                      a,
                      b,
                      state.healthByServerKey,
                    ),
                  );
            final premium =
                filtered
                    .where(
                      (s) =>
                          !freeKeys.contains(
                            VpnServerQualitySorter.keyForServer(s),
                          ),
                    )
                    .toList()
                  ..sort(
                    (a, b) => VpnServerQualitySorter.compare(
                      a,
                      b,
                      state.healthByServerKey,
                    ),
                  );

            return ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              children: [
                _SearchBar(
                  palette: palette,
                  onChanged: (v) => setState(() => _query = v),
                ),
                if (state.isHealthChecking || state.healthTotalCount > 0)
                  _HealthProgressPill(state: state, palette: palette),
                const SizedBox(height: 8),
                _SectionHeader(
                  title: 'Free Server',
                  trailing: 'View All',
                  palette: palette,
                ),
                ...free.map(
                  (s) => VpnServerCard(
                    server: s,
                    health:
                        state
                            .healthByServerKey[VpnServerQualitySorter.keyForServer(
                          s,
                        )],
                    isSelected: s == state.selectedServer,
                    onTap: () => _select(context, s),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionHeader(
                  title: 'Premium Server',
                  trailing: 'Go Premium 👑',
                  trailingColor: palette.accent,
                  palette: palette,
                ),
                ...premium.map(
                  (s) => VpnServerCard(
                    server: s,
                    health:
                        state
                            .healthByServerKey[VpnServerQualitySorter.keyForServer(
                          s,
                        )],
                    isSelected: false,
                    isLocked: true,
                    onTap: () => Navigator.pushNamed(context, Routes.premium),
                  ),
                ),
              ],
            );
          }
          return Center(
            child: Text(
              'Pull to refresh servers',
              style: TextStyle(color: palette.textSecondary),
            ),
          );
        },
      ),
    );
  }

  void _select(BuildContext context, VpnServerEntity s) {
    context.read<VpnServersBloc>().add(SelectVpnServerEvent(s));
    Navigator.pop(context);
  }
}

class _HealthProgressPill extends StatelessWidget {
  final VpnServersLoaded state;
  final AppPalette palette;

  const _HealthProgressPill({required this.state, required this.palette});

  @override
  Widget build(BuildContext context) {
    final text =
        state.isHealthChecking
            ? 'Checking ${state.healthCheckedCount}/${state.healthTotalCount}'
            : 'Checked ${state.healthCheckedCount}/${state.healthTotalCount}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: palette.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: palette.primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child:
                    state.isHealthChecking
                        ? CircularProgressIndicator(
                          strokeWidth: 2,
                          color: palette.primary,
                        )
                        : Icon(
                          Icons.check_circle_rounded,
                          size: 12,
                          color: palette.primary,
                        ),
              ),
              const SizedBox(width: 7),
              Text(
                text,
                style: TextStyle(
                  color: palette.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final AppPalette palette;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.palette, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(color: palette.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search Server Name',
          prefixIcon: Icon(Icons.search_rounded, color: palette.textSecondary),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String trailing;
  final Color? trailingColor;
  final AppPalette palette;
  const _SectionHeader({
    required this.title,
    required this.trailing,
    required this.palette,
    this.trailingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            trailing,
            style: TextStyle(
              color: trailingColor ?? palette.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final AppPalette palette;
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 64, color: palette.textHint),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: palette.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
