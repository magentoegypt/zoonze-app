import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/store_contact.dart';
import '../../core/store/store_controller.dart';
import '../../core/util/launch.dart';
import '../../core/validation/validators.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/social_icon.dart';
import '../../l10n/l10n.dart';
import '../routes.dart';
import '../theme/app_colors.dart';

/// Marketing footer shown on content screens (home, PLP, PDP, cart, …) in both
/// EN and AR. Social links + website come from admin config
/// ([storeContactProvider]); other links navigate in-app; the newsletter
/// validates the email and confirms locally.
class MarketingFooter extends ConsumerStatefulWidget {
  const MarketingFooter({super.key});

  @override
  ConsumerState<MarketingFooter> createState() => _MarketingFooterState();
}

class _MarketingFooterState extends ConsumerState<MarketingFooter> {
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

  /// Slug for a store CMS page, relative to the active store's base URL. "About
  /// Us" has an AR-specific slug; the rest are shared. Verified against the live
  /// zoonze.com footer (uae-en / uae-ar).
  String _cmsSlug(String page, bool isAr) => switch (page) {
    'about' => isAr ? 'about-us-ar' : 'about-us',
    'faqs' => 'faqs',
    'shipping' => 'shipping-delivery',
    'returns' => 'returns-exchanges',
    'privacy' => 'privacy-policy-cookie-restriction-mode',
    'terms' => 'terms-conditions',
    _ => '',
  };

  /// Opens a store CMS page on the active store's website (correct per-locale
  /// URL), instead of dumping the user on the homepage.
  Future<void> _openCms(String page) async {
    final store = ref.read(storeControllerProvider);
    var base = ref.read(storeContactProvider).website;
    for (final s in store.stores) {
      if (s.storeCode == store.activeStoreCode) {
        final b = s.secureBaseUrl.isNotEmpty ? s.secureBaseUrl : s.baseUrl;
        if (b.isNotEmpty) base = b;
        break;
      }
    }
    final slug = _cmsSlug(page, store.activeLocale == 'ar');
    final sep = base.endsWith('/') ? '' : '/';
    await _openUrl('$base$sep$slug/');
  }

  Future<void> _openUrl(String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    if (!await launchExternalUri(Uri.parse(url))) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final socials = ref.watch(storeContactProvider).socials;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      color: AppColors.surfaceDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandLogo(onDark: true, height: 48),
          const SizedBox(height: 16),
          Text(
            l10n.footerTagline,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 20),
          // Social row — admin-configured links (hidden when none are set).
          if (socials.isNotEmpty)
            Row(
              children: [
                for (final s in socials)
                  _SocialButton(
                    icon: socialIconFor(s.key),
                    onTap: () => _openUrl(s.url),
                  ),
              ],
            ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "About Us" column — matches the website footer grouping.
              Expanded(
                child: _LinkColumn(
                  heading: l10n.footerAboutHeading,
                  links: [
                    (label: l10n.footerAbout, onTap: () => _openCms('about')),
                    (label: l10n.footerFaqs, onTap: () => _openCms('faqs')),
                    (
                      label: l10n.footerContact,
                      onTap: () => context.push(AppRoutes.help),
                    ),
                    (
                      label: l10n.footerTrackOrder,
                      onTap: () => context.push(AppRoutes.orders),
                    ),
                  ],
                ),
              ),
              // "Customer Service" column — matches the website footer grouping.
              Expanded(
                child: _LinkColumn(
                  heading: l10n.footerSupport,
                  links: [
                    (
                      label: l10n.footerShipping,
                      onTap: () => _openCms('shipping'),
                    ),
                    (
                      label: l10n.footerReturns,
                      onTap: () => _openCms('returns'),
                    ),
                    (label: l10n.footerPrivacy, onTap: () => _openCms('privacy')),
                    (label: l10n.footerTerms, onTap: () => _openCms('terms')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            l10n.footerNewsletterTitle.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.footerNewsletterSubtitle,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 12),
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
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _subscribe,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
                child: Text(l10n.footerSubscribe),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          // Accepted payment methods — matches the website footer.
          const Center(child: _PaymentBadges()),
          const SizedBox(height: 14),
          // Copyright — centered like the website (was start-aligned).
          Center(
            child: Text(
              l10n.footerRights,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Accepted-payment badges row shown above the footer copyright (card · tabby ·
/// Mastercard · Visa), mirroring the website footer. Rendered as lightweight
/// brand chips; swap in official brand assets if/when they're provided.
class _PaymentBadges extends StatelessWidget {
  const _PaymentBadges();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PayChip(child: Icon(Icons.credit_card, size: 18, color: Color(0xFF1F2937))),
        SizedBox(width: 8),
        _PayChip(
          child: Text(
            'tabby',
            style: TextStyle(
              color: Color(0xFF3EB34F),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        SizedBox(width: 8),
        _PayChip(child: _MastercardMark()),
        SizedBox(width: 8),
        _PayChip(
          child: Text(
            'VISA',
            style: TextStyle(
              color: Color(0xFF1A1F71),
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// White rounded chip that hosts one payment mark.
class _PayChip extends StatelessWidget {
  const _PayChip({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 27,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(5),
    ),
    child: child,
  );
}

/// Mastercard's two overlapping circles.
class _MastercardMark extends StatelessWidget {
  const _MastercardMark();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 26,
    height: 16,
    child: Stack(
      children: [
        Positioned(
          left: 0,
          child: _dot(const Color(0xFFEB001B)),
        ),
        Positioned(
          right: 0,
          child: _dot(const Color(0xFFF79E1B)),
        ),
      ],
    ),
  );

  Widget _dot(Color color) => Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
    ),
  );
}

/// Circular bordered social button (icon or short label) for the footer.
class _SocialButton extends StatelessWidget {
  const _SocialButton({this.icon, this.label, required this.onTap})
    : assert(icon != null || label != null);

  final IconData? icon;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 10),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 18)
              : Text(
                  label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
        ),
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
          heading.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1,
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
