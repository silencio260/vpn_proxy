import 'package:flutter/material.dart';

import '../../../../../config/routes_manager.dart';
import '../../../../../core/utils/app_colors.dart';

class AdsScreen extends StatelessWidget {
  final bool embedded;
  const AdsScreen({super.key, this.embedded = false});

  static const _offers = [
    _Offer('4 Ads in 1 minute', 'Earn 30 Minute'),
    _Offer('8 Ads in 3 minute', 'Earn 2 Hours'),
    _Offer('14 Ads in 5 minute', 'Earn 24 Hours'),
  ];

  void _watch(BuildContext context, _Offer offer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reward unlocked: ${offer.reward}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: embedded
          ? null
          : AppBar(
              backgroundColor: palette.background,
              title: Text(
                'Earn Time',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              leading: IconButton(
                icon:
                    Icon(Icons.arrow_back_rounded, color: palette.textPrimary),
                onPressed: () => Navigator.pop(context),
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
                    'Earn Connection Time',
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            Text(
              'Watch a few ads to extend your VPN time.',
              style: TextStyle(color: palette.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 18),
            ..._offers.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _OfferCard(
                    offer: o,
                    palette: palette,
                    onTap: () => _watch(context, o),
                  ),
                )),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'OR',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, Routes.premium),
                icon: Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 18),
                label: const Text('Remove Ads'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Offer {
  final String label;
  final String reward;
  const _Offer(this.label, this.reward);
}

class _OfferCard extends StatelessWidget {
  final _Offer offer;
  final AppPalette palette;
  final VoidCallback onTap;
  const _OfferCard({
    required this.offer,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: palette.accent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            offer.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -10),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                offer.reward,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
