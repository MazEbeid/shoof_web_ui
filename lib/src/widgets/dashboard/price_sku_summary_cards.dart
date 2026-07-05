import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'price_sku_picker.dart';
import '../../data/price_monitor_provider.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../admin_stat_card.dart';

const _maxCards = 4;
const _maxSkuCardsWhenMany = 3;

/// Per-SKU raw avg price cards + optional spread card for Price Trend.
class PriceSkuSummaryCards extends StatelessWidget {
  final AsyncValue<PriceSkuSummaryData> summaryAsync;

  const PriceSkuSummaryCards({super.key, required this.summaryAsync});

  @override
  Widget build(BuildContext context) {
    return summaryAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
        child: AdminStatCardRow(
          cards: List.generate(
            2,
            (_) => const AdminStatCard(
              title: 'Loading…',
              value: '—',
              isLoading: true,
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        if (data.isEmpty) return const SizedBox.shrink();

        final cards = _buildCards(data);
        if (cards.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
          child: AdminStatCardRow(cards: cards),
        );
      },
    );
  }

  List<AdminStatCard> _buildCards(PriceSkuSummaryData data) {
    final cards = <AdminStatCard>[];
    final skus = data.skus;
    final total = skus.length;

    final skuCardCount = total <= _maxCards ? total : _maxSkuCardsWhenMany;
    final includeSpread = data.spread != null &&
        total >= 2 &&
        (total < _maxCards || total > _maxCards);

    for (var i = 0; i < skuCardCount; i++) {
      final sku = skus[i];
      final color = priceTrendColorForIndex(sku.colorIndex);
      cards.add(AdminStatCard(
        title: _shortLabel(sku.skuLabel),
        value: '${sku.avgPrice.toStringAsFixed(2)} EGP',
        subtitle: _storeLabel(sku.observationCount),
        icon: Icons.sell_outlined,
        accentColor: color,
      ));
    }

    if (includeSpread && data.spread != null) {
      final spread = data.spread!;
      final hidden = total > _maxSkuCardsWhenMany ? total - _maxSkuCardsWhenMany : 0;
      final spreadWithHidden = PriceSpreadSummary(
        spread: spread.spread,
        highLabel: spread.highLabel,
        lowLabel: spread.lowLabel,
        hiddenSkuCount: hidden,
      );
      cards.add(AdminStatCard(
        title: 'Price spread',
        value: '${spreadWithHidden.spread.toStringAsFixed(2)} EGP',
        subtitle: _spreadSubtitle(spreadWithHidden),
        icon: Icons.compare_arrows,
        accentColor: AdminColors.info,
      ));
    }

    return cards.take(_maxCards).toList();
  }

  String _shortLabel(String label) {
    if (label.length <= 32) return label;
    return '${label.substring(0, 29)}…';
  }

  String _storeLabel(int count) {
    return count == 1 ? '1 observation' : '$count observations';
  }

  String _spreadSubtitle(PriceSpreadSummary spread) {
    final high = _shortLabel(spread.highLabel);
    final low = _shortLabel(spread.lowLabel);
    final base = '$high ↑ · $low ↓';
    if (spread.hiddenSkuCount > 0) {
      return '$base · +${spread.hiddenSkuCount} more in chart';
    }
    return base;
  }
}
