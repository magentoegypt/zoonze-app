import 'package:flutter_test/flutter_test.dart';
import 'package:zoonze_app/core/util/store_time.dart';

void main() {
  group('untilNextStoreMidnight', () {
    test('counts to midnight in the store zone, not the device zone', () {
      // 2026-07-17 11:29:37Z → 15:29:37 in Dubai (UTC+4). Next Dubai midnight
      // is 20:00:00Z, i.e. 8h30m23s away — whatever the device's own zone is.
      final now = DateTime.utc(2026, 7, 17, 11, 29, 37);
      expect(
        untilNextStoreMidnight('Asia/Dubai', now: now),
        const Duration(hours: 8, minutes: 30, seconds: 23),
      );
    });

    test('is independent of the device zone (the zoonze.com mismatch)', () {
      // The same instant expressed in a +05:30 local time must give the same
      // answer — the device on Asia/Kolkata was the reported bug.
      final utc = DateTime.utc(2026, 7, 17, 11, 29, 37);
      final kolkata = utc.add(const Duration(hours: 5, minutes: 30));
      final asLocalKolkata = DateTime.parse(
        '${kolkata.toIso8601String().substring(0, 19)}+05:30',
      );
      expect(
        untilNextStoreMidnight('Asia/Dubai', now: asLocalKolkata),
        untilNextStoreMidnight('Asia/Dubai', now: utc),
      );
    });

    test('rolls over month and year ends', () {
      expect(
        untilNextStoreMidnight(
          'Asia/Dubai',
          now: DateTime.utc(2026, 12, 31, 19, 0, 0), // 23:00 Dubai, NYE
        ),
        const Duration(hours: 1),
      );
    });

    test('never returns a non-positive duration', () {
      // 20:00:00Z is exactly Dubai midnight → a full day remains, not zero.
      expect(
        untilNextStoreMidnight('Asia/Dubai', now: DateTime.utc(2026, 7, 17, 20)),
        const Duration(hours: 24),
      );
    });

    test('handles a zone with DST', () {
      // 2026-07-17 is BST (UTC+1) in London: 22:15Z = 23:15 local → 45m left.
      expect(
        untilNextStoreMidnight(
          'Europe/London',
          now: DateTime.utc(2026, 7, 17, 22, 15),
        ),
        const Duration(minutes: 45),
      );
    });

    test('falls back to device-local midnight for an empty/unknown zone', () {
      final now = DateTime(2026, 7, 17, 21, 30); // local
      const expected = Duration(hours: 2, minutes: 30);
      expect(untilNextStoreMidnight('', now: now), expected);
      expect(untilNextStoreMidnight('Not/AZone', now: now), expected);
    });
  });
}
