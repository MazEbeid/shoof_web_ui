import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'price_filter_controls.dart';
import '../../data/price_monitor_provider.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';

const _skuWarningThreshold = 10;

/// Opens a modal to select SKUs. Returns the new selection, or null if cancelled.
Future<Set<String>?> showPriceSkuPickerDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String missionId,
  required Set<String> initialSelection,
}) async {
  return showDialog<Set<String>>(
    context: context,
    builder: (ctx) => _PriceSkuPickerDialog(
      missionId: missionId,
      initialSelection: initialSelection,
    ),
  );
}

/// Compact trigger: button + optional selected SKU chips.
class PriceSkuSelectButton extends StatelessWidget {
  final int selectedCount;
  final List<String> selectedLabels;
  final VoidCallback onPressed;

  const PriceSkuSelectButton({
    super.key,
    required this.selectedCount,
    required this.selectedLabels,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.checklist, size: 16),
          label: Text(
            selectedCount == 0 ? 'Select SKUs' : 'SKUs ($selectedCount)',
          ),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        if (selectedLabels.isNotEmpty) ...[
          const SizedBox(height: AdminSpacing.xs),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.end,
            children: selectedLabels.take(4).map((label) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AdminColors.backgroundHover,
                  borderRadius: AdminRadius.smAll,
                  border: Border.all(color: AdminColors.divider),
                ),
                child: Text(
                  label,
                  style: AdminTextStyles.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
          if (selectedLabels.length > 4)
            Text(
              '+${selectedLabels.length - 4} more',
              style: AdminTextStyles.labelSmall.copyWith(
                color: AdminColors.textMuted,
              ),
            ),
        ],
      ],
    );
  }
}

class _PriceSkuPickerDialog extends StatefulWidget {
  final String missionId;
  final Set<String> initialSelection;

  const _PriceSkuPickerDialog({
    required this.missionId,
    required this.initialSelection,
  });

  @override
  State<_PriceSkuPickerDialog> createState() => _PriceSkuPickerDialogState();
}

class _PriceSkuPickerDialogState extends State<_PriceSkuPickerDialog> {
  late Set<String> _draft;
  String? _brandFilter;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _draft = Set<String>.from(widget.initialSelection);
  }

  void _toggleSku(String skuKey, bool checked) {
    setState(() {
      if (checked) {
        _draft.add(skuKey);
      } else {
        _draft.remove(skuKey);
      }
    });
  }

  List<PriceSkuOption> _visibleOptions(List<PriceSkuOption> all) {
    var list = all;
    if (_brandFilter != null) {
      list = list.where((o) => o.category == _brandFilter).toList();
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.trim().toLowerCase();
      list = list.where((o) => o.label.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select SKUs to compare'),
      content: SizedBox(
        width: 480,
        height: 520,
        child: Consumer(
          builder: (context, ref, _) {
            final optionsAsync = ref.watch(
              priceSkuOptionsProvider(
                PriceSkuListParams(missionId: widget.missionId),
              ),
            );
            final brandsAsync =
                ref.watch(priceCategoriesForMissionProvider(widget.missionId));

            return optionsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (_, __) => const Text('Failed to load SKUs'),
              data: (allOptions) {
                final visible = _visibleOptions(allOptions);
                final brands = brandsAsync.valueOrNull ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (brands.isNotEmpty)
                      Row(
                        children: [
                          Expanded(
                            child: PriceSimpleDropdown<String?>(
                              label: 'Brand',
                              value: _brandFilter,
                              hint: 'All brands',
                              items: [null, ...brands],
                              itemLabel: (v) => v ?? 'All brands',
                              onChanged: (v) =>
                                  setState(() => _brandFilter = v),
                            ),
                          ),
                          TextButton(
                            onPressed: visible.isEmpty
                                ? null
                                : () {
                                    setState(() {
                                      for (final o in visible) {
                                        _draft.add(o.skuKey);
                                      }
                                    });
                                  },
                            child: const Text('Select all'),
                          ),
                          TextButton(
                            onPressed: _draft.isEmpty
                                ? null
                                : () => setState(() => _draft.clear()),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    const SizedBox(height: AdminSpacing.sm),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search SKUs...',
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: AdminRadius.smAll,
                        ),
                      ),
                      style: AdminTextStyles.bodySmall,
                      onChanged: (v) => setState(() => _search = v),
                    ),
                    const SizedBox(height: AdminSpacing.sm),
                    if (_draft.length > _skuWarningThreshold)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
                        child: Text(
                          'Chart may be hard to read — consider fewer SKUs '
                          '(${_draft.length} selected)',
                          style: AdminTextStyles.labelSmall.copyWith(
                            color: AdminColors.warning,
                          ),
                        ),
                      ),
                    Text(
                      '${_draft.length} selected · ${visible.length} shown',
                      style: AdminTextStyles.labelSmall.copyWith(
                        color: AdminColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AdminSpacing.xs),
                    Expanded(
                      child: visible.isEmpty
                          ? Center(
                              child: Text(
                                'No SKUs match your search',
                                style: AdminTextStyles.bodySmall.copyWith(
                                  color: AdminColors.textMuted,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: visible.length,
                              itemBuilder: (context, i) {
                                final option = visible[i];
                                final checked = _draft.contains(option.skuKey);
                                return CheckboxListTile(
                                  dense: true,
                                  value: checked,
                                  title: Text(
                                    option.label,
                                    style: AdminTextStyles.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: option.category != null
                                      ? Text(
                                          option.category!,
                                          style: AdminTextStyles.labelSmall
                                              .copyWith(
                                            color: AdminColors.textMuted,
                                          ),
                                        )
                                      : null,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  onChanged: (v) =>
                                      _toggleSku(option.skuKey, v ?? false),
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _draft),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

/// Legend chips for multi-SKU trend lines.
class PriceTrendLegend extends StatelessWidget {
  final List<PriceTrendSeries> series;

  const PriceTrendLegend({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AdminSpacing.sm,
      runSpacing: AdminSpacing.xs,
      children: series.map((s) {
        final color = priceTrendColorForIndex(s.colorIndex);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AdminRadius.smAll,
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                s.skuLabel,
                style: AdminTextStyles.labelSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

Color priceTrendColorForIndex(int index) {
  const palette = [
    Color(0xFF9C27B0),
    Color(0xFF2962FF),
    Color(0xFF00C853),
    Color(0xFFFF6F00),
    Color(0xFFD81B60),
    Color(0xFF00838F),
    Color(0xFF6C5CE7),
    Color(0xFF795548),
    Color(0xFF455A64),
    Color(0xFFC0CA33),
    Color(0xFF5E35B1),
    Color(0xFFEF6C00),
  ];
  return palette[index % palette.length];
}
