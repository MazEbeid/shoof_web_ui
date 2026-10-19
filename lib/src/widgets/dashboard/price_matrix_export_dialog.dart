import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'export_button.dart';
import 'price_filter_controls.dart';
import '../admin_action_buttons.dart';
import '../admin_date_range_picker.dart';
import '../admin_dialog.dart';
import '../../data/cities_constants.dart';
import '../../data/price_matrix_export.dart';
import '../../data/supabase_client_provider.dart';
import '../../data/widget_data_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_typography.dart';

/// Opens the "Export Price Matrix" dialog for the Price Monitor widget.
/// [filters] are the widget's live filters; the dialog's period replaces
/// their date range.
Future<void> showPriceMatrixExportDialog(
  BuildContext context, {
  required WidgetFilterParams filters,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => PriceMatrixExportDialog(filters: filters),
  );
}

class PriceMatrixExportDialog extends ConsumerStatefulWidget {
  final WidgetFilterParams filters;

  const PriceMatrixExportDialog({super.key, required this.filters});

  @override
  ConsumerState<PriceMatrixExportDialog> createState() =>
      _PriceMatrixExportDialogState();
}

class _PriceMatrixExportDialogState
    extends ConsumerState<PriceMatrixExportDialog> {
  var _kind = ExportPeriodKind.thisMonth;
  var _months = 3;
  DateTimeRange? _custom;
  bool _busy = false;
  int _visitsFetched = 0;
  String? _error;

  DateTimeRange? get _range =>
      resolveExportPeriod(_kind, months: _months, custom: _custom);

  Future<void> _export() async {
    final range = _range;
    if (range == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _visitsFetched = 0;
      _error = null;
    });

    try {
      final filters = widget.filters;
      List<String>? regionCities;
      if (filters.region != null) {
        final cities = await ref
            .read(missionCitiesProvider(filters.missionId).future);
        regionCities = citiesForRegion(filters.region!, cities);
      }

      final result = await buildPriceMatrixExport(
        ref.read(sharedSupabaseProvider),
        filters: filters,
        range: range,
        regionCities: regionCities,
        onProgress: (visits) {
          if (mounted) setState(() => _visitsFetched = visits);
        },
      );

      if (result.rowCount == 0) {
        if (mounted) {
          setState(() {
            _busy = false;
            _error = 'No data to export for this period';
          });
        }
        return;
      }

      downloadCsvContent(
        'price_matrix_${_fileDate(range.start)}_${_fileDate(range.end)}',
        result.csv,
      );
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text('Exported ${_thousands(result.rowCount)} rows '
            '(${_thousands(result.visitCount)} visits)'),
      ));
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Export failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = _range;

    return PopScope(
      canPop: !_busy,
      child: AdminDialog(
        title: 'Export Price Matrix',
        subtitle: 'Every visit x SKU with availability and price (CSV)',
        titleIcon: Icons.table_view,
        width: 560,
        showCloseButton: !_busy,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Period',
                style: AdminTextStyles.labelSmall
                    .copyWith(color: AdminColors.textMuted)),
            const SizedBox(height: AdminSpacing.sm),
            Wrap(
              spacing: AdminSpacing.sm,
              runSpacing: AdminSpacing.sm,
              children: ExportPeriodKind.values.map((kind) {
                return ChoiceChip(
                  label: Text(kind.label),
                  selected: kind == _kind,
                  onSelected: _busy
                      ? null
                      : (_) => setState(() {
                            _kind = kind;
                            _error = null;
                          }),
                );
              }).toList(),
            ),
            if (_kind == ExportPeriodKind.lastNMonths) ...[
              const SizedBox(height: AdminSpacing.md),
              SizedBox(
                width: 200,
                child: PriceSimpleDropdown<int>(
                  label: 'Months',
                  value: _months,
                  hint: 'Months',
                  items: kExportMonthOptions,
                  itemLabel: (n) => 'Last $n months',
                  onChanged: (n) {
                    if (!_busy) setState(() => _months = n);
                  },
                ),
              ),
            ],
            if (_kind == ExportPeriodKind.custom) ...[
              const SizedBox(height: AdminSpacing.md),
              AdminDateRangePicker(
                startDate: _custom?.start,
                endDate: _custom?.end,
                placeholder: 'Select date range',
                onChanged: (r) => setState(() {
                  _custom = r;
                  _error = null;
                }),
              ),
            ],
            const SizedBox(height: AdminSpacing.lg),
            _SummaryRow(
              icon: Icons.date_range,
              text: range == null
                  ? 'Pick a date range'
                  : _formatRange(range),
            ),
            const SizedBox(height: AdminSpacing.xs),
            _SummaryRow(
              icon: Icons.filter_alt_outlined,
              text: _filtersSummary(widget.filters),
            ),
            if (_busy) ...[
              const SizedBox(height: AdminSpacing.md),
              const LinearProgressIndicator(minHeight: 3),
              const SizedBox(height: AdminSpacing.xs),
              Text(
                'Fetched ${_thousands(_visitsFetched)} visits…',
                style: AdminTextStyles.bodySmall
                    .copyWith(color: AdminColors.textMuted),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AdminSpacing.md),
              Text(
                _error!,
                style:
                    AdminTextStyles.bodySmall.copyWith(color: AdminColors.error),
              ),
            ],
          ],
        ),
        actions: [
          AdminSecondaryButton(
            label: 'Cancel',
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
          ),
          AdminPrimaryButton(
            label: 'Export',
            icon: Icons.download,
            isLoading: _busy,
            onPressed: range == null || _busy ? null : _export,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SummaryRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AdminColors.textMuted),
        const SizedBox(width: AdminSpacing.sm),
        Expanded(
          child: Text(text,
              style: AdminTextStyles.bodySmall
                  .copyWith(color: AdminColors.textSecondary)),
        ),
      ],
    );
  }
}

String _filtersSummary(WidgetFilterParams f) {
  final parts = <String>[
    if (f.region != null) 'Region: ${f.region}',
    if (f.city != null) 'City: ${f.city}',
    if (f.channel != null) 'Channel: ${f.channel}',
    if (f.company != null) 'Company: ${f.company}',
    if (f.brand != null) 'Brand: ${f.brand}',
    if (f.package != null) 'Package: ${f.package}',
    if (f.size != null) 'Size: ${f.size}',
  ];
  return parts.isEmpty
      ? 'All regions, channels and SKUs'
      : 'Widget filters applied — ${parts.join(' · ')}';
}

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDay(DateTime d) => '${d.day} ${_monthNames[d.month - 1]} ${d.year}';

String _formatRange(DateTimeRange r) =>
    '${_formatDay(r.start)} – ${_formatDay(r.end)}';

String _fileDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String _thousands(int n) => n.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
