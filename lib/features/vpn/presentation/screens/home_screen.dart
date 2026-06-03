import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/routes_manager.dart';
import '../../../../../core/utils/app_colors.dart';
import '../bloc/vpn_connection_bloc/vpn_connection_bloc.dart';
import '../bloc/vpn_servers_bloc/vpn_servers_bloc.dart';
import '../widgets/vpn_connect_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  VpnStage? _lastStage;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final stage = context.read<VpnConnectionBloc>().state.stage;
      if (stage == VpnStage.connected) {
        setState(() => _elapsed += const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatTimer(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(d.inHours);
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: BlocConsumer<VpnConnectionBloc, VpnConnectionState>(
          listener: (context, state) {
            if (_lastStage != state.stage) {
              if (state.stage == VpnStage.connected &&
                  _lastStage != VpnStage.connected) {
                setState(() => _elapsed = Duration.zero);
              } else if (state.stage == VpnStage.disconnected) {
                setState(() => _elapsed = Duration.zero);
              }
              _lastStage = state.stage;
            }
          },
          builder: (context, connectionState) {
            return Column(
              children: [
                _AppBar(palette: palette),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _SpeedRow(state: connectionState, palette: palette),
                        const SizedBox(height: 24),
                        VpnConnectButton(
                          state: connectionState,
                          onTap: () => _onConnectTap(context, connectionState),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _statusLabel(connectionState.stage),
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatTimer(_elapsed),
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _SelectedServerCard(palette: palette),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _statusLabel(VpnStage stage) => switch (stage) {
        VpnStage.connected => 'Connected',
        VpnStage.connecting => 'Connecting',
        VpnStage.disconnecting => 'Disconnecting',
        VpnStage.error => 'Error',
        _ => 'Disconnected',
      };

  void _onConnectTap(BuildContext context, VpnConnectionState state) {
    final bloc = context.read<VpnConnectionBloc>();
    if (state.stage == VpnStage.connecting ||
        state.stage == VpnStage.connected) {
      bloc.add(const DisconnectVpnEvent());
      return;
    }
    final serversState = context.read<VpnServersBloc>().state;
    if (serversState is VpnServersLoaded &&
        !serversState.selectedServer.isEmpty) {
      bloc.add(ConnectVpnEvent(serversState.selectedServer));
    } else {
      Navigator.pushNamed(context, Routes.location);
    }
  }
}

class _AppBar extends StatelessWidget {
  final AppPalette palette;
  const _AppBar({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(Icons.menu_rounded, color: palette.textPrimary, size: 26),
          const Spacer(),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Mash ',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: 'VPN',
                  style: TextStyle(
                    color: palette.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, Routes.premium),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: palette.accent,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedRow extends StatelessWidget {
  final VpnConnectionState state;
  final AppPalette palette;
  const _SpeedRow({required this.state, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SpeedPill(
            icon: Icons.south_rounded,
            label: 'Download',
            value: _normalize(state.status.byteIn),
            palette: palette,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SpeedPill(
            icon: Icons.north_rounded,
            label: 'Upload',
            value: _normalize(state.status.byteOut),
            palette: palette,
          ),
        ),
      ],
    );
  }

  String _normalize(String? raw) {
    if (raw == null || raw.isEmpty) return '00 Mbps';
    return raw;
  }
}

class _SpeedPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final AppPalette palette;
  const _SpeedPill({
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
              Text(
                label,
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectedServerCard extends StatelessWidget {
  final AppPalette palette;
  const _SelectedServerCard({required this.palette});

  String _flagEmoji(String code) {
    if (code.isEmpty) return '🌐';
    return code.toUpperCase().runes
        .map((r) => String.fromCharCode(r - 0x41 + 0x1F1E6))
        .join();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VpnServersBloc, VpnServersState>(
      builder: (context, state) {
        final server =
            state is VpnServersLoaded ? state.selectedServer : null;
        final hasServer = server != null && !server.isEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Selected Server',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, Routes.location),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.border),
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
                      child: Text(
                        _flagEmoji(hasServer ? server.countryShort : ''),
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Auto ',
                                  style: TextStyle(
                                    color: palette.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Fast Server',
                                  style: TextStyle(
                                    color: palette.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasServer
                                ? server.countryLong
                                : 'Tap to select a server',
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: palette.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
