import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';
import 'package:shoof_web_ui/src/data/price_matrix_export.dart';

void main() {
  final oct19 = DateTime(2026, 10, 19, 15, 30);

  DateTimeRange resolve(ExportPeriodKind kind,
          {int months = 3, DateTimeRange? custom, DateTime? now}) =>
      resolveExportPeriod(kind,
          months: months, custom: custom, now: now ?? oct19)!;

  group('resolveExportPeriod', () {
    test('this month = the 1st through today', () {
      final r = resolve(ExportPeriodKind.thisMonth);
      expect(r.start, DateTime(2026, 10, 1));
      expect(r.end, DateTime(2026, 10, 19));
    });

    test('last month = full previous month', () {
      final r = resolve(ExportPeriodKind.lastMonth);
      expect(r.start, DateTime(2026, 9, 1));
      expect(r.end, DateTime(2026, 9, 30));
    });

    test('last 3 months = 3 full past months', () {
      final r = resolve(ExportPeriodKind.lastNMonths);
      expect(r.start, DateTime(2026, 7, 1));
      expect(r.end, DateTime(2026, 9, 30));
    });

    test('last N months crosses the year boundary', () {
      final jan = DateTime(2027, 1, 5);
      final last = resolve(ExportPeriodKind.lastMonth, now: jan);
      expect(last.start, DateTime(2026, 12, 1));
      expect(last.end, DateTime(2026, 12, 31));

      final r = resolve(ExportPeriodKind.lastNMonths, months: 12, now: jan);
      expect(r.start, DateTime(2026, 1, 1));
      expect(r.end, DateTime(2026, 12, 31));
    });

    test('last month handles leap February', () {
      final r = resolve(ExportPeriodKind.lastMonth, now: DateTime(2028, 3, 2));
      expect(r.end, DateTime(2028, 2, 29));
    });

    test('custom passes through (time stripped); null when unpicked', () {
      final r = resolve(ExportPeriodKind.custom,
          custom: DateTimeRange(
              start: DateTime(2026, 8, 3, 10), end: DateTime(2026, 8, 20, 23)));
      expect(r.start, DateTime(2026, 8, 3));
      expect(r.end, DateTime(2026, 8, 20));
      expect(resolveExportPeriod(ExportPeriodKind.custom, now: oct19), isNull);
    });
  });
}
