import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../data/anchor_prices_provider.dart';
import 'export_button.dart';
import '../../data/price_monitor_provider.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';

class PriceVsAnchorWidget extends ConsumerWidget {
  final String missionId;
  final String clientId;
  final String title;
  final String? subtitle;

  /// Hides the anchor editor (client-facing renderers like shoof_insights).
  final bool readOnly;

  const PriceVsAnchorWidget({
    super.key,
    required this.missionId,
    required this.clientId,
    required this.title,
    this.subtitle,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterParams = PriceFilterParams(missionId: missionId);

    final anchorAsync = ref.watch(anchorPricesProvider(
      AnchorPricesParams(clientId: clientId, missionId: missionId),
    ));

    final vsAnchorAsync = anchorAsync.when(
      data: (anchorState) => ref.watch(priceVsAnchorProvider(
        PriceVsAnchorParams(
          filters: filterParams,
          anchorPrices: anchorState.prices,
        ),
      )),
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
    );

    return Container(
      height: AdminSpacing.widgetLarge,
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: AdminRadius.lgAll,
        border: Border.all(color: AdminColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AdminTextStyles.sectionTitle)),
              ExportButton(
                baseName: 'price_vs_anchor',
                buildData: () async {
                  final anchorState = ref
                      .read(anchorPricesProvider(AnchorPricesParams(
                          clientId: clientId, missionId: missionId)))
                      .value;
                  final rows = await ref.read(priceVsAnchorProvider(
                    PriceVsAnchorParams(
                      filters: filterParams,
                      anchorPrices:
                          anchorState?.prices ?? const <String, double>{},
                    ),
                  ).future);
                  return CsvExportData(
                    header: const [
                      'Product', 'City', 'Channel', 'Observed Avg',
                      'Anchor Price', 'Deviation %', 'Observations',
                    ],
                    rows: rows
                        .map((r) => <Object?>[
                              r.productName, r.city, r.channel,
                              r.observedAvg.toStringAsFixed(2),
                              r.anchorPrice?.toStringAsFixed(2),
                              r.deviationPercent?.toStringAsFixed(1),
                              r.observationCount,
                            ])
                        .toList(),
                  );
                },
              ),
              if (!readOnly) ...[
                const SizedBox(width: AdminSpacing.sm),
                TextButton.icon(
                  onPressed: () => _showAnchorEditor(context, ref),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Anchors'),
                ),
              ],
            ],
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: AdminSpacing.xs),
            Text(
              subtitle!,
              style: AdminTextStyles.bodySmall.copyWith(
                color: AdminColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: AdminSpacing.sm),
          Text(
            'Showing SKUs with anchor prices set',
            style: AdminTextStyles.labelSmall.copyWith(
              color: AdminColors.textMuted,
            ),
          ),
          _TableHeader(),
          Expanded(
            child: vsAnchorAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (rows) {
                if (rows.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No anchored SKUs in this slice',
                          style: AdminTextStyles.bodySmall.copyWith(
                            color: AdminColors.textMuted,
                          ),
                        ),
                        if (!readOnly) ...[
                          const SizedBox(height: AdminSpacing.sm),
                          TextButton(
                            onPressed: () => _showAnchorEditor(context, ref),
                            child: const Text('Set anchor prices'),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final row = rows[i];
                    final dev = row.deviationPercent;
                    final color = dev == null
                        ? AdminColors.textMuted
                        : dev.abs() <= 10
                            ? AdminColors.success
                            : dev > 0
                                ? AdminColors.error
                                : AdminColors.info;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.05),
                        borderRadius: AdminRadius.smAll,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              row.productName,
                              style: AdminTextStyles.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              row.channel ?? '-',
                              style: AdminTextStyles.bodySmall,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              row.city ?? '-',
                              style: AdminTextStyles.bodySmall,
                            ),
                          ),
                          SizedBox(
                            width: 70,
                            child: Text(
                              row.observedAvg.toStringAsFixed(2),
                              style: AdminTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 70,
                            child: Text(
                              row.anchorPrice?.toStringAsFixed(2) ?? '—',
                              style: AdminTextStyles.bodySmall,
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              dev != null
                                  ? '${dev > 0 ? '+' : ''}${dev.toStringAsFixed(1)}%'
                                  : '—',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAnchorEditor(BuildContext context, WidgetRef ref) =>
      showAnchorEditorDialog(context, ref,
          missionId: missionId, clientId: clientId);
}

/// Anchor price editor — shared by Price vs Anchor and Price Monitor.
Future<void> showAnchorEditorDialog(
  BuildContext context,
  WidgetRef ref, {
  required String missionId,
  required String clientId,
}) async {
  final skus = await ref.read(priceSkusForMissionProvider(missionId).future);
  final anchorNotifier = ref.read(anchorPricesProvider(
    AnchorPricesParams(clientId: clientId, missionId: missionId),
  ).notifier);
  final current = ref
          .read(anchorPricesProvider(
            AnchorPricesParams(clientId: clientId, missionId: missionId),
          ))
          .value
          ?.prices ??
      {};

  if (!context.mounted) return;

  await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anchor Prices'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: ListView.builder(
            itemCount: skus.length,
            itemBuilder: (context, i) {
              final skuKey = skus[i];
              final controller = TextEditingController(
                text: current[skuKey]?.toStringAsFixed(2) ?? '',
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        priceSkuLabel(skuKey),
                        style: AdminTextStyles.bodySmall,
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'EGP',
                          isDense: true,
                        ),
                        onSubmitted: (v) {
                          final price = double.tryParse(v);
                          if (price != null) {
                            anchorNotifier.setPrice(skuKey, price);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _TableHeader extends StatelessWidget {
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
              style: AdminTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Channel',
              style: AdminTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'City',
              style: AdminTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              'Observed',
              style: AdminTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              'Anchor',
              style: AdminTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              'Dev %',
              style: AdminTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
