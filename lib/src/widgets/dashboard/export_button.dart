import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';

import '../../data/csv_format.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_radius.dart';

export '../../data/csv_format.dart' show csvLine;

/// Header + rows for a CSV export.
class CsvExportData {
  final List<String> header;
  final List<List<Object?>> rows;

  const CsvExportData({required this.header, required this.rows});
}

/// Builds a CSV and triggers a browser download.
///
/// The file starts with a UTF-8 BOM so Excel detects the encoding — without
/// it Arabic SKU/city names open garbled. Filename: `<baseName>_YYYY-MM-DD.csv`.
void downloadCsv(String baseName, CsvExportData data) {
  final buffer = StringBuffer();
  buffer.writeln(csvLine(data.header));
  for (final row in data.rows) {
    buffer.writeln(csvLine(row));
  }
  downloadCsvContent(baseName, buffer.toString());
}

/// Downloads already-built CSV text (built with [csvLine]) — for exports too
/// large to hold as a [CsvExportData]. Adds the BOM; same filename scheme.
void downloadCsvContent(String baseName, String csv) {
  final bytes = utf8.encode('\uFEFF$csv');
  final blob = html.Blob([bytes], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final date = DateTime.now().toIso8601String().split('T')[0];
  html.AnchorElement(href: url)
    ..setAttribute('download', '${baseName}_$date.csv')
    ..click();
  html.Url.revokeObjectUrl(url);
}

/// Opens [url] in a new browser tab (maps links, photos, recordings).
void openUrl(String url) => html.window.open(url, '_blank');

/// The standard dashboard-widget export control (user-decided, 2026-07-07):
/// every rich widget exposes the SAME "Export" button which downloads the
/// widget's current (filter-respecting) data as an Excel-friendly CSV.
class ExportButton extends StatelessWidget {
  final String baseName;

  /// Builds the data to export; return null or empty rows for "no data".
  final Future<CsvExportData?> Function() buildData;

  const ExportButton({
    super.key,
    required this.baseName,
    required this.buildData,
  });

  Future<void> _export(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Preparing export...')),
    );

    try {
      final data = await buildData();
      if (data == null || data.rows.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No data to export')),
        );
        return;
      }
      downloadCsv(baseName, data);
      messenger.showSnackBar(
        SnackBar(content: Text('Exported ${data.rows.length} rows')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _export(context),
      icon: Icon(Icons.download, size: 18, color: AdminColors.primary),
      label: Text(
        'Export',
        style: TextStyle(color: AdminColors.primary),
      ),
      style: exportButtonStyle(),
    );
  }
}

/// The tinted look of [ExportButton], for sibling export controls.
ButtonStyle exportButtonStyle() => TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      backgroundColor: AdminColors.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: AdminRadius.smAll),
    );
