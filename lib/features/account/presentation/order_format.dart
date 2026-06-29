import 'package:intl/intl.dart';

/// Formats a Magento order timestamp (e.g. `2026-06-25 10:24:33`) as a short
/// date — falls back to the raw string when it can't be parsed.
String orderFmtDate(String raw) {
  final dt = DateTime.tryParse(raw);
  return dt == null ? raw : DateFormat('d MMM yyyy').format(dt);
}

/// Formats a Magento order timestamp as a short date + time
/// (e.g. `25 Jun, 10:24 AM`).
String orderFmtDateTime(String raw) {
  final dt = DateTime.tryParse(raw);
  return dt == null ? raw : DateFormat('d MMM, h:mm a').format(dt);
}
