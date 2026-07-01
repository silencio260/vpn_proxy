import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/country_util.dart';
import '../../domain/entities/proxy_entity.dart';
import '../bloc/proxy_bloc/proxy_bloc.dart';
import '../widgets/proxy_card.dart';

class ProxyListScreen extends StatefulWidget {
  /// When embedded inside another screen, renders only its list body
  /// without its own Scaffold/AppBar.
  final bool embedded;

  const ProxyListScreen({super.key, this.embedded = false});

  @override
  State<ProxyListScreen> createState() => _ProxyListScreenState();
}

class _ProxyListScreenState extends State<ProxyListScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    final state = context.read<ProxyBloc>().state;
    if (state is! ProxyLoaded) {
      context.read<ProxyBloc>().add(const FetchProxiesEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final body = _buildBody(context, palette);
    if (widget.embedded) return body;
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
                () => context.read<ProxyBloc>().add(
                  const FetchProxiesEvent(forceRefresh: true),
                ),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildBody(BuildContext context, AppPalette palette) {
    return BlocBuilder<ProxyBloc, ProxyState>(
      builder: (context, state) {
          if (state is ProxyLoading) {
            return Center(
              child: CircularProgressIndicator(color: palette.primary),
            );
          }
          if (state is ProxyError) {
            return _ErrorView(
              message: state.message,
              palette: palette,
              onRetry:
                  () => context.read<ProxyBloc>().add(
                    const FetchProxiesEvent(forceRefresh: true),
                  ),
            );
          }
          if (state is ProxyLoaded) {
            final all = state.proxies;
            if (all.isEmpty) {
              return _ErrorView(
                message: 'No proxies available',
                palette: palette,
                onRetry:
                    () => context.read<ProxyBloc>().add(
                      const FetchProxiesEvent(forceRefresh: true),
                    ),
              );
            }
            final q = _query.toLowerCase();
            final filtered =
                _query.isEmpty
                    ? all
                    : all.where((p) {
                      final code = p.deep?.egressCountry ?? '';
                      final country = CountryUtil.name(code);
                      return p.remark.toLowerCase().contains(q) ||
                          p.address.toLowerCase().contains(q) ||
                          p.type.toLowerCase().contains(q) ||
                          code.toLowerCase().contains(q) ||
                          country.toLowerCase().contains(q);
                    }).toList();

            return ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              children: [
                _SearchBar(
                  palette: palette,
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 8),
                ...filtered.map(
                  (p) => ProxyCard(
                    proxy: p,
                    isSelected: p == state.selectedProxy,
                    onTap: () => _select(context, p),
                  ),
                ),
              ],
            );
          }
          return Center(
            child: Text(
              'Pull to refresh proxies',
              style: TextStyle(color: palette.textSecondary),
            ),
          );
        },
      );
  }

  void _select(BuildContext context, ProxyEntity p) {
    context.read<ProxyBloc>().add(SelectProxyEvent(p));
    Navigator.pop(context);
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
          hintText: 'Search Proxy',
          prefixIcon: Icon(Icons.search_rounded, color: palette.textSecondary),
        ),
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
