import 'package:intl/intl.dart';

/// Formats a Magento order timestamp (e.g. `2026-06-25 10:24:33`) as a short
/// date in the active [locale] (so AR renders Arabic month names) — falls back
/// to the raw string when it can't be parsed, and to the default locale if the
/// locale's date symbols aren't loaded.
String orderFmtDate(String raw, [String? locale]) {
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw;
  try {
    return DateFormat('d MMM yyyy', locale).format(dt);
  } catch (_) {
    return DateFormat('d MMM yyyy').format(dt);
  }
}

/// Formats a Magento order timestamp as a short date + time
/// (e.g. `25 Jun, 10:24 AM`), localized to [locale].
String orderFmtDateTime(String raw, [String? locale]) {
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw;
  try {
    return DateFormat('d MMM, h:mm a', locale).format(dt);
  } catch (_) {
    return DateFormat('d MMM, h:mm a').format(dt);
  }
}
