import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../data/widget_data_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';
import '../admin_date_range_picker.dart';

/// Reusable filter row for dashboard widgets
/// Includes: City dropdown, Channel dropdown, Date range picker.
///
/// Widgets showing SKU data can opt into company/brand/package/size dropdowns
/// by passing the corresponding onChanged callbacks; option lists come from
/// fn_availability_dimensions via [skuDimensionsProvider].
class WidgetFiltersRow extends ConsumerWidget {
  final String missionId;
  final String? selectedCity;
  final String? selectedChannel;
  final String? selectedCompany;
  final String? selectedBrand;
  final String? selectedPackage;
  final String? selectedSize;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<String?> onCityChanged;
  final ValueChanged<String?> onChannelChanged;
  final ValueChanged<String?>? onCompanyChanged;
  final ValueChanged<String?>? onBrandChanged;
  final ValueChanged<String?>? onPackageChanged;
  final ValueChanged<String?>? onSizeChanged;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;
  final VoidCallback? onClearAll;
  final bool hasFilters;

  const WidgetFiltersRow({
    super.key,
    required this.missionId,
    this.selectedCity,
    this.selectedChannel,
    this.selectedCompany,
    this.selectedBrand,
    this.selectedPackage,
    this.selectedSize,
    this.startDate,
    this.endDate,
    required this.onCityChanged,
    required this.onChannelChanged,
    this.onCompanyChanged,
    this.onBrandChanged,
    this.onPackageChanged,
    this.onSizeChanged,
    required this.onDateRangeChanged,
    this.onClearAll,
    this.hasFilters = false,
  });

  bool get _wantsSkuDims =>
      onCompanyChanged != null ||
      onBrandChanged != null ||
      onPackageChanged != null ||
      onSizeChanged != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citiesAsync = ref.watch(missionCitiesProvider(missionId));
    final channelsAsync = ref.watch(missionChannelsProvider(missionId));
    final dims = _wantsSkuDims
        ? ref.watch(skuDimensionsProvider(missionId)).valueOrNull
        : null;

    return Container(
      padding: const EdgeInsets.all(AdminSpacing.sm),
      decoration: BoxDecoration(
        color: AdminColors.backgroundHover,
        borderRadius: AdminRadius.smAll,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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

          // SKU dimension dropdowns (opt-in per widget)
          if (dims != null &&
              (dims.companies.isNotEmpty ||
                  dims.brands.isNotEmpty ||
                  dims.packages.isNotEmpty ||
                  dims.sizes.isNotEmpty)) ...[
            const SizedBox(height: AdminSpacing.sm),
            Wrap(
              spacing: AdminSpacing.sm,
              runSpacing: AdminSpacing.sm,
              children: [
                if (onCompanyChanged != null && dims.companies.isNotEmpty)
                  SizedBox(
                    width: 170,
                    child: _buildDropdown(
                      label: 'Company',
                      value: selectedCompany,
                      hint: 'All companies',
                      items: dims.companies,
                      onChanged: onCompanyChanged!,
                    ),
                  ),
                if (onBrandChanged != null && dims.brands.isNotEmpty)
                  SizedBox(
                    width: 170,
                    child: _buildDropdown(
                      label: 'Brand',
                      value: selectedBrand,
                      hint: 'All brands',
                      items: dims.brands,
                      onChanged: onBrandChanged!,
                    ),
                  ),
                if (onPackageChanged != null && dims.packages.isNotEmpty)
                  SizedBox(
                    width: 150,
                    child: _buildDropdown(
                      label: 'Package',
                      value: selectedPackage,
                      hint: 'All packages',
                      items: dims.packages,
                      onChanged: onPackageChanged!,
                    ),
                  ),
                if (onSizeChanged != null && dims.sizes.isNotEmpty)
                  SizedBox(
                    width: 130,
                    child: _buildDropdown(
                      label: 'Size',
                      value: selectedSize,
                      hint: 'All sizes',
                      items: dims.sizes,
                      onChanged: onSizeChanged!,
                    ),
                  ),
              ],
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
