import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'export_button.dart';
import 'sku_filter_bar.dart';
import '../../data/missed_opps_provider.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';

/// Missed Opportunities Widget
///
/// Shows SKUs that were out of stock when a competitor's similar SKU
/// (same size + package) was available at the same location.
/// Includes Cold/Warm store classification.
///
/// Self-contained with local filter state - no global dependencies.
class MissedOpportunitiesWidget extends HookConsumerWidget {
  final String missionId;
  final String title;
  final String? subtitle;
  final String? subtitleAr;

  const MissedOpportunitiesWidget({
    super.key,
    required this.missionId,
    this.title = 'Missed Opportunities',
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
              Icon(Icons.trending_down, color: AdminColors.error, size: 24),
              const SizedBox(width: AdminSpacing.sm),
              Text(title, style: AdminTextStyles.sectionTitle),
              const Spacer(),
              // Export button
              ExportButton(
                baseName: 'missed_opportunities',
                buildData: () async => missedOppsCsv(await ref
                    .read(missedOppsExportForWidgetProvider(filterParams)
                        .future)),
              ),
              const SizedBox(width: AdminSpacing.sm),
              // Count badge
              topSkus.when(
                data: (skus) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AdminColors.error.withOpacity(0.1),
                    borderRadius: AdminRadius.smAll,
                  ),
                  child: Text(
                    '${skus.length} SKUs',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AdminColors.error,
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
            'Stores whose latest visit found the SKU OOS while a same-size/package '
            'competitor was on shelf — each store counts once',
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
                    'SKU',
                    style: AdminTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    'Package',
                    textAlign: TextAlign.center,
                    style: AdminTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    'Type',
                    textAlign: TextAlign.center,
                    style: AdminTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    'Cold',
                    textAlign: TextAlign.center,
                    style: AdminTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    'Warm',
                    textAlign: TextAlign.center,
                    style: AdminTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    'Total',
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
            child: topSkus.when(
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
                          'No missed opportunities!',
                          style: AdminTextStyles.bodyMedium.copyWith(
                            color: AdminColors.success,
                            fontWeight: FontWeight.w600,
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
                    final primaryType = sku.warmStoreCount > sku.coldStoreCount
                        ? 'Warm'
                        : 'Cold';
                    final typeColor = primaryType == 'Warm'
                        ? AdminColors.warning
                        : AdminColors.info;

                    return Tooltip(
                      richMessage: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Why is this a missed opportunity?\n\n',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          TextSpan(
                            text:
                                '${sku.sku} (${sku.category}) was out of stock at ${_formatNumber(sku.missedCount)} locations.\n\n',
                          ),
                          TextSpan(
                            text:
                                'Cold stores (${sku.coldStoreCount}): Your company has NO products there.\n',
                            style: TextStyle(color: Colors.blue[200]),
                          ),
                          TextSpan(
                            text:
                                'Warm stores (${sku.warmStoreCount}): Your company IS selling other products - easy win!\n\n',
                            style: TextStyle(color: Colors.orange[200]),
                          ),
                          TextSpan(
                            text:
                                'Similar SKUs available: ${sku.competitorBrands}',
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
                          color: typeColor.withOpacity(0.04),
                          borderRadius: AdminRadius.smAll,
                          border:
                              Border.all(color: typeColor.withOpacity(0.15)),
                        ),
                        child: Row(
                          children: [
                            // Rank
                            Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: typeColor,
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
                              width: 72,
                              child: Text(
                                sku.package,
                                textAlign: TextAlign.center,
                                style: AdminTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            // Type (Cold/Warm)
                            SizedBox(
                              width: 72,
                              child: Text(
                                primaryType,
                                textAlign: TextAlign.center,
                                style: AdminTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: primaryType == 'Warm'
                                      ? const Color(0xFFE67E22)
                                      : AdminColors.info,
                                ),
                              ),
                            ),
                            // Cold count
                            SizedBox(
                              width: 56,
                              child: Text(
                                _formatNumber(sku.coldStoreCount),
                                textAlign: TextAlign.center,
                                style: AdminTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AdminColors.info,
                                ),
                              ),
                            ),
                            // Warm count
                            SizedBox(
                              width: 56,
                              child: Text(
                                _formatNumber(sku.warmStoreCount),
                                textAlign: TextAlign.center,
                                style: AdminTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFE67E22),
                                ),
                              ),
                            ),
                            // Total
                            SizedBox(
                              width: 72,
                              child: Text(
                                _formatNumber(sku.missedCount),
                                textAlign: TextAlign.center,
                                style: AdminTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AdminColors.error,
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
