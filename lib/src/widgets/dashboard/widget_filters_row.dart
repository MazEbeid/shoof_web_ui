import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../data/widget_data_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';
import '../admin_date_range_picker.dart';

/// Reusable filter row for dashboard widgets
/// Includes: City dropdown, Channel dropdown, Date range picker
class WidgetFiltersRow extends ConsumerWidget {
  final String missionId;
  final String? selectedCity;
  final String? selectedChannel;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<String?> onCityChanged;
  final ValueChanged<String?> onChannelChanged;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;
  final VoidCallback? onClearAll;
  final bool hasFilters;

  const WidgetFiltersRow({
    super.key,
    required this.missionId,
    this.selectedCity,
    this.selectedChannel,
    this.startDate,
    this.endDate,
    required this.onCityChanged,
    required this.onChannelChanged,
    required this.onDateRangeChanged,
    this.onClearAll,
    this.hasFilters = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citiesAsync = ref.watch(missionCitiesProvider(missionId));
    final channelsAsync = ref.watch(missionChannelsProvider(missionId));

    return Container(
      padding: const EdgeInsets.all(AdminSpacing.sm),
      decoration: BoxDecoration(
        color: AdminColors.backgroundHover,
        borderRadius: AdminRadius.smAll,
      ),
      child: Row(
        children: [
          // City dropdown
          Expanded(
            child: citiesAsync.when(
              loading: () => _buildDropdown(
                label: 'City',
                hint: 'Loading...',
                items: const [],
                onChanged: (_) {},
              ),
              error: (_, __) => _buildDropdown(
                label: 'City',
                hint: 'Error',
                items: const [],
                onChanged: (_) {},
              ),
              data: (cities) => _buildDropdown(
                label: 'City',
                value: selectedCity,
                hint: 'All cities',
                items: cities,
                onChanged: onCityChanged,
              ),
            ),
          ),
          const SizedBox(width: AdminSpacing.sm),

          // Channel dropdown
          Expanded(
            child: channelsAsync.when(
              loading: () => _buildDropdown(
                label: 'Channel',
                hint: 'Loading...',
                items: const [],
                onChanged: (_) {},
              ),
              error: (_, __) => _buildDropdown(
                label: 'Channel',
                hint: 'Error',
                items: const [],
                onChanged: (_) {},
              ),
              data: (channels) => _buildDropdown(
                label: 'Channel',
                value: selectedChannel,
                hint: 'All channels',
                items: channels,
                onChanged: onChannelChanged,
              ),
            ),
          ),
          const SizedBox(width: AdminSpacing.sm),

          // Date range picker
          Expanded(
            child: AdminDateRangePicker(
              label: 'Date Range',
              startDate: startDate,
              endDate: endDate,
              placeholder: 'All time',
              onChanged: onDateRangeChanged,
            ),
          ),

          // Clear all button
          if (hasFilters) ...[
            const SizedBox(width: AdminSpacing.sm),
            IconButton(
              onPressed: onClearAll,
              icon: const Icon(Icons.clear_all, size: 20),
              tooltip: 'Clear all filters',
              style: IconButton.styleFrom(
                foregroundColor: AdminColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AdminTextStyles.labelSmall.copyWith(
            color: AdminColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AdminColors.surface,
            borderRadius: AdminRadius.smAll,
            border: Border.all(color: AdminColors.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: value,
              hint: Text(
                hint,
                style: AdminTextStyles.bodySmall.copyWith(
                  color: AdminColors.textMuted,
                ),
              ),
              isExpanded: true,
              isDense: true,
              icon: Icon(Icons.keyboard_arrow_down,
                  size: 20, color: AdminColors.textMuted),
              dropdownColor: AdminColors.surface,
              style: AdminTextStyles.bodySmall.copyWith(
                color: AdminColors.textPrimary,
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(hint, style: AdminTextStyles.bodySmall),
                ),
                ...items.map((item) => DropdownMenuItem<String?>(
                      value: item,
                      child: Text(
                        item,
                        style: AdminTextStyles.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
