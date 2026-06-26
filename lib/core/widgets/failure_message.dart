import 'package:flutter/widgets.dart';

import '../../l10n/l10n.dart';
import '../error/failure.dart';

/// Maps a [Failure] to a localized, user-friendly message.
String failureMessage(BuildContext context, Failure failure) {
  final l10n = AppLocalizations.of(context);
  switch (failure.kind) {
    case FailureKind.network:
      return l10n.errorNetwork;
    case FailureKind.service:
      return l10n.errorService;
    case FailureKind.auth:
    case FailureKind.unknown:
      return l10n.errorGeneric;
    case FailureKind.server:
      return failure.detail ?? l10n.errorGeneric;
  }
}
