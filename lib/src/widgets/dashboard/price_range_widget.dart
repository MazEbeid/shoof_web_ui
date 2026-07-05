import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'price_sku_picker.dart';
import 'price_widget_shell.dart';
import '../../data/anchor_prices_provider.dart';
import '../../data/price_monitor_provider.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_typography.dart';

/// Min–avg–max price spread per SKU with the anchor price overlaid.
class PriceRangeWidget extends HookConsumerWidget {
  final String missionId;
  final String clientId;
  final String title;
  final String? subtitle;

  const PriceRangeWidget({
    super.key,
    required this.missionId,
    required this.clientId,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSkuKeys = useState<Set<String>>({});

    final params = PriceFilterParams(
      missionId: missionId,
      skuKeys: selectedSkuKeys.value,
    );
    final summaryAsync = ref.watch(priceSkuSummaryProvider(params));
    final anchorAsync = ref.watch(anchorPricesProvider(
      AnchorPricesParams(clientId: clientId, missionId: missionId),
    ));
    final anchorPrices = anchorAsync.value?.prices ?? const <String, double>{};

    final selectedLabels = selectedSkuKeys.value.map(priceSkuLabel).toList()
      ..sort();

    Future<void> openSkuPicker() async {
      final result = await showPriceSkuPickerDialog(
        context: context,
        ref: ref,
        missionId: missionId,
        initialSelection: selectedSkuKeys.value,
      );
      if (result != null) selectedSkuKeys.value = result;
    }

    return PriceWidgetShell(
      title: title,
      subtitle: subtitle,
      trailing: PriceSkuSelectButton(
        selectedCount: selectedSkuKeys.value.length,
        selectedLabels: selectedLabels,
        onPressed: openSkuPicker,
      ),
      child: PriceAsyncContent(
        value: summaryAsync,
        builder: (summary) {
          if (selectedSkuKeys.value.isEmpty) {
            return const PriceWidgetMessage(
              message: 'Select SKUs to see their price spread',
            );
          }
          if (summary.isEmpty) {
            return const PriceWidgetMessage(
              message: 'No price data for the selected SKUs',
            );
          }
          return ListView.separated(
            itemCount: summary.skus.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AdminSpacing.md),
            itemBuilder: (context, i) {
              final sku = summary.skus[i];
              return _RangeRow(
                summary: sku,
                anchorPrice: anchorPrices[sku.skuKey],
              );
            },
          );
        },
      ),
    );
  }
}

class _RangeRow extends StatelessWidget {
  final PriceSkuSummary summary;
  final double? anchorPrice;

  const _RangeRow({required this.summary, this.anchorPrice});

  @override
  Widget build(BuildContext context) {
    // Scale covers observed range plus the anchor, with padding.
    final values = [
      summary.minPrice,
      summary.maxPrice,
      if (anchorPrice != null) anchorPrice!,
    ];
    final lo = values.reduce((a, b) => a < b ? a : b);
    final hi = values.reduce((a, b) => a > b ? a : b);
    final span = (hi - lo) == 0 ? 1.0 : (hi - lo);
    final scaleLo = lo - span * 0.1;
    final scaleSpan = span * 1.2;

    double fraction(double v) => ((v - scaleLo) / scaleSpan).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                summary.skuLabel,
                style: AdminTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${summary.minPrice.toStringAsFixed(2)} – '
              '${summary.avgPrice.toStringAsFixed(2)} – '
              '${summary.maxPrice.toStringAsFixed(2)} EGP'
              '${anchorPrice != null ? '  ·  anchor ${anchorPrice!.toStringAsFixed(2)}' : ''}',
              style: AdminTextStyles.labelSmall
                  .copyWith(color: AdminColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 18,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final left = fraction(summary.minPrice) * width;
              final right = fraction(summary.maxPrice) * width;
              final avgX = fraction(summary.avgPrice) * width;
              final anchorX =
                  anchorPrice != null ? fraction(anchorPrice!) * width : null;

              return Stack(
                children: [
                  // Track
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 7,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AdminColors.backgroundHover,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Min–max range bar
                  Positioned(
                    left: left,
                    width: (right - left).clamp(2.0, width),
                    top: 7,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AdminColors.primary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Average dot
                  Positioned(
                    left: (avgX - 5).clamp(0.0, width - 10),
                    top: 4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AdminColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Anchor tick
                  if (anchorX != null)
                    Positioned(
                      left: (anchorX - 1).clamp(0.0, width - 2),
                      top: 0,
                      child: Tooltip(
                        message:
                            'Anchor ${anchorPrice!.toStringAsFixed(2)} EGP',
                        child: Container(
                          width: 2,
                          height: 18,
                          color: AdminColors.error,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
