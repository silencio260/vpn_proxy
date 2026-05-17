import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/routes_manager.dart';
import '../../../../../core/utils/app_colors.dart';
import '../bloc/vpn_connection_bloc/vpn_connection_bloc.dart';
import '../bloc/vpn_servers_bloc/vpn_servers_bloc.dart';
import '../widgets/status_card.dart';
import '../widgets/vpn_connect_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<VpnConnectionBloc, VpnConnectionState>(
          builder: (context, connectionState) {
            return Column(
              children: [
                _AppBar(connectionState: connectionState),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        VpnConnectButton(
                          state: connectionState,
                          onTap: () => _onConnectTap(context, connectionState),
                        ),
                        const SizedBox(height: 40),
                        _IpRow(connectionState: connectionState),
                        const SizedBox(height: 24),
                        _StatsGrid(connectionState: connectionState),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                _ChangeLocationBar(onTap: () {
                  Navigator.pushNamed(context, Routes.location);
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onConnectTap(BuildContext context, VpnConnectionState state) {
    if (state.isConnected || state.stage == VpnStage.disconnecting) {
      context.read<VpnConnectionBloc>().add(const DisconnectVpnEvent());
    } else {
      final serversState = context.read<VpnServersBloc>().state;
      if (serversState is VpnServersLoaded &&
          !serversState.selectedServer.isEmpty) {
        context
            .read<VpnConnectionBloc>()
            .add(ConnectVpnEvent(serversState.selectedServer));
      } else {
        Navigator.pushNamed(context, Routes.location);
      }
    }
  }
}

class _AppBar extends StatelessWidget {
  final VpnConnectionState connectionState;

  const _AppBar({required this.connectionState});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.shield, color: AppColors.primary, size: 28),
          const SizedBox(width: 10),
          const Text(
            'VPN Proxy',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          _StatusBadge(stage: connectionState.stage),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final VpnStage stage;

  const _StatusBadge({required this.stage});

  Color get _color => switch (stage) {
        VpnStage.connected => AppColors.connected,
        VpnStage.connecting || VpnStage.disconnecting => AppColors.connecting,
        _ => AppColors.disconnected,
      };

  String get _label => switch (stage) {
        VpnStage.connected => 'Connected',
        VpnStage.connecting => 'Connecting',
        VpnStage.disconnecting => 'Disconnecting',
        _ => 'Disconnected',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _color),
          ),
          const SizedBox(width: 6),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IpRow extends StatelessWidget {
  final VpnConnectionState connectionState;

  const _IpRow({required this.connectionState});

  @override
  Widget build(BuildContext context) {
    final ip = connectionState.ipDetails.query;
    final country = connectionState.ipDetails.country;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ip.isEmpty ? '—' : ip,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                country.isEmpty ? 'Your IP Address' : country,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final VpnConnectionState connectionState;

  const _StatsGrid({required this.connectionState});

  String _format(String? raw) => raw?.isNotEmpty == true ? raw! : '0 B';

  @override
  Widget build(BuildContext context) {
    final status = connectionState.status;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        StatusCard(
          icon: Icons.timer_outlined,
          label: 'Duration',
          value: _format(status.duration),
        ),
        StatusCard(
          icon: Icons.network_check,
          label: 'Last Packet',
          value: _format(status.lastPacketReceive),
        ),
        StatusCard(
          icon: Icons.arrow_downward,
          label: 'Download',
          value: _format(status.byteIn),
        ),
        StatusCard(
          icon: Icons.arrow_upward,
          label: 'Upload',
          value: _format(status.byteOut),
        ),
      ],
    );
  }
}

class _ChangeLocationBar extends StatelessWidget {
  final VoidCallback onTap;

  const _ChangeLocationBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BlocBuilder<VpnServersBloc, VpnServersState>(
        builder: (context, state) {
          final server = state is VpnServersLoaded
              ? state.selectedServer
              : null;
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.public, color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server != null && !server.isEmpty
                            ? server.countryLong
                            : 'Select a server',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (server != null && !server.isEmpty)
                        Text(
                          server.hostname,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.primary,
                  size: 22,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
