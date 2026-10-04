import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'export_button.dart';
import 'sku_filter_bar.dart';
import '../../data/raw_visits_provider.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';

/// Raw Data — every accepted visit of the mission (user-designed, 2026-07-08).
///
/// One row per visit: date, location (+ Google Maps link), city/channel/
/// district, the per-SKU availability/price matrix (expand the row), photo
/// thumbnails with a full-screen gallery, and the session recording where
/// available (opens in a new tab). Server-side pagination; the export
/// downloads the FILTERED subset as a wide prices-matrix CSV with explicit
/// `<SKU> Available` + `<SKU> Price` columns. Serves admin AND insights
/// (RLS scopes clients); the crowd column shows only when [showCrowd].
class RawDataWidget extends HookConsumerWidget {
  final String missionId;
  final String title;
  final String? subtitle;
  final bool showCrowd;

  const RawDataWidget({
    super.key,
    required this.missionId,
    this.title = 'Raw Data',
    this.subtitle,
    this.showCrowd = false,
  });

  static const int _pageSize = 25;
  static const int _exportPageSize = 1000;
  static const int _exportMaxRows = 50000;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = useSkuFilters();
    final availability = useState<bool?>(null);
    final priceMin = useState<double?>(null);
    final priceMax = useState<double?>(null);
    final page = useState(0);
    final expanded = useState<Set<String>>({});

    final filterParams = filters.params(missionId);

    // Any filter change starts back at page 1.
    final filterSig = Object.hash(
        filterParams, availability.value, priceMin.value, priceMax.value);
    useEffect(() {
      page.value = 0;
      expanded.value = {};
      return null;
    }, [filterSig]);

    RawVisitsParams paramsFor({required int limit, required int offset}) =>
        RawVisitsParams(
          filters: filterParams,
          available: availability.value,
          priceMin: priceMin.value,
          priceMax: priceMax.value,
          limit: limit,
          offset: offset,
        );

    final rowsAsync = ref.watch(rawVisitsProvider(
        paramsFor(limit: _pageSize, offset: page.value * _pageSize)));
    final totalCount = rowsAsync.valueOrNull?.isNotEmpty == true
        ? rowsAsync.valueOrNull!.first.totalCount
        : null;

    Future<List<RawVisitRow>> fetchAllFiltered() async {
      final all = <RawVisitRow>[];
      for (var offset = 0; offset < _exportMaxRows; offset += _exportPageSize) {
        final chunk = await ref.read(rawVisitsProvider(
                paramsFor(limit: _exportPageSize, offset: offset))
            .future);
        all.addAll(chunk);
        if (chunk.length < _exportPageSize) break;
      }
      return all;
    }

    return Container(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: AdminRadius.lgAll,
        border: Border.all(color: AdminColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.table_rows_outlined,
                  color: AdminColors.primary, size: 24),
              const SizedBox(width: AdminSpacing.sm),
              Text(title, style: AdminTextStyles.sectionTitle),
              const Spacer(),
              ExportButton(
                baseName: 'raw_data',
                buildData: () async =>
                    _buildMatrixCsv(await fetchAllFiltered(), showCrowd),
              ),
              const SizedBox(width: AdminSpacing.sm),
              if (totalCount != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withValues(alpha: 0.1),
                    borderRadius: AdminRadius.smAll,
                  ),
                  child: Text(
                    '$totalCount visits',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AdminColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AdminSpacing.sm),
          Text(
            subtitle?.isNotEmpty == true
                ? subtitle!
                : 'Every accepted visit — expand a row for the per-SKU '
                    'matrix; export downloads the filtered subset',
            style: AdminTextStyles.bodySmall.copyWith(
              color: AdminColors.textMuted,
            ),
          ),
          const SizedBox(height: AdminSpacing.md),

          SkuFilterBar(missionId: missionId, filters: filters),
          const SizedBox(height: AdminSpacing.sm),
          _RawDataFilters(
            availability: availability,
            priceMin: priceMin,
            priceMax: priceMax,
          ),
          const SizedBox(height: AdminSpacing.md),

          rowsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Could not load visits',
                  style: AdminTextStyles.bodySmall.copyWith(
                    color: AdminColors.textMuted,
                  ),
                ),
              ),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No visits match these filters',
                      style: AdminTextStyles.bodySmall.copyWith(
                        color: AdminColors.textMuted,
                      ),
                    ),
                  ),
                );
              }
              final total = rows.first.totalCount;
              final from = page.value * _pageSize + 1;
              final to = page.value * _pageSize + rows.length;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeaderRow(showCrowd: showCrowd),
                  ...rows.map((r) => _VisitRow(
                        row: r,
                        showCrowd: showCrowd,
                        expanded: expanded.value.contains(r.submissionId),
                        onToggle: () {
                          final next = {...expanded.value};
                          if (!next.remove(r.submissionId)) {
                            next.add(r.submissionId);
                          }
                          expanded.value = next;
                        },
                      )),
                  const SizedBox(height: AdminSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: page.value > 0
                            ? () => page.value = page.value - 1
                            : null,
                        icon: const Icon(Icons.chevron_left, size: 20),
                        tooltip: 'Previous page',
                      ),
                      Text(
                        'Showing $from–$to of $total',
                        style: AdminTextStyles.bodySmall.copyWith(
                          color: AdminColors.textSecondary,
                        ),
                      ),
                      IconButton(
                        onPressed: to < total
                            ? () => page.value = page.value + 1
                            : null,
                        icon: const Icon(Icons.chevron_right, size: 20),
                        tooltip: 'Next page',
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Availability / price-range filters specific to Raw Data.
class _RawDataFilters extends StatelessWidget {
  final ValueNotifier<bool?> availability;
  final ValueNotifier<double?> priceMin;
  final ValueNotifier<double?> priceMax;

  const _RawDataFilters({
    required this.availability,
    required this.priceMin,
    required this.priceMax,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AdminSpacing.sm,
      runSpacing: AdminSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'SKU filters:',
          style: AdminTextStyles.labelSmall.copyWith(
            color: AdminColors.textMuted,
          ),
        ),
        SizedBox(
          width: 170,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<bool?>(
              value: availability.value,
              isDense: true,
              isExpanded: true,
              hint: Text('Availability: any',
                  style: AdminTextStyles.bodySmall
                      .copyWith(color: AdminColors.textMuted)),
              dropdownColor: AdminColors.surface,
              style: AdminTextStyles.bodySmall
                  .copyWith(color: AdminColors.textPrimary),
              items: const [
                DropdownMenuItem<bool?>(
                    value: null, child: Text('Availability: any')),
                DropdownMenuItem<bool?>(value: true, child: Text('Available')),
                DropdownMenuItem<bool?>(
                    value: false, child: Text('Unavailable')),
              ],
              onChanged: (v) => availability.value = v,
            ),
          ),
        ),
        _PriceField(label: 'Min price', notifier: priceMin),
        _PriceField(label: 'Max price', notifier: priceMax),
        if (availability.value != null ||
            priceMin.value != null ||
            priceMax.value != null)
          TextButton(
            onPressed: () {
              availability.value = null;
              priceMin.value = null;
              priceMax.value = null;
            },
            child: const Text('Clear'),
          ),
      ],
    );
  }
}

class _PriceField extends StatelessWidget {
  final String label;
  final ValueNotifier<double?> notifier;

  const _PriceField({required this.label, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: TextFormField(
        initialValue: notifier.value?.toString() ?? '',
        keyboardType: TextInputType.number,
        style: AdminTextStyles.bodySmall,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AdminTextStyles.labelSmall
              .copyWith(color: AdminColors.textMuted),
          isDense: true,
          border: OutlineInputBorder(borderRadius: AdminRadius.smAll),
        ),
        onFieldSubmitted: (v) =>
            notifier.value = double.tryParse(v.trim()),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final bool showCrowd;

  const _HeaderRow({required this.showCrowd});

  @override
  Widget build(BuildContext context) {
    final style = AdminTextStyles.labelSmall.copyWith(
      fontWeight: FontWeight.w600,
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: AdminColors.backgroundPage,
      child: Row(
        children: [
          SizedBox(width: 84, child: Text('Date', style: style)),
          Expanded(flex: 3, child: Text('Location', style: style)),
          SizedBox(width: 90, child: Text('City', style: style)),
          SizedBox(width: 90, child: Text('Channel', style: style)),
          SizedBox(width: 64, child: Text('SKUs', style: style)),
          SizedBox(width: 96, child: Text('Photos', style: style)),
          SizedBox(width: 44, child: Text('Rec', style: style)),
          if (showCrowd)
            SizedBox(width: 90, child: Text('Crowd', style: style)),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _VisitRow extends StatelessWidget {
  final RawVisitRow row;
  final bool showCrowd;
  final bool expanded;
  final VoidCallback onToggle;

  const _VisitRow({
    required this.row,
    required this.showCrowd,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AdminColors.divider, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 84,
                  child: Text(
                    row.observedDate ?? '—',
                    style: AdminTextStyles.bodySmall,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          row.locationName ?? '—',
                          style: AdminTextStyles.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (row.googleMapsLink != null)
                        IconButton(
                          onPressed: () => openUrl(row.googleMapsLink!),
                          icon: Icon(Icons.place_outlined,
                              size: 16, color: AdminColors.primary),
                          tooltip: 'Open in Google Maps',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 28, minHeight: 28),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(row.city ?? '—',
                      style: AdminTextStyles.bodySmall,
                      overflow: TextOverflow.ellipsis),
                ),
                SizedBox(
                  width: 90,
                  child: Text(row.channel ?? row.placeType ?? '—',
                      style: AdminTextStyles.bodySmall,
                      overflow: TextOverflow.ellipsis),
                ),
                SizedBox(
                  width: 64,
                  child: row.skus.isEmpty
                      ? Text('—',
                          style: AdminTextStyles.bodySmall
                              .copyWith(color: AdminColors.textMuted))
                      : Text(
                          '${row.availableCount}/${row.skus.length}',
                          style: AdminTextStyles.bodySmall
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                ),
                SizedBox(
                  width: 96,
                  child: row.photos.isEmpty
                      ? Text('—',
                          style: AdminTextStyles.bodySmall
                              .copyWith(color: AdminColors.textMuted))
                      : InkWell(
                          onTap: () => _showGallery(context, row.photos, 0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  row.photos.first,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                      Icons.broken_image_outlined,
                                      size: 20,
                                      color: AdminColors.textMuted),
                                ),
                              ),
                              if (row.photos.length > 1) ...[
                                const SizedBox(width: 4),
                                Text('+${row.photos.length - 1}',
                                    style: AdminTextStyles.labelSmall.copyWith(
                                        color: AdminColors.textSecondary)),
                              ],
                            ],
                          ),
                        ),
                ),
                SizedBox(
                  width: 44,
                  child: row.recordingUrl == null
                      ? Text('—',
                          style: AdminTextStyles.bodySmall
                              .copyWith(color: AdminColors.textMuted))
                      : IconButton(
                          onPressed: () => openUrl(row.recordingUrl!),
                          icon: Icon(Icons.headphones_outlined,
                              size: 18, color: AdminColors.primary),
                          tooltip: 'Play recording (new tab)',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 28, minHeight: 28),
                        ),
                ),
                if (showCrowd)
                  SizedBox(
                    width: 90,
                    child: Text(
                      row.crowdId ?? '—',
                      style: AdminTextStyles.labelSmall
                          .copyWith(color: AdminColors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                SizedBox(
                  width: 32,
                  child: Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AdminColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (expanded) _VisitDetail(row: row),
      ],
    );
  }
}

class _VisitDetail extends StatelessWidget {
  final RawVisitRow row;

  const _VisitDetail({required this.row});

  @override
  Widget build(BuildContext context) {
    final labelStyle = AdminTextStyles.labelSmall.copyWith(
      fontWeight: FontWeight.w600,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AdminSpacing.md),
      color: AdminColors.backgroundHover,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (row.districtName != null || row.submissionId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
              child: Text(
                [
                  if (row.districtName != null)
                    'District: ${row.districtName}',
                  'Visit: ${row.submissionId}',
                ].join('   ·   '),
                style: AdminTextStyles.labelSmall
                    .copyWith(color: AdminColors.textMuted),
              ),
            ),
          if (row.skus.isNotEmpty) ...[
            Row(
              children: [
                Expanded(flex: 3, child: Text('SKU', style: labelStyle)),
                SizedBox(width: 110, child: Text('Brand', style: labelStyle)),
                SizedBox(width: 80, child: Text('Package', style: labelStyle)),
                SizedBox(width: 70, child: Text('Size', style: labelStyle)),
                SizedBox(
                    width: 90, child: Text('Available', style: labelStyle)),
                SizedBox(width: 80, child: Text('Price', style: labelStyle)),
              ],
            ),
            const SizedBox(height: 4),
            ...row.skus.map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(s.sku,
                            style: AdminTextStyles.bodySmall,
                            overflow: TextOverflow.ellipsis),
                      ),
                      SizedBox(
                        width: 110,
                        child: Text(s.brand ?? '—',
                            style: AdminTextStyles.bodySmall,
                            overflow: TextOverflow.ellipsis),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(s.package ?? '—',
                            style: AdminTextStyles.bodySmall),
                      ),
                      SizedBox(
                        width: 70,
                        child: Text(s.size ?? '—',
                            style: AdminTextStyles.bodySmall),
                      ),
                      SizedBox(
                        width: 90,
                        child: Text(
                          s.available == null
                              ? '—'
                              : s.available!
                                  ? 'YES'
                                  : 'NO',
                          style: AdminTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: s.available == true
                                ? AdminColors.success
                                : s.available == false
                                    ? AdminColors.error
                                    : AdminColors.textMuted,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          s.price != null
                              ? '${s.price!.toStringAsFixed(2)} EGP'
                              : '—',
                          style: AdminTextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )),
          ] else
            Text(
              'No SKU answers on this visit',
              style: AdminTextStyles.bodySmall
                  .copyWith(color: AdminColors.textMuted),
            ),
          if (row.photos.isNotEmpty) ...[
            const SizedBox(height: AdminSpacing.sm),
            Wrap(
              spacing: AdminSpacing.sm,
              runSpacing: AdminSpacing.sm,
              children: [
                for (var i = 0; i < row.photos.length; i++)
                  InkWell(
                    onTap: () => _showGallery(context, row.photos, i),
                    child: ClipRRect(
                      borderRadius: AdminRadius.smAll,
                      child: Image.network(
                        row.photos[i],
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 72,
                          height: 72,
                          color: AdminColors.backgroundPage,
                          child: Icon(Icons.broken_image_outlined,
                              color: AdminColors.textMuted),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

void _showGallery(BuildContext context, List<String> photos, int initial) {
  showDialog(
    context: context,
    builder: (_) => _PhotoGalleryDialog(photos: photos, initialIndex: initial),
  );
}

/// Full-screen photo viewer with zoom + prev/next (local mirror of the
/// admin QA lightbox — shared package can't import ShooofAdmin widgets).
class _PhotoGalleryDialog extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const _PhotoGalleryDialog({required this.photos, required this.initialIndex});

  @override
  State<_PhotoGalleryDialog> createState() => _PhotoGalleryDialogState();
}

class _PhotoGalleryDialogState extends State<_PhotoGalleryDialog> {
  late int index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black87,
      insetPadding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Image.network(
                widget.photos[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const SizedBox(
                        width: 200,
                        height: 200,
                        child: Center(
                            child:
                                CircularProgressIndicator(strokeWidth: 2)),
                      ),
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(48),
                  child: Icon(Icons.broken_image_outlined,
                      color: Colors.white54, size: 48),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => openUrl(widget.photos[index]),
                  icon: const Icon(Icons.open_in_new, color: Colors.white70),
                  tooltip: 'Open original',
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          if (widget.photos.length > 1) ...[
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: index > 0 ? () => setState(() => index--) : null,
                  icon:
                      const Icon(Icons.chevron_left, color: Colors.white70),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: index < widget.photos.length - 1
                      ? () => setState(() => index++)
                      : null,
                  icon:
                      const Icon(Icons.chevron_right, color: Colors.white70),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '${index + 1} / ${widget.photos.length}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Wide prices-matrix export: visit columns then, per SKU (union across the
/// exported rows), explicit `<SKU> Available` (YES/NO) + `<SKU> Price`.
CsvExportData _buildMatrixCsv(List<RawVisitRow> rows, bool showCrowd) {
  final skuNames = <String>{};
  for (final r in rows) {
    for (final s in r.skus) {
      skuNames.add(s.sku);
    }
  }
  final orderedSkus = skuNames.toList()..sort();

  final header = <String>[
    'Date', 'Submission ID', 'Location', 'City', 'District', 'Channel',
    'Maps Link', 'Photos', 'Recording',
    if (showCrowd) 'Crowd',
    for (final sku in orderedSkus) ...['$sku Available', '$sku Price'],
  ];

  final dataRows = rows.map((r) {
    final bySku = {for (final s in r.skus) s.sku: s};
    return <Object?>[
      r.observedDate,
      r.submissionId,
      r.locationName,
      r.city,
      r.districtName,
      r.channel ?? r.placeType,
      r.googleMapsLink,
      r.photos.join(' | '),
      r.recordingUrl,
      if (showCrowd) r.crowdId,
      for (final sku in orderedSkus) ...[
        bySku[sku] == null
            ? ''
            : bySku[sku]!.available == true
                ? 'YES'
                : bySku[sku]!.available == false
                    ? 'NO'
                    : '',
        bySku[sku]?.price?.toStringAsFixed(2),
      ],
    ];
  }).toList();

  return CsvExportData(header: header, rows: dataRows);
}
