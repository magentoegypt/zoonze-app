import 'package:flutter/material.dart';

import '../../core/widgets/brand_lockup.dart';
import '../../l10n/l10n.dart';
import '../theme/app_colors.dart';

/// Marketing footer shown on content screens (home, PLP, PDP, cart, …) in both
/// EN and AR. Static for now; links are wired as their destinations land.
class MarketingFooter extends StatelessWidget {
  const MarketingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      color: AppColors.surfaceDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandLockup(color: Colors.white, fontSize: 22),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LinkColumn(
                  heading: l10n.footerShop,
                  links: [l10n.homeShopByCategory, l10n.homeFeatured],
                ),
              ),
              Expanded(
                child: _LinkColumn(
                  heading: l10n.footerSupport,
                  links: [
                    l10n.footerAbout,
                    l10n.footerContact,
                    l10n.footerShipping,
                    l10n.footerReturns,
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            l10n.footerNewsletterTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l10n.footerNewsletterHint,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: () {}, child: Text(l10n.footerSubscribe)),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            l10n.footerRights,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LinkColumn extends StatelessWidget {
  const _LinkColumn({required this.heading, required this.links});
  final String heading;
  final List<String> links;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        for (final link in links)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(link, style: const TextStyle(color: Colors.white70)),
          ),
      ],
    );
  }
}
