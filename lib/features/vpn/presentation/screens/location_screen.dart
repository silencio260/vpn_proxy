import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_colors.dart';
import '../bloc/vpn_servers_bloc/vpn_servers_bloc.dart';
import '../widgets/vpn_server_card.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Select Server',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () =>
                context.read<VpnServersBloc>().add(const FetchVpnServersEvent()),
          ),
        ],
      ),
      body: BlocBuilder<VpnServersBloc, VpnServersState>(
        builder: (context, state) {
          if (state is VpnServersLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is VpnServersError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context
                  .read<VpnServersBloc>()
                  .add(const FetchVpnServersEvent()),
            );
          }

          if (state is VpnServersLoaded) {
            if (state.servers.isEmpty) {
              return _ErrorView(
                message: 'No servers available',
                onRetry: () => context
                    .read<VpnServersBloc>()
                    .add(const FetchVpnServersEvent()),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: state.servers.length,
              itemBuilder: (context, index) {
                final server = state.servers[index];
                return VpnServerCard(
                  server: server,
                  isSelected: server == state.selectedServer,
                  onTap: () {
                    context
                        .read<VpnServersBloc>()
                        .add(SelectVpnServerEvent(server));
                    Navigator.pop(context);
                  },
                );
              },
            );
          }

          return const Center(
            child: Text(
              'Pull to refresh servers',
              style: TextStyle(color: Colors.white54),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () =>
            context.read<VpnServersBloc>().add(const FetchVpnServersEvent()),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
