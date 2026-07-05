import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../data/price_monitor_provider.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';

/// Dialog showing row-level price observations (field detail / audit view).
Future<void> showPriceObservationsDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String missionId,
  required Set<String> skuKeys,
  PriceTimeMode timeMode = PriceTimeMode.today,
}) async {
  final filterParams = PriceFilterParams(
    missionId: missionId,
    skuKeys: skuKeys,
    timeMode: timeMode,
  );

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text("Today's observations")),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
      content: SizedBox(
        width: 720,
        height: 480,
        child: Consumer(
          builder: (context, ref, _) {
            final observationsAsync =
                ref.watch(rawPriceObservationsProvider(filterParams));

            return observationsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (observations) {
                if (observations.isEmpty) {
                  return Center(
                    child: Text(
                      skuKeys.isEmpty
                          ? 'No observations for today with current filters'
                          : 'No observations for the selected SKUs',
                      style: AdminTextStyles.bodySmall.copyWith(
                        color: AdminColors.textMuted,
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    _ObservationsTableHeader(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: observations.length,
                        itemBuilder: (context, i) {
                          final obs = observations[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    obs.productName,
                                    style: AdminTextStyles.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    obs.channel ?? '-',
                                    style: AdminTextStyles.bodySmall,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    obs.city ?? '-',
                                    style: AdminTextStyles.bodySmall,
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    '${obs.price.toStringAsFixed(2)} EGP',
                                    style: AdminTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    obs.locationName ?? '',
                                    style: AdminTextStyles.bodySmall.copyWith(
                                      color: AdminColors.textMuted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
      ],
    ),
  );
}

class _ObservationsTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: AdminColors.backgroundPage,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'SKU',
              style: AdminTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              'Channel',
              style: AdminTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              'City',
              style: AdminTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              'Price',
              style: AdminTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              'Location',
              style: AdminTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
