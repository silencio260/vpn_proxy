import 'package:flutter/material.dart';

import '../../../../../config/routes_manager.dart';
import '../../../../../core/utils/app_colors.dart';

class PremiumScreen extends StatelessWidget {
  final bool embedded;
  const PremiumScreen({super.key, this.embedded = false});

  static const _plans = [
    _Plan('Basic Plan', '6.99', '/Week'),
    _Plan('Advance Plan', '12.99', '/Month'),
    _Plan('Premium Plan', '29.99', '/years', highlighted: true),
  ];

  static const _features = [
    'All Premium Services',
    'Access All Application and site',
    'Bandwidth High',
    'Connection Speed',
    'Safe Browsing and Security',
    'Surfing Any ads Enjoy',
  ];

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
                'Premium',
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
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: Text(
                    'Premium',
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Center(
              child: Icon(
                Icons.workspace_premium_rounded,
                color: palette.accent,
                size: 56,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Upgrade To Premium',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Get Unlimited Access & all Features',
                style:
                    TextStyle(color: palette.textSecondary, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
            ..._features.map((f) => _FeatureRow(text: f, palette: palette)),
            const SizedBox(height: 24),
            ..._plans.map((p) => _PlanCard(plan: p, palette: palette)),
          ],
        ),
      ),
    );
  }
}

class _Plan {
  final String name;
  final String price;
  final String period;
  final bool highlighted;
  const _Plan(this.name, this.price, this.period,
      {this.highlighted = false});
}

class _FeatureRow extends StatelessWidget {
  final String text;
  final AppPalette palette;
  const _FeatureRow({required this.text, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              size: 20, color: palette.success),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(color: palette.textPrimary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final AppPalette palette;
  const _PlanCard({required this.plan, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: plan.highlighted ? palette.primary : palette.border,
          width: plan.highlighted ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: plan.price,
                        style: TextStyle(
                          color: palette.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: plan.period,
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, Routes.paymentSuccess),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            child: const Text('Buy Now'),
          ),
        ],
      ),
    );
  }
}
