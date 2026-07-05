import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'price_observations_dialog.dart';
import '../../data/price_monitor_provider.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';

/// Legacy widget — field-level detail is available from Price Trend (Today → View observations).
class PriceTodayWidget extends ConsumerWidget {
  final String missionId;
  final String title;
  final String? subtitle;

  const PriceTodayWidget({
    super.key,
    required this.missionId,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: AdminRadius.lgAll,
        border: Border.all(color: AdminColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AdminTextStyles.sectionTitle),
          const SizedBox(height: AdminSpacing.sm),
          Text(
            'Row-level field detail now lives in Price Trend. '
            'Switch to Today mode, select SKUs, then open View observations.',
            style: AdminTextStyles.bodySmall.copyWith(
              color: AdminColors.textMuted,
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => showPriceObservationsDialog(
                context: context,
                ref: ref,
                missionId: missionId,
                skuKeys: const {},
                timeMode: PriceTimeMode.today,
              ),
              icon: const Icon(Icons.table_rows_outlined, size: 16),
              label: const Text("View today's observations"),
            ),
          ),
        ],
      ),
    );
  }
}
