import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../data/price_monitor_provider.dart';
import '../../data/widget_data_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';

/// Availability % (store-level, latest visit per store) joined with average
/// observed price per SKU — flags products that are both scarce and priced
/// above the median. Filters apply to BOTH sides of the join.
///
/// Rendered as the "Availability × Price" view inside
/// AvailabilityAnalysisWidget (the standalone widget type was consolidated
/// there, 2026-07-07); self-sizing like the other analysis views.
class AvailabilityPriceListView extends ConsumerWidget {
  final WidgetFilterParams params;
  final bool showAll;
  final VoidCallback onToggleShowAll;
  final int previewRowCount;

  const AvailabilityPriceListView({
    super.key,
    required this.params,
    required this.showAll,
    required this.onToggleShowAll,
    this.previewRowCount = 8,
  });

  /// Maps the shared widget filter state onto the price provider's params.
  static PriceFilterParams priceParams(WidgetFilterParams params) =>
      PriceFilterParams(
        missionId: params.missionId,
        city: params.city,
        channel: params.channel,
        company: params.company,
        brand: params.brand,
        package: params.package,
        size: params.size,
        startDate: params.startDate,
        endDate: params.endDate,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowsAsync = ref.watch(availabilityVsPriceProvider(priceParams(params)));

    return rowsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Could not load availability/price data',
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
                'No availability data for this mission',
                style: AdminTextStyles.bodySmall.copyWith(
                  color: AdminColors.textMuted,
                ),
              ),
            ),
          );
        }
        final visible = showAll ? rows : rows.take(previewRowCount).toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(),
            ...visible.map((row) => _Row(row: row)),
            if (rows.length > previewRowCount)
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: onToggleShowAll,
                  icon: Icon(
                    showAll ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  label: Text(
                    showAll
                        ? 'Show top $previewRowCount'
                        : 'Show all ${rows.length} rows',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
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
          SizedBox(width: 110, child: Text('Availability', style: style)),
          SizedBox(width: 90, child: Text('Avg price', style: style)),
          SizedBox(width: 70, child: Text('Stores', style: style)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final AvailabilityPriceRow row;

  const _Row({required this.row});

  @override
  Widget build(BuildContext context) {
    final rateColor = row.availabilityRate >= 70
        ? AdminColors.success
        : row.availabilityRate >= 50
            ? AdminColors.warning
            : AdminColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: row.flagged
            ? AdminColors.error.withValues(alpha: 0.06)
            : Colors.transparent,
        borderRadius: AdminRadius.smAll,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (row.flagged) ...[
                  const Tooltip(
                    message: 'Scarce and priced above the median',
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: AdminColors.error,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    row.skuLabel,
                    style: AdminTextStyles.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 110,
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (row.availabilityRate / 100).clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: AdminColors.backgroundHover,
                      valueColor: AlwaysStoppedAnimation<Color>(rateColor),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${row.availabilityRate.toStringAsFixed(0)}%',
                  style: AdminTextStyles.bodySmall.copyWith(color: rateColor),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              row.avgPrice != null
                  ? '${row.avgPrice!.toStringAsFixed(2)} EGP'
                  : '—',
              style: AdminTextStyles.bodySmall.copyWith(
                fontWeight:
                    row.flagged ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              '${row.totalChecks}',
              style: AdminTextStyles.bodySmall
                  .copyWith(color: AdminColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
