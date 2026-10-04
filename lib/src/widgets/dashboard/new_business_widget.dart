import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'export_button.dart';
import 'sku_filter_bar.dart';
import '../../data/missed_opps_provider.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';

/// New Business Opportunities Widget
///
/// Shows only COLD stores - locations where the company is NOT selling yet.
/// These represent new market expansion opportunities (harder but high potential).
/// 
/// Self-contained with local filter state - no global dependencies.
class NewBusinessWidget extends HookConsumerWidget {
  final String missionId;
  final String title;
  final String? subtitle;
  final String? subtitleAr;

  const NewBusinessWidget({
    super.key,
    required this.missionId,
    this.title = 'New Business Opportunities',
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

    // Filter to only show SKUs with COLD stores (new business opportunities)
    final coldSkus = topSkus.whenData((skus) =>
        skus.where((s) => s.coldStoreCount > 0).toList()
          ..sort((a, b) => b.coldStoreCount.compareTo(a.coldStoreCount)));

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
              Icon(Icons.store_outlined, color: AdminColors.info, size: 24),
              const SizedBox(width: AdminSpacing.sm),
              Text(title, style: AdminTextStyles.sectionTitle),
              const Spacer(),
              // Export button
              ExportButton(
                baseName: 'new_business',
                buildData: () async => missedOppsCsv(
                    await ref.read(
                        missedOppsExportForWidgetProvider(filterParams).future),
                    storeType: 'Cold'),
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.sm),
          Text(
            'Cold stores - new market expansion opportunities',
            style: AdminTextStyles.bodySmall.copyWith(
              color: AdminColors.textMuted,
            ),
          ),
          const SizedBox(height: AdminSpacing.md),

          // Filters row (region-level: expansion is planned by region)
          SkuFilterBar(
            missionId: missionId,
            filters: filters,
            regionInsteadOfCity: true,
          ),
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
                const SizedBox(width: 32),
                Expanded(
                  flex: 3,
                  child: Text('SKU',
                      style: AdminTextStyles.labelSmall
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
                SizedBox(
                  width: 80,
                  child: Text('Package',
                      textAlign: TextAlign.center,
                      style: AdminTextStyles.labelSmall
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
                SizedBox(
                  width: 80,
                  child: Text('Cold',
                      textAlign: TextAlign.center,
                      style: AdminTextStyles.labelSmall
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
                SizedBox(
                  width: 70,
                  child: Text('Total',
                      textAlign: TextAlign.right,
                      style: AdminTextStyles.labelSmall
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AdminSpacing.xs),

          // SKU list
          Expanded(
            child: coldSkus.when(
              data: (skus) {
                if (skus.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 48, color: AdminColors.success),
                        const SizedBox(height: AdminSpacing.md),
                        Text(
                          'No cold store opportunities',
                          style: AdminTextStyles.bodySmall.copyWith(
                            color: AdminColors.textMuted,
                          ),
                        ),
                        Text(
                          'All stores have your products!',
                          style: AdminTextStyles.bodySmall.copyWith(
                            color: AdminColors.success,
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
                    return _buildSkuRow(sku, index);
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: AdminTextStyles.bodySmall
                        .copyWith(color: AdminColors.error)),
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

  Widget _buildSkuRow(MissedOpportunitySku sku, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.sm,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AdminColors.info.withOpacity(0.04),
        borderRadius: AdminRadius.smAll,
        border: Border.all(color: AdminColors.info.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AdminColors.info.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.info,
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getColorForPackage(sku.package).withOpacity(0.1),
                borderRadius: AdminRadius.smAll,
              ),
              child: Text(
                sku.package,
                textAlign: TextAlign.center,
                style: AdminTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Cold store count
          SizedBox(
            width: 80,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AdminColors.info.withOpacity(0.15),
                    borderRadius: AdminRadius.smAll,
                  ),
                  child: Text(
                    '${sku.coldStoreCount}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.info,
                    ),
                  ),
                ),
                Text(
                  'new stores',
                  style: TextStyle(
                    fontSize: 8,
                    color: AdminColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Total missed
          SizedBox(
            width: 70,
            child: Text(
              '${sku.missedCount}',
              textAlign: TextAlign.right,
              style: AdminTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForPackage(String package) {
    final p = package.toUpperCase();
    if (p.contains('PET') || p.contains('PLASTIC')) {
      return AdminColors.primary;
    }
    if (p.contains('CAN')) {
      return AdminColors.info;
    }
    if (p.contains('GLASS') || p.contains('RGB') || p.contains('NRG')) {
      return const Color(0xFF8B4513);
    }
    if (p.contains('TETRA') || p.contains('CARTON')) {
      return AdminColors.warning;
    }
    return AdminColors.textMuted;
  }
}
