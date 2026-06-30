import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/store_contact.dart';
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

  Future<void> _openWebsite() =>
      _openUrl(ref.read(storeContactProvider).website);

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
              Expanded(
                child: _LinkColumn(
                  heading: l10n.footerAboutHeading,
                  links: [
                    (label: l10n.footerAbout, onTap: _openWebsite),
                    (
                      label: l10n.footerContact,
                      onTap: () => context.push(AppRoutes.help),
                    ),
                    (label: l10n.footerStoreLocator, onTap: _openWebsite),
                    (
                      label: l10n.footerTrackOrder,
                      onTap: () => context.push(AppRoutes.orders),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _LinkColumn(
                  heading: l10n.footerSupport,
                  links: [
                    (
                      label: l10n.footerShippingReturns,
                      onTap: () => context.push(AppRoutes.help),
                    ),
                    (
                      label: l10n.footerFaqs,
                      onTap: () => context.push(AppRoutes.help),
                    ),
                    (label: l10n.footerPrivacy, onTap: _openWebsite),
                    (label: l10n.footerTerms, onTap: _openWebsite),
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
          Text(
            l10n.footerRights,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
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
