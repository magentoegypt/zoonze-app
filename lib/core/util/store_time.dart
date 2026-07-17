import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Time left until the next midnight **in the store's timezone** — the store's
/// day, not the device's.
///
/// The website's countdown does exactly this: its template renders the store
/// timezone as a fixed `data-utc-offset` (240 = UTC+4 for `Asia/Dubai`) and
/// `beauty-countdown.js` counts to the next midnight at that offset, whatever
/// the visitor's own clock says. Using `DateTime.now()` here instead would make
/// the app disagree with the site for every shopper outside the store's zone —
/// e.g. a device on `Asia/Kolkata` (UTC+5:30) ran 1h30m ahead of zoonze.com.
///
/// [ianaZone] is `storeConfig { timezone }` (e.g. `Asia/Dubai`). An empty or
/// unknown zone falls back to the device's local midnight, which is the best
/// guess available and matches the pre-existing behaviour.
Duration untilNextStoreMidnight(String ianaZone, {DateTime? now}) {
  final instant = now ?? DateTime.now();
  final location = _location(ianaZone);
  if (location == null) return _untilNextLocalMidnight(instant);
  final storeNow = tz.TZDateTime.from(instant, location);
  // Day + 1 at 00:00 in the store's zone; TZDateTime normalises the rollover
  // across month/year ends and any DST shift the zone may have.
  final midnight = tz.TZDateTime(
    location,
    storeNow.year,
    storeNow.month,
    storeNow.day + 1,
  );
  return midnight.difference(storeNow);
}

Duration _untilNextLocalMidnight(DateTime now) =>
    DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1))
        .difference(now);

bool _dbReady = false;

/// Resolves an IANA zone name, loading the tz database on first use. Returns
/// null for an empty/unknown name so the caller can fall back.
tz.Location? _location(String ianaZone) {
  final name = ianaZone.trim();
  if (name.isEmpty) return null;
  if (!_dbReady) {
    // The 10-year database is ~1/5 the size of the full one and covers every
    // date this countdown can reach.
    tzdata.initializeTimeZones();
    _dbReady = true;
  }
  try {
    return tz.getLocation(name);
  } catch (_) {
    return null;
  }
}
