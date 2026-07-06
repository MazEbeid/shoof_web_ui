import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'price_widget_shell.dart';
import 'widget_filters_row.dart';
import '../../data/price_monitor_provider.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_typography.dart';

/// Availability % (store-level, latest visit per store) joined with average
/// observed price per SKU — flags products that are both scarce and priced
/// above the median. Filters apply to BOTH sides of the join.
class AvailabilityVsPriceWidget extends HookConsumerWidget {
  final String missionId;
  final String title;
  final String? subtitle;

  const AvailabilityVsPriceWidget({
    super.key,
    required this.missionId,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCity = useState<String?>(null);
    final selectedChannel = useState<String?>(null);
    final startDate = useState<DateTime?>(null);
    final endDate = useState<DateTime?>(null);

    final hasFilters = selectedCity.value != null ||
        selectedChannel.value != null ||
        startDate.value != null ||
        endDate.value != null;

    final rowsAsync = ref.watch(
      availabilityVsPriceProvider(PriceFilterParams(
        missionId: missionId,
        city: selectedCity.value,
        channel: selectedChannel.value,
        startDate: startDate.value,
        endDate: endDate.value,
      )),
    );

    return PriceWidgetShell(
      title: title,
      subtitle: subtitle,
      child: Column(
        children: [
          WidgetFiltersRow(
            missionId: missionId,
            selectedCity: selectedCity.value,
            selectedChannel: selectedChannel.value,
            startDate: startDate.value,
            endDate: endDate.value,
            hasFilters: hasFilters,
            onCityChanged: (v) => selectedCity.value = v,
            onChannelChanged: (v) => selectedChannel.value = v,
            onDateRangeChanged: (range) {
              startDate.value = range?.start;
              endDate.value = range?.end;
            },
            onClearAll: () {
              selectedCity.value = null;
              selectedChannel.value = null;
              startDate.value = null;
              endDate.value = null;
            },
          ),
          const SizedBox(height: AdminSpacing.md),
          Expanded(
            child: PriceAsyncContent(
              value: rowsAsync,
              builder: (rows) {
                if (rows.isEmpty) {
                  return const PriceWidgetMessage(
                    message: 'No availability data for this mission',
                  );
                }
                return Column(
                  children: [
                    _Header(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: rows.length,
                        itemBuilder: (context, i) => _Row(row: rows[i]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
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
