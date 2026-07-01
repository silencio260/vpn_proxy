import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../proxy/presentation/bloc/proxy_bloc/proxy_bloc.dart';
import '../../../proxy/presentation/screens/proxy_list_screen.dart';
import '../bloc/vpn_servers_bloc/vpn_servers_bloc.dart';
import 'location_screen.dart';

/// Hosts both the Firestore-backed proxy list and the legacy vpngate VPN
/// server list under a single screen, switched via a segmented toggle at the
/// top. Both child screens are rendered [embedded] (no inner Scaffold/AppBar).
class ServerSelectScreen extends StatefulWidget {
  const ServerSelectScreen({super.key});

  @override
  State<ServerSelectScreen> createState() => _ServerSelectScreenState();
}

class _ServerSelectScreenState extends State<ServerSelectScreen> {
  int _index = 0; // 0 = Proxies, 1 = VPN Servers

  void _refresh(BuildContext context) {
    if (_index == 0) {
      context.read<ProxyBloc>().add(const FetchProxiesEvent(forceRefresh: true));
    } else {
      context.read<VpnServersBloc>().add(
        const FetchVpnServersEvent(forceHealthRefresh: true),
      );
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
            onPressed: () => _refresh(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _SegToggle(
            index: _index,
            palette: palette,
            labels: const ['Proxies', 'VPN Servers'],
            onChanged: (i) => setState(() => _index = i),
          ),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [
                ProxyListScreen(embedded: true),
                LocationScreen(embedded: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegToggle extends StatelessWidget {
  final int index;
  final List<String> labels;
  final AppPalette palette;
  final ValueChanged<int> onChanged;

  const _SegToggle({
    required this.index,
    required this.labels,
    required this.palette,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: List.generate(labels.length, (i) {
            final selected = i == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? palette.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: selected ? Colors.white : palette.textSecondary,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
