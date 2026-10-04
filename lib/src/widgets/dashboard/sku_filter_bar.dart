import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../data/cities_constants.dart';
import '../../data/widget_data_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';
import '../admin_date_range_picker.dart';

/// Bundled filter state for [SkuFilterBar]. Create with [useSkuFilters()]
/// inside a HookWidget build method; pass to the bar and read
/// [params] to feed data providers:
///
/// ```dart
/// final filters = useSkuFilters();
/// final params = filters.params(missionId);
/// ...
/// SkuFilterBar(missionId: missionId, filters: filters),
/// ```
class SkuFilters {
  final ValueNotifier<String?> city;
  final ValueNotifier<String?> region;
  final ValueNotifier<String?> channel;
  final ValueNotifier<String?> company;
  final ValueNotifier<String?> brand;
  final ValueNotifier<String?> package;
  final ValueNotifier<String?> size;
  final ValueNotifier<DateTime?> startDate;
  final ValueNotifier<DateTime?> endDate;

  const SkuFilters({
    required this.city,
    required this.region,
    required this.channel,
    required this.company,
    required this.brand,
    required this.package,
    required this.size,
    required this.startDate,
    required this.endDate,
  });

  WidgetFilterParams params(String missionId) => WidgetFilterParams(
        missionId: missionId,
        company: company.value,
        brand: brand.value,
        package: package.value,
        size: size.value,
        city: city.value,
        region: region.value,
        channel: channel.value,
        startDate: startDate.value,
        endDate: endDate.value,
      );

  bool get hasFilters =>
      city.value != null ||
      region.value != null ||
      channel.value != null ||
      company.value != null ||
      brand.value != null ||
      package.value != null ||
      size.value != null ||
      startDate.value != null ||
      endDate.value != null;

  void clear() {
    city.value = null;
    region.value = null;
    channel.value = null;
    company.value = null;
    brand.value = null;
    package.value = null;
    size.value = null;
    startDate.value = null;
    endDate.value = null;
  }
}

/// Creates the full filter state bundle for [SkuFilterBar].
SkuFilters useSkuFilters() {
  return SkuFilters(
    city: useState<String?>(null),
    region: useState<String?>(null),
    channel: useState<String?>(null),
    company: useState<String?>(null),
    brand: useState<String?>(null),
    package: useState<String?>(null),
    size: useState<String?>(null),
    startDate: useState<DateTime?>(null),
    endDate: useState<DateTime?>(null),
  );
}

/// The standard dashboard-widget filter bar (the layout from Availability
/// Analysis, user-preferred): one unified block with City / Channel /
/// Date range on top and Company / Brand / Package / Size dropdowns below.
///
/// SKU dimension option lists come from fn_availability_dimensions via
/// [skuDimensionsProvider]; pass [showSkuDims] = false for widgets whose
/// data has no SKU dimensions (e.g. coverage map, mission overview).
class SkuFilterBar extends ConsumerWidget {
  final String missionId;
  final SkuFilters filters;
  final bool showSkuDims;

  /// Replace the City dropdown with a Region dropdown (Cairo / Alexandria /
  /// Delta / Suez Canal / Upper Egypt / Unknown region). Region options are
  /// derived from the mission's cities via cities_constants; selection is
  /// resolved back to city lists by the data providers.
  final bool regionInsteadOfCity;

  /// Date-range hint when nothing is picked. Widgets with an implicit
  /// default window (e.g. Price Monitor's 8 weeks) override this so the
  /// filter never claims "All time" while showing a bounded window.
  final String dateRangePlaceholder;

  const SkuFilterBar({
    super.key,
    required this.missionId,
    required this.filters,
    this.showSkuDims = true,
    this.regionInsteadOfCity = false,
    this.dateRangePlaceholder = 'All time',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citiesAsync = ref.watch(missionCitiesProvider(missionId));
    final channelsAsync = ref.watch(missionChannelsProvider(missionId));
    final dims = showSkuDims
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
              // City (or Region) dropdown
              Expanded(
                child: citiesAsync.when(
                  loading: () => _buildDropdown(
                    label: regionInsteadOfCity ? 'Region' : 'City',
                    hint: 'Loading...',
                    items: const [],
                    onChanged: (_) {},
                  ),
                  error: (_, __) => _buildDropdown(
                    label: regionInsteadOfCity ? 'Region' : 'City',
                    hint: 'Error',
                    items: const [],
                    onChanged: (_) {},
                  ),
                  data: (cities) => regionInsteadOfCity
                      ? _buildDropdown(
                          label: 'Region',
                          value: filters.region.value,
                          hint: 'All regions',
                          items: regionsForCities(cities),
                          onChanged: (v) => filters.region.value = v,
                        )
                      : _buildDropdown(
                          label: 'City',
                          value: filters.city.value,
                          hint: 'All cities',
                          items: cities,
                          onChanged: (v) => filters.city.value = v,
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
                    value: filters.channel.value,
                    hint: 'All channels',
                    items: channels,
                    onChanged: (v) => filters.channel.value = v,
                  ),
                ),
              ),
              const SizedBox(width: AdminSpacing.sm),

              // Date range picker
              Expanded(
                child: AdminDateRangePicker(
                  label: 'Date Range',
                  startDate: filters.startDate.value,
                  endDate: filters.endDate.value,
                  placeholder: dateRangePlaceholder,
                  onChanged: (range) {
                    filters.startDate.value = range?.start;
                    filters.endDate.value = range?.end;
                  },
                ),
              ),

              // Clear all button
              if (filters.hasFilters) ...[
                const SizedBox(width: AdminSpacing.sm),
                IconButton(
                  onPressed: filters.clear,
                  icon: const Icon(Icons.clear_all, size: 20),
                  tooltip: 'Clear all filters',
                  style: IconButton.styleFrom(
                    foregroundColor: AdminColors.textMuted,
                  ),
                ),
              ],
            ],
          ),

          // SKU dimension dropdowns
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
                if (dims.companies.isNotEmpty)
                  SizedBox(
                    width: 170,
                    child: _buildDropdown(
                      label: 'Company',
                      value: filters.company.value,
                      hint: 'All companies',
                      items: dims.companies,
                      onChanged: (v) => filters.company.value = v,
                    ),
                  ),
                if (dims.brands.isNotEmpty)
                  SizedBox(
                    width: 170,
                    child: _buildDropdown(
                      label: 'Brand',
                      value: filters.brand.value,
                      hint: 'All brands',
                      items: dims.brands,
                      onChanged: (v) => filters.brand.value = v,
                    ),
                  ),
                if (dims.packages.isNotEmpty)
                  SizedBox(
                    width: 150,
                    child: _buildDropdown(
                      label: 'Package',
                      value: filters.package.value,
                      hint: 'All packages',
                      items: dims.packages,
                      onChanged: (v) => filters.package.value = v,
                    ),
                  ),
                if (dims.sizes.isNotEmpty)
                  SizedBox(
                    width: 130,
                    child: _buildDropdown(
                      label: 'Size',
                      value: filters.size.value,
                      hint: 'All sizes',
                      items: dims.sizes,
                      onChanged: (v) => filters.size.value = v,
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
