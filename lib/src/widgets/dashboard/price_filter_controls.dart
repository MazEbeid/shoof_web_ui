import 'package:flutter/material.dart';
import '../../data/price_monitor_provider.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';

class PriceTimeModeSelector extends StatelessWidget {
  final PriceTimeMode value;
  final ValueChanged<PriceTimeMode> onChanged;

  const PriceTimeModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: PriceTimeMode.values.map((mode) {
        final selected = mode == value;
        return Padding(
          padding: const EdgeInsets.only(right: AdminSpacing.sm),
          child: ChoiceChip(
            label: Text(mode.label),
            selected: selected,
            onSelected: (_) => onChanged(mode),
          ),
        );
      }).toList(),
    );
  }
}

class PriceRegionDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const PriceRegionDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PriceSimpleDropdown<String?>(
      label: 'Region',
      value: value,
      hint: 'All regions',
      items: [null, ...priceRegions],
      itemLabel: (v) => v ?? 'All regions',
      onChanged: onChanged,
    );
  }
}

class PriceSimpleDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final String hint;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;

  const PriceSimpleDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AdminTextStyles.labelSmall.copyWith(color: AdminColors.textMuted),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AdminColors.surface,
            borderRadius: AdminRadius.smAll,
            border: Border.all(color: AdminColors.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: Text(hint, style: AdminTextStyles.bodySmall),
              items: items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(itemLabel(item), style: AdminTextStyles.bodySmall),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null || items.contains(null)) onChanged(v as T);
              },
            ),
          ),
        ),
      ],
    );
  }
}
