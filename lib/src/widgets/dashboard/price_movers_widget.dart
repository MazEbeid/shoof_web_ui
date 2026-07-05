import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'price_widget_shell.dart';
import '../../data/price_monitor_provider.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';

/// SKUs with the biggest average-price change between the last two periods.
class PriceMoversWidget extends HookConsumerWidget {
  final String missionId;
  final String title;
  final String? subtitle;

  const PriceMoversWidget({
    super.key,
    required this.missionId,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeMode = useState(PriceTimeMode.wow);

    final moversAsync = ref.watch(priceMoversProvider(PriceFilterParams(
      missionId: missionId,
      timeMode: timeMode.value,
    )));

    return PriceWidgetShell(
      title: title,
      subtitle: subtitle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [PriceTimeMode.wow, PriceTimeMode.mom].map((mode) {
          return Padding(
            padding: const EdgeInsets.only(left: AdminSpacing.sm),
            child: ChoiceChip(
              label: Text(mode.label),
              selected: timeMode.value == mode,
              onSelected: (_) => timeMode.value = mode,
            ),
          );
        }).toList(),
      ),
      child: PriceAsyncContent(
        value: moversAsync,
        builder: (movers) {
          if (movers.isEmpty) {
            return PriceWidgetMessage(
              message: timeMode.value == PriceTimeMode.wow
                  ? 'Not enough weekly history to compare prices yet'
                  : 'Not enough monthly history to compare prices yet',
            );
          }
          return Column(
            children: [
              _MoversHeader(mode: timeMode.value),
              Expanded(
                child: ListView.builder(
                  itemCount: movers.length,
                  itemBuilder: (context, i) => _MoverRow(row: movers[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MoversHeader extends StatelessWidget {
  final PriceTimeMode mode;

  const _MoversHeader({required this.mode});

  @override
  Widget build(BuildContext context) {
    TextStyle style = AdminTextStyles.labelSmall.copyWith(
      fontWeight: FontWeight.w600,
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: AdminColors.backgroundPage,
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('SKU', style: style)),
          SizedBox(
            width: 90,
            child: Text(
              mode == PriceTimeMode.wow ? 'Prev week' : 'Prev month',
              style: style,
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              mode == PriceTimeMode.wow ? 'This week' : 'This month',
              style: style,
            ),
          ),
          SizedBox(width: 80, child: Text('Change', style: style)),
        ],
      ),
    );
  }
}

class _MoverRow extends StatelessWidget {
  final PriceMoverRow row;

  const _MoverRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final change = row.changePercent;
    final up = change > 0;
    final color = change == 0
        ? AdminColors.textMuted
        : up
            ? AdminColors.error
            : AdminColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: AdminRadius.smAll,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.skuLabel,
              style: AdminTextStyles.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              row.previousAvg.toStringAsFixed(2),
              style: AdminTextStyles.bodySmall,
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              row.currentAvg.toStringAsFixed(2),
              style: AdminTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  change == 0
                      ? Icons.remove
                      : up
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 2),
                Text(
                  '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
