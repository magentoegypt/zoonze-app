import 'package:flutter/widgets.dart';

import '../../l10n/l10n.dart';

/// Localized form-field validators.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? required(BuildContext context, String? value) =>
      (value == null || value.trim().isEmpty)
          ? AppLocalizations.of(context).validationRequired
          : null;

  static String? email(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) return l10n.validationRequired;
    return _email.hasMatch(value.trim()) ? null : l10n.validationEmail;
  }

  static String? password(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) return l10n.validationRequired;
    return value.length >= 8 ? null : l10n.validationPassword;
  }
}
