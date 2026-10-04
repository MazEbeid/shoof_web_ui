import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'export_button.dart';
import 'price_vs_anchor_widget.dart' show showAnchorEditorDialog;
import 'sku_filter_bar.dart';
import '../../data/anchor_prices_provider.dart';
import '../../data/price_monitor_provider.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';

/// Price Monitor — the analyst's price table (user-designed, 2026-07-07).
///
/// One row per SKU: modal latest-week price (the actual "street price"),
/// Δ vs the trailing 4-week average, min–max spread, weekly sparkline and
/// anchor compliance (at/above/below %, when the client set an anchor).
/// Replaces the Price Range and Price Movers widgets. Window defaults to
/// the last 8 weeks unless a date filter is set.
class PriceMonitorWidget extends HookConsumerWidget {
  final String missionId;
  final String? clientId;
  final String title;
  final String? subtitle;

  /// Admins can open the anchor-price editor from here (requires clientId).
  final bool canEditAnchors;

  const PriceMonitorWidget({
    super.key,
    required this.missionId,
    this.clientId,
    this.title = 'Price Monitor',
    this.subtitle,
    this.canEditAnchors = false,
  });

  static const int _previewRowCount = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showAll = useState(false);
    final filters = useSkuFilters();
    final filterParams = filters.params(missionId);

    final rowsAsync = ref.watch(priceMonitorProvider(filterParams));
    final anchors = clientId == null
        ? const <String, double>{}
        : ref
                .watch(anchorPricesProvider(AnchorPricesParams(
                  clientId: clientId!,
                  missionId: missionId,
                )))
                .value
                ?.prices ??
            const <String, double>{};

    final hasAnyAnchor = anchors.isNotEmpty;

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
              Icon(Icons.query_stats, color: AdminColors.primary, size: 24),
              const SizedBox(width: AdminSpacing.sm),
              Text(title, style: AdminTextStyles.sectionTitle),
              const Spacer(),
              if (canEditAnchors && clientId != null) ...[
                TextButton.icon(
                  onPressed: () => showAnchorEditorDialog(context, ref,
                      missionId: missionId, clientId: clientId!),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Anchors'),
                ),
                const SizedBox(width: AdminSpacing.sm),
              ],
              ExportButton(
                baseName: 'price_monitor',
                buildData: () async {
                  final rows =
                      await ref.read(priceMonitorProvider(filterParams).future);
                  return CsvExportData(
                    header: const [
                      'SKU', 'Brand', 'Company', 'Size', 'Package',
                      'Latest Price (Mode)', 'Latest Avg', 'Prev 4-wk Avg',
                      'Change %', 'Min', 'Max', 'Anchor',
                      'At Anchor %', 'Above %', 'Below %',
                      'Obs (week)', 'Obs (total)',
                    ],
                    rows: rows.map((r) {
                      final c = _compliance(r, anchors[_anchorKey(r)]);
                      return <Object?>[
                        r.sku, r.brand, r.company, r.size, r.packaging,
                        r.latestMode?.toStringAsFixed(2),
                        r.latestAvg?.toStringAsFixed(2),
                        r.trailingAvg?.toStringAsFixed(2),
                        r.changePercent?.toStringAsFixed(1),
                        r.minPrice?.toStringAsFixed(2),
                        r.maxPrice?.toStringAsFixed(2),
                        anchors[_anchorKey(r)]?.toStringAsFixed(2),
                        c?.atPct.toStringAsFixed(0),
                        c?.abovePct.toStringAsFixed(0),
                        c?.belowPct.toStringAsFixed(0),
                        r.latestObs, r.totalObs,
                      ];
                    }).toList(),
                  );
                },
              ),
              const SizedBox(width: AdminSpacing.sm),
              rowsAsync.when(
                data: (rows) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withValues(alpha: 0.1),
                    borderRadius: AdminRadius.smAll,
                  ),
                  child: Text(
                    '${rows.length} SKUs',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AdminColors.primary,
                    ),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.sm),
          Text(
            subtitle?.isNotEmpty == true
                ? subtitle!
                : 'Street price this week (most common observed price) vs the '
                    '4-week average — last 8 weeks unless a date filter is set',
            style: AdminTextStyles.bodySmall.copyWith(
              color: AdminColors.textMuted,
            ),
          ),
          const SizedBox(height: AdminSpacing.md),

          SkuFilterBar(
            missionId: missionId,
            filters: filters,
            regionInsteadOfCity: true,
            dateRangePlaceholder: 'Last 8 weeks',
          ),
          if (hasAnyAnchor) ...[
            const SizedBox(height: AdminSpacing.sm),
            Wrap(
              spacing: AdminSpacing.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('vs Anchor:',
                    style: AdminTextStyles.labelSmall
                        .copyWith(color: AdminColors.textMuted)),
                _LegendDot(color: AdminColors.info, label: 'below anchor'),
                _LegendDot(color: AdminColors.success, label: 'at anchor'),
                _LegendDot(color: AdminColors.warning, label: 'above anchor'),
              ],
            ),
          ],
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
                  'Could not load price data',
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
                      'No price observations in this window',
                      style: AdminTextStyles.bodySmall.copyWith(
                        color: AdminColors.textMuted,
                      ),
                    ),
                  ),
                );
              }
              final visible =
                  showAll.value ? rows : rows.take(_previewRowCount).toList();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(),
                  ...visible.map((r) => _Row(
                        row: r,
                        anchor: anchors[_anchorKey(r)],
                      )),
                  if (rows.length > _previewRowCount)
                    Align(
                      alignment: Alignment.center,
                      child: TextButton.icon(
                        onPressed: () => showAll.value = !showAll.value,
                        icon: Icon(
                          showAll.value
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 18,
                        ),
                        label: Text(
                          showAll.value
                              ? 'Show top $_previewRowCount'
                              : 'Show all ${rows.length} rows',
                        ),
                      ),
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

/// Anchor prices are keyed 'name|size|packaging' (see priceSkuLabel).
String _anchorKey(PriceMonitorRow r) =>
    '${r.sku}|${r.size ?? ''}|${r.packaging ?? ''}';

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: AdminTextStyles.labelSmall
                .copyWith(color: AdminColors.textSecondary)),
      ],
    );
  }
}

class _ComplianceSplit {
  final int at;
  final int above;
  final int below;

  const _ComplianceSplit(this.at, this.above, this.below);

  int get total => at + above + below;
  double get atPct => total == 0 ? 0 : at / total * 100;
  double get abovePct => total == 0 ? 0 : above / total * 100;
  double get belowPct => total == 0 ? 0 : below / total * 100;
}

_ComplianceSplit? _compliance(PriceMonitorRow row, double? anchor) {
  if (anchor == null || row.latestPrices.isEmpty) return null;
  var at = 0, above = 0, below = 0;
  row.latestPrices.forEach((price, count) {
    if ((price - anchor).abs() < 0.005) {
      at += count;
    } else if (price > anchor) {
      above += count;
    } else {
      below += count;
    }
  });
  return _ComplianceSplit(at, above, below);
}

class _Header extends StatelessWidget {
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
          Expanded(flex: 3, child: Text('SKU', style: style)),
          SizedBox(
            width: 90,
            child: Tooltip(
              message: 'Most common shelf price observed in the latest week '
                  '(the "street price"); the small number is the week average',
              child: Text('Latest', style: style),
            ),
          ),
          SizedBox(
            width: 80,
            child: Tooltip(
              message: 'Latest week average vs the average of the previous '
                  '4 weeks',
              child: Text('Δ vs 4-wk', style: style),
            ),
          ),
          SizedBox(
            width: 90,
            child: Tooltip(
              message: 'Cheapest and most expensive price observed in the '
                  'window (entries under 5 EGP are treated as typos and '
                  'excluded)',
              child: Text('Min – Max', style: style),
            ),
          ),
          SizedBox(
            width: 86,
            child: Tooltip(
              message: 'Weekly average price across the window',
              child: Text('Trend', style: style),
            ),
          ),
          SizedBox(
            width: 96,
            child: Tooltip(
              message: 'Share of this week\'s observations below / at / '
                  'above the anchor price ("—" when no anchor is set)',
              child: Text('vs Anchor', style: style),
            ),
          ),
          SizedBox(
            width: 64,
            child: Tooltip(
              message: 'Price observations: latest week / whole window',
              child: Text('Obs', textAlign: TextAlign.right, style: style),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final PriceMonitorRow row;
  final double? anchor;

  const _Row({required this.row, required this.anchor});

  @override
  Widget build(BuildContext context) {
    final change = row.changePercent;
    final stable = change != null && change.abs() < 0.5;
    final changeColor = change == null || stable
        ? AdminColors.textMuted
        : change > 0
            ? AdminColors.warning
            : AdminColors.info;
    final compliance = _compliance(row, anchor);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.sku,
                  style: AdminTextStyles.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
                if (row.brand != null)
                  Text(
                    '${row.brand}${row.company != null ? ' · ${row.company}' : ''}',
                    style: AdminTextStyles.labelSmall.copyWith(
                      color: AdminColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.latestMode != null
                      ? '${_trimZeros(row.latestMode!)} EGP'
                      : '—',
                  style: AdminTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (row.latestAvg != null)
                  Text(
                    'avg ${row.latestAvg!.toStringAsFixed(2)}',
                    style: AdminTextStyles.labelSmall.copyWith(
                      color: AdminColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: change == null
                ? Text('—',
                    style: AdminTextStyles.bodySmall.copyWith(
                      color: AdminColors.textMuted,
                    ))
                : Row(
                    children: [
                      Icon(
                        stable
                            ? Icons.remove
                            : change > 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                        size: 14,
                        color: changeColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        stable
                            ? 'stable'
                            : '${change.abs().toStringAsFixed(1)}%',
                        style: AdminTextStyles.bodySmall.copyWith(
                          color: changeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              row.minPrice != null && row.maxPrice != null
                  ? '${_trimZeros(row.minPrice!)} – ${_trimZeros(row.maxPrice!)}'
                  : '—',
              style: AdminTextStyles.bodySmall.copyWith(
                color: AdminColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 86,
            child: row.weeklyAvgs.length < 2
                ? Text('—',
                    style: AdminTextStyles.bodySmall.copyWith(
                      color: AdminColors.textMuted,
                    ))
                : CustomPaint(
                    size: const Size(70, 22),
                    painter: _SparklinePainter(
                      row.weeklyAvgs,
                      AdminColors.primary,
                    ),
                  ),
          ),
          SizedBox(
            width: 96,
            child: compliance == null
                ? Text('—',
                    style: AdminTextStyles.bodySmall.copyWith(
                      color: AdminColors.textMuted,
                    ))
                : Tooltip(
                    message:
                        '${compliance.belowPct.toStringAsFixed(0)}% below · '
                        '${compliance.atPct.toStringAsFixed(0)}% at · '
                        '${compliance.abovePct.toStringAsFixed(0)}% above '
                        'the ${_trimZeros(anchor!)} EGP anchor',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: SizedBox(
                            height: 8,
                            width: 84,
                            child: Row(
                              children: [
                                if (compliance.below > 0)
                                  Expanded(
                                    flex: compliance.below,
                                    child:
                                        Container(color: AdminColors.info),
                                  ),
                                if (compliance.at > 0)
                                  Expanded(
                                    flex: compliance.at,
                                    child: Container(
                                        color: AdminColors.success),
                                  ),
                                if (compliance.above > 0)
                                  Expanded(
                                    flex: compliance.above,
                                    child: Container(
                                        color: AdminColors.warning),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          'anchor ${_trimZeros(anchor!)}',
                          style: AdminTextStyles.labelSmall.copyWith(
                            color: AdminColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          SizedBox(
            width: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${row.latestObs} wk',
                  style: AdminTextStyles.bodySmall,
                ),
                Text(
                  'of ${row.totalObs} in window',
                  style: AdminTextStyles.labelSmall.copyWith(
                    color: AdminColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _trimZeros(double v) {
  final s = v.toStringAsFixed(2);
  return s.endsWith('.00') ? v.toStringAsFixed(0) : s;
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  const _SparklinePainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final span = (maxV - minV) == 0 ? 1.0 : (maxV - minV);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = size.height - ((values[i] - minV) / span) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
