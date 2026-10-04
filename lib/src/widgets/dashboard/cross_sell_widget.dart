import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'export_button.dart';
import 'sku_filter_bar.dart';
import '../../data/missed_opps_provider.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';

/// Cross-Sell Opportunities Widget
///
/// Shows only WARM stores - locations where the company is already selling
/// other products, making it easier to add this SKU.
/// 
/// Self-contained with local filter state - no global dependencies.
class CrossSellWidget extends HookConsumerWidget {
  final String missionId;
  final String title;
  final String? subtitle;
  final String? subtitleAr;

  const CrossSellWidget({
    super.key,
    required this.missionId,
    this.title = 'Cross-Sell Opportunities',
    this.subtitle,
    this.subtitleAr,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Local filter state - each widget instance manages its own
    final filters = useSkuFilters();
    final filterParams = filters.params(missionId);

    // Watch data with local filters
    final topSkus = ref.watch(missedSkusForWidgetProvider(filterParams));

    // Filter to only show SKUs with warm stores
    final warmSkus = topSkus.whenData((skus) =>
        skus.where((s) => s.warmStoreCount > 0).toList()
          ..sort((a, b) => b.warmStoreCount.compareTo(a.warmStoreCount)));

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
          // Header
          Row(
            children: [
              Icon(Icons.trending_up, color: AdminColors.success, size: 24),
              const SizedBox(width: AdminSpacing.sm),
              Text(title, style: AdminTextStyles.sectionTitle),
              const Spacer(),
              // Export button (warm only)
              ExportButton(
                baseName: 'cross_sell_warm',
                buildData: () async => missedOppsCsv(
                    await ref.read(
                        missedOppsExportForWidgetProvider(filterParams).future),
                    storeType: 'Warm'),
              ),
              const SizedBox(width: AdminSpacing.sm),
              // Count badge
              warmSkus.when(
                data: (skus) {
                  final totalWarm =
                      skus.fold<int>(0, (sum, s) => sum + s.warmStoreCount);
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AdminColors.success.withOpacity(0.1),
                      borderRadius: AdminRadius.smAll,
                    ),
                    child: Text(
                      '${_formatNumber(totalWarm)} easy wins',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AdminColors.success,
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.sm),
          Text(
            'Stores where you already sell products - just add these SKUs!',
            style: AdminTextStyles.bodySmall.copyWith(
              color: AdminColors.textMuted,
            ),
          ),
          const SizedBox(height: AdminSpacing.md),

          // Filters row
          SkuFilterBar(missionId: missionId, filters: filters),
          const SizedBox(height: AdminSpacing.md),

          // Column headers
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AdminSpacing.sm, vertical: AdminSpacing.xs),
            decoration: BoxDecoration(
              color: AdminColors.backgroundPage,
              borderRadius: AdminRadius.smAll,
            ),
            child: Row(
              children: [
                const SizedBox(width: 32), // Rank column
                Expanded(
                  flex: 3,
                  child: Text(
                    'Missing SKU',
                    style: AdminTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'Package',
                    textAlign: TextAlign.center,
                    style: AdminTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'Warm',
                    textAlign: TextAlign.center,
                    style: AdminTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'Avg SKUs',
                    textAlign: TextAlign.center,
                    style: AdminTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Similar SKUs Available',
                    style: AdminTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AdminSpacing.xs),

          // SKU list
          Expanded(
            child: warmSkus.when(
              data: (skus) {
                if (skus.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: AdminColors.success, size: 48),
                        const SizedBox(height: AdminSpacing.sm),
                        Text(
                          'No cross-sell opportunities!',
                          style: AdminTextStyles.bodyMedium.copyWith(
                            color: AdminColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AdminSpacing.xs),
                        Text(
                          'All SKUs are available where your company is present',
                          style: AdminTextStyles.bodySmall.copyWith(
                            color: AdminColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: skus.length,
                  itemBuilder: (context, index) {
                    final sku = skus[index];

                    return Tooltip(
                      richMessage: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Easy Win Opportunity!\n\n',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          TextSpan(
                            text:
                                '${sku.sku} (${sku.category}) is missing at ${_formatNumber(sku.warmStoreCount)} stores.\n\n',
                          ),
                          TextSpan(
                            text:
                                'But these stores already sell ${sku.avgCompanySkusWhenWarm.floor()} of your other SKUs on average!\n\n',
                            style: TextStyle(color: Colors.green[200]),
                          ),
                          TextSpan(
                            text:
                                'Similar SKUs available: ${sku.competitorBrands}\n\n',
                            style: TextStyle(color: Colors.blue[200]),
                          ),
                          const TextSpan(
                            text:
                                'This is low-hanging fruit - the store already has a relationship with your company.',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      preferBelow: false,
                      waitDuration: const Duration(milliseconds: 300),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AdminSpacing.sm,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AdminColors.success.withOpacity(0.04),
                          borderRadius: AdminRadius.smAll,
                          border: Border.all(
                              color: AdminColors.success.withOpacity(0.15)),
                        ),
                        child: Row(
                          children: [
                            // Rank
                            Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: AdminColors.success.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AdminColors.success,
                                  ),
                                ),
                              ),
                            ),
                            // SKU info
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sku.sku,
                                    style: AdminTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${sku.brand} · ${sku.company}',
                                    style: AdminTextStyles.bodySmall.copyWith(
                                      color: AdminColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Package
                            SizedBox(
                              width: 80,
                              child: Text(
                                sku.package,
                                textAlign: TextAlign.center,
                                style: AdminTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            // Warm store count
                            SizedBox(
                              width: 80,
                              child: Text(
                                _formatNumber(sku.warmStoreCount),
                                textAlign: TextAlign.center,
                                style: AdminTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AdminColors.success,
                                ),
                              ),
                            ),
                            // Avg company SKUs
                            SizedBox(
                              width: 80,
                              child: Text(
                                sku.avgCompanySkusWhenWarm > 0
                                    ? '${sku.avgCompanySkusWhenWarm.floor()} SKUs'
                                    : '-',
                                textAlign: TextAlign.center,
                                style: AdminTextStyles.bodySmall.copyWith(
                                  color: AdminColors.textSecondary,
                                ),
                              ),
                            ),
                            // Competitor brands
                            Expanded(
                              flex: 2,
                              child: Text(
                                sku.competitorBrands,
                                style: AdminTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error loading data',
                  style: AdminTextStyles.bodySmall.copyWith(
                    color: AdminColors.error,
                  ),
                ),
              ),
            ),
          ),

          // Subtitle
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: AdminSpacing.md),
            Text(
              subtitle!,
              style: AdminTextStyles.bodySmall.copyWith(
                color: AdminColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }


  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
