import 'package:flutter/material.dart' show DateTimeRange;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'csv_format.dart';
import 'cities_constants.dart';
import 'widget_data_providers.dart';

// =============================================================================
// Price Matrix export (2026-10-19) — the Price Monitor's "Export Price Matrix":
// one CSV row per visit x SKU for a chosen period, streamed page by page from
// fn_price_matrix_export (one row per visit + its SKUs as jsonb).
// =============================================================================

/// Period choices of the export dialog (user-decided, 2026-10-19).
enum ExportPeriodKind {
  thisMonth('This month'),
  lastMonth('Last month'),
  lastNMonths('Last N months'),
  custom('Custom range');

  final String label;
  const ExportPeriodKind(this.label);
}

/// Month counts offered for [ExportPeriodKind.lastNMonths].
const List<int> kExportMonthOptions = [2, 3, 4, 6, 9, 12];

/// Resolves a period to inclusive calendar dates (midnight, no time part).
///
/// - This month: the 1st through today.
/// - Last month: the full previous calendar month.
/// - Last N months: the N full months before the current one (on Oct 19,
///   N = 3 is Jul 1 - Sep 30); the partial current month is "This month".
/// - Custom: [custom] as given (null when nothing was picked yet).
DateTimeRange? resolveExportPeriod(
  ExportPeriodKind kind, {
  int months = 3,
  DateTimeRange? custom,
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final monthStart = DateTime(n.year, n.month, 1);
  final lastMonthEnd = DateTime(n.year, n.month, 0);
  return switch (kind) {
    ExportPeriodKind.thisMonth => DateTimeRange(start: monthStart, end: today),
    ExportPeriodKind.lastMonth => DateTimeRange(
        start: DateTime(n.year, n.month - 1, 1), end: lastMonthEnd),
    ExportPeriodKind.lastNMonths => DateTimeRange(
        start: DateTime(n.year, n.month - months, 1), end: lastMonthEnd),
    ExportPeriodKind.custom => custom == null
        ? null
        : DateTimeRange(
            start: DateTime(
                custom.start.year, custom.start.month, custom.start.day),
            end: DateTime(custom.end.year, custom.end.month, custom.end.day),
          ),
  };
}

/// CSV header, in the order the client asked for.
const List<String> kPriceMatrixHeader = [
  'Region', 'City', 'Location name', 'Location type', 'Map link',
  'Timestamp', 'Company', 'Brand', 'English SKU', 'Arabic SKU', 'Size',
  'Package', 'Available', 'Price', 'Date',
];

/// Excel stops at 1,048,576 rows; past this the file would be cut off.
const int kPriceMatrixMaxRows = 1000000;

const int _visitsPerPage = 250;

/// A built export: CSV body (header included, no BOM) + counts.
class PriceMatrixExport {
  final String csv;
  final int rowCount;
  final int visitCount;

  const PriceMatrixExport({
    required this.csv,
    required this.rowCount,
    required this.visitCount,
  });
}

/// Fetches every visit of [filters.missionId] in [range] and builds the CSV.
///
/// Honors the widget's region (as [regionCities]), city, channel, company,
/// brand, package and size filters; [range] replaces its date filter.
/// [onProgress] gets the running visit count after each page.
Future<PriceMatrixExport> buildPriceMatrixExport(
  SupabaseClient supabase, {
  required WidgetFilterParams filters,
  required DateTimeRange range,
  List<String>? regionCities,
  void Function(int visits)? onProgress,
}) async {
  final buffer = StringBuffer()..writeln(csvLine(kPriceMatrixHeader));
  var rows = 0;
  var visits = 0;

  for (var offset = 0;; offset += _visitsPerPage) {
    final page = await supabase.rpc('fn_price_matrix_export', params: {
      'p_mission_id': filters.missionId,
      'p_city': filters.city,
      'p_cities': regionCities,
      'p_channel': filters.channel,
      'p_company': filters.company,
      'p_brand': filters.brand,
      'p_package': filters.package,
      'p_size': filters.size,
      'p_start_date': _isoDate(range.start),
      'p_end_date': _isoDate(range.end),
      'p_limit': _visitsPerPage,
      'p_offset': offset,
    }) as List<dynamic>;

    for (final visit in page.cast<Map<String, dynamic>>()) {
      final skus = (visit['skus'] as List<dynamic>?) ?? const [];
      if (skus.isEmpty) continue;
      visits++;
      final city = visit['city'] as String?;
      final lat = (visit['lat'] as num?)?.toDouble();
      final lng = (visit['lng'] as num?)?.toDouble();
      final visitCells = <Object?>[
        regionForCity(city),
        city,
        visit['location_name'],
        visit['place_type'] ?? visit['channel'],
        lat != null && lng != null
            ? 'https://www.google.com/maps?q=$lat,$lng'
            : null,
        _formatTimestamp(visit['observed_at'] as String?),
      ];
      for (final sku in skus.cast<Map<String, dynamic>>()) {
        final available = sku['available'] as bool?;
        final price = (sku['price'] as num?)?.toDouble();
        buffer.writeln(csvLine([
          ...visitCells,
          sku['company'],
          sku['brand'],
          sku['sku'],
          sku['sku_ar'],
          sku['size'],
          sku['package'],
          available == null ? null : (available ? 'Yes' : 'No'),
          price?.toStringAsFixed(2),
          visit['observed_date'],
        ]));
        rows++;
      }
    }

    if (rows > kPriceMatrixMaxRows) {
      throw StateError(
          'More than 1,000,000 rows (Excel\'s limit) — choose a shorter period');
    }
    onProgress?.call(visits);
    if (page.length < _visitsPerPage) break;
  }

  return PriceMatrixExport(
    csv: buffer.toString(),
    rowCount: rows,
    visitCount: visits,
  );
}

String _isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${_two(d.month)}-${_two(d.day)}';

/// Browser-local `YYYY-MM-DD HH:mm` (Cairo for the client team).
String? _formatTimestamp(String? iso) {
  final t = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
  if (t == null) return null;
  return '${_isoDate(t)} ${_two(t.hour)}:${_two(t.minute)}';
}

String _two(int v) => v.toString().padLeft(2, '0');
