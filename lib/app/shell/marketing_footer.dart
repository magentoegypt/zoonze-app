import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/util/launch.dart';
import '../../core/validation/validators.dart';
import '../../core/widgets/brand_lockup.dart';
import '../../l10n/l10n.dart';
import '../routes.dart';
import '../theme/app_colors.dart';

/// Marketing footer shown on content screens (home, PLP, PDP, cart, …) in both
/// EN and AR. Links navigate to in-app destinations (categories, Help) or the
/// website; the newsletter validates the email and confirms locally.
class MarketingFooter extends StatefulWidget {
  const MarketingFooter({super.key});

  @override
  State<MarketingFooter> createState() => _MarketingFooterState();
}

class _MarketingFooterState extends State<MarketingFooter> {
  static const String _websiteUrl = 'https://zoonze.com';
  final TextEditingController _newsletter = TextEditingController();

  @override
  void dispose() {
    _newsletter.dispose();
    super.dispose();
  }

  void _subscribe() {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (Validators.email(context, _newsletter.text) != null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.validationEmail)));
      return;
    }
    _newsletter.clear();
    FocusScope.of(context).unfocus();
    messenger.showSnackBar(SnackBar(content: Text(l10n.footerSubscribed)));
  }

  Future<void> _openWebsite() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    if (!await launchExternalUri(Uri.parse(_websiteUrl))) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }

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
                  links: [
                    (
                      label: l10n.homeShopByCategory,
                      onTap: () => context.go(AppRoutes.categories),
                    ),
                    (
                      label: l10n.homeFeatured,
                      onTap: () => context.go(AppRoutes.home),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _LinkColumn(
                  heading: l10n.footerSupport,
                  links: [
                    (label: l10n.footerAbout, onTap: _openWebsite),
                    (
                      label: l10n.footerContact,
                      onTap: () => context.push(AppRoutes.help),
                    ),
                    (
                      label: l10n.footerShipping,
                      onTap: () => context.push(AppRoutes.help),
                    ),
                    (
                      label: l10n.footerReturns,
                      onTap: () => context.push(AppRoutes.help),
                    ),
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
                  controller: _newsletter,
                  keyboardType: TextInputType.emailAddress,
                  onSubmitted: (_) => _subscribe(),
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
              FilledButton(
                onPressed: _subscribe,
                child: Text(l10n.footerSubscribe),
              ),
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

typedef _FooterLink = ({String label, VoidCallback onTap});

class _LinkColumn extends StatelessWidget {
  const _LinkColumn({required this.heading, required this.links});
  final String heading;
  final List<_FooterLink> links;

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
          InkWell(
            onTap: link.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                link.label,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
      ],
    );
  }
}
