import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/util/launch.dart';
import '../../../../l10n/l10n.dart';

/// Static, bilingual Help & FAQ screen. Answers the common storefront
/// questions and offers two contact actions (email / website) via
/// `url_launcher`. No backend dependency — content lives in ARB.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const String _supportEmail = 'support@zoonze.com';
  static const String _websiteUrl = 'https://zoonze.com';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final faqs = <(String, String)>[
      (l10n.helpQOrders, l10n.helpAOrders),
      (l10n.helpQPayments, l10n.helpAPayments),
      (l10n.helpQDelivery, l10n.helpADelivery),
      (l10n.helpQReturns, l10n.helpAReturns),
      (l10n.helpQLanguage, l10n.helpALanguage),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountHelp)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              l10n.helpIntro,
              style: const TextStyle(color: AppColors.inkMuted),
            ),
          ),
          for (final (question, answer) in faqs)
            ExpansionTile(
              title: Text(
                question,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              childrenPadding: const EdgeInsetsDirectional.fromSTEB(
                16,
                0,
                16,
                16,
              ),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(answer)],
            ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
            child: Text(
              l10n.helpContactTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.mail_outline,
              color: AppColors.brandPrimary,
            ),
            title: Text(l10n.helpEmailAction),
            subtitle: const Text(_supportEmail),
            onTap: () => _open(context, mailtoUri(_supportEmail)),
          ),
          ListTile(
            leading: const Icon(
              Icons.public_outlined,
              color: AppColors.brandPrimary,
            ),
            title: Text(l10n.helpWebsiteAction),
            subtitle: const Text(_websiteUrl),
            onTap: () => _open(context, Uri.parse(_websiteUrl)),
          ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final ok = await launchExternalUri(uri);
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }
}
