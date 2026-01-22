import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_radius.dart';
import '../theme/admin_spacing.dart';
import '../theme/admin_typography.dart';
import '../theme/admin_decorations.dart';
import '../theme/admin_durations.dart';
import '../theme/admin_button_styles.dart';
import 'admin_card.dart';

/// Column definition for AdminDataTable
class AdminTableColumn {
  final String label;
  final double? width;
  final bool sortable;
  final TextAlign textAlign;

  const AdminTableColumn({
    required this.label,
    this.width,
    this.sortable = false,
    this.textAlign = TextAlign.left,
  });
}

/// A modern data table widget using the V2 design system.
class AdminDataTable extends HookConsumerWidget {
  final String? title;
  final List<AdminTableColumn> columns;
  final List<List<Widget>> rows;
  final int rowsPerPage;
  final bool showSearch;
  final bool showFilters;
  final String? searchHint;
  final Function(String)? onSearch;
  final List<Widget>? filterWidgets;
  final List<Widget>? actions;
  final String? emptyMessage;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final Function(int, bool)? onSort;
  final int? sortColumnIndex;
  final bool sortAscending;

  const AdminDataTable({
    super.key,
    this.title,
    required this.columns,
    required this.rows,
    this.rowsPerPage = 10,
    this.showSearch = true,
    this.showFilters = false,
    this.searchHint,
    this.onSearch,
    this.filterWidgets,
    this.actions,
    this.emptyMessage,
    this.isLoading = false,
    this.onRefresh,
    this.onSort,
    this.sortColumnIndex,
    this.sortAscending = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = useState(0);
    final searchController = useTextEditingController();

    // Calculate pagination
    final totalPages = (rows.length / rowsPerPage).ceil();
    final startIndex = currentPage.value * rowsPerPage;
    final endIndex = (startIndex + rowsPerPage).clamp(0, rows.length);
    final displayedRows = rows.sublist(startIndex, endIndex);

    return Container(
      decoration: AdminDecorations.tableContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with title, search, filters, and actions
          _buildHeader(context, searchController),

          // Filter chips row
          if (showFilters && filterWidgets != null && filterWidgets!.isNotEmpty)
            _buildFiltersRow(),

          // Table
          if (isLoading)
            const Expanded(child: AdminLoadingState(message: 'Loading data...'))
          else if (rows.isEmpty)
            Expanded(
              child: AdminEmptyState(
                title: emptyMessage ?? 'No data found',
                subtitle: 'Try adjusting your search or filters.',
                action: onRefresh != null
                    ? ElevatedButton.icon(
                        style: AdminButtonStyles.primary,
                        onPressed: onRefresh,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Refresh'),
                      )
                    : null,
              ),
            )
          else
            Expanded(
              child: _buildTable(displayedRows),
            ),

          // Pagination
          if (rows.isNotEmpty)
            _buildPagination(currentPage, totalPages, startIndex, endIndex),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    TextEditingController searchController,
  ) {
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AdminColors.divider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Title
              if (title != null)
                Text(
                  title!,
                  style: AdminTextStyles.cardTitle,
                ),

              const Spacer(),

              // Search
              if (showSearch)
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearch,
                    style: AdminTextStyles.bodyMedium,
                    decoration: AdminDecorations.inputDecoration(
                      hint: searchHint ?? 'Search...',
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 20,
                        color: AdminColors.textMuted,
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                size: 18,
                                color: AdminColors.textMuted,
                              ),
                              onPressed: () {
                                searchController.clear();
                                onSearch?.call('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),

              // Actions
              if (actions != null) ...[
                const SizedBox(width: AdminSpacing.md),
                ...actions!,
              ],

              // Refresh button
              if (onRefresh != null)
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  color: AdminColors.textSecondary,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.lg,
        vertical: AdminSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AdminColors.backgroundHover,
        border: Border(
          bottom: BorderSide(color: AdminColors.divider),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_list,
            size: 18,
            color: AdminColors.textSecondary,
          ),
          const SizedBox(width: AdminSpacing.sm),
          Text(
            'Filters:',
            style: AdminTextStyles.labelMedium,
          ),
          const SizedBox(width: AdminSpacing.md),
          Expanded(
            child: Wrap(
              spacing: AdminSpacing.sm,
              runSpacing: AdminSpacing.sm,
              children: filterWidgets!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<List<Widget>> displayedRows) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Container(
            color: AdminColors.tableHeader,
            padding: const EdgeInsets.symmetric(
              horizontal: AdminSpacing.lg,
              vertical: AdminSpacing.md,
            ),
            child: Row(
              children: columns.asMap().entries.map((entry) {
                final index = entry.key;
                final column = entry.value;
                final isLast = index == columns.length - 1;

                return Expanded(
                  flex: column.width != null ? 0 : 1,
                  child: Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : AdminSpacing.md),
                    child: SizedBox(
                      width: column.width,
                      child: Align(
                        alignment: _getAlignment(column.textAlign),
                        child: InkWell(
                          onTap: column.sortable && onSort != null
                              ? () => onSort!(
                                  index,
                                  sortColumnIndex == index
                                      ? !sortAscending
                                      : true)
                              : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  column.label,
                                  style: AdminTextStyles.tableHeader,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (column.sortable) ...[
                                const SizedBox(width: AdminSpacing.xs),
                                Icon(
                                  sortColumnIndex == index
                                      ? (sortAscending
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward)
                                      : Icons.unfold_more,
                                  size: 14,
                                  color: sortColumnIndex == index
                                      ? AdminColors.primary
                                      : AdminColors.textMuted,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Data rows
          ...displayedRows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;

            return _buildDataRow(row, index);
          }),
        ],
      ),
    );
  }

  Widget _buildDataRow(List<Widget> cells, int index) {
    return Material(
      color: index.isEven
          ? AdminColors.tableRowEven
          : AdminColors.tableRowOdd,
      child: InkWell(
        onTap: null, // Can be made interactive
        hoverColor: AdminColors.tableRowHover,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AdminSpacing.lg,
            vertical: AdminSpacing.md,
          ),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AdminColors.divider, width: 0.5),
            ),
          ),
          child: Row(
            children: cells.asMap().entries.map((entry) {
              final cellIndex = entry.key;
              final cell = entry.value;
              final column = columns.length > cellIndex
                  ? columns[cellIndex]
                  : const AdminTableColumn(label: '');
              final isLast = cellIndex == cells.length - 1;

              return Expanded(
                flex: column.width != null ? 0 : 1,
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : AdminSpacing.md),
                  child: SizedBox(
                    width: column.width,
                    child: Align(
                      alignment: _getAlignment(column.textAlign),
                      child: cell,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(
    ValueNotifier<int> currentPage,
    int totalPages,
    int startIndex,
    int endIndex,
  ) {
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AdminColors.divider),
        ),
      ),
      child: Row(
        children: [
          // Showing X - Y of Z
          Text(
            'Showing ${startIndex + 1} - $endIndex of ${rows.length}',
            style: AdminTextStyles.bodySmall,
          ),

          const Spacer(),

          // Page navigation
          Row(
            children: [
              // Previous button
              IconButton(
                onPressed: currentPage.value > 0
                    ? () => currentPage.value--
                    : null,
                icon: const Icon(Icons.chevron_left),
                iconSize: 20,
                color: currentPage.value > 0
                    ? AdminColors.textSecondary
                    : AdminColors.textMuted,
              ),

              // Page numbers
              ...List.generate(
                totalPages.clamp(0, 5),
                (index) {
                  final pageIndex = _getPageIndex(
                    currentPage.value,
                    totalPages,
                    index,
                  );
                  final isActive = pageIndex == currentPage.value;

                  return GestureDetector(
                    onTap: () => currentPage.value = pageIndex,
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.symmetric(
                        horizontal: AdminSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AdminColors.primary
                            : Colors.transparent,
                        borderRadius: AdminRadius.smAll,
                      ),
                      child: Center(
                        child: Text(
                          '${pageIndex + 1}',
                          style: AdminTextStyles.buttonSmall.copyWith(
                            color: isActive
                                ? AdminColors.textOnPrimary
                                : AdminColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Next button
              IconButton(
                onPressed: currentPage.value < totalPages - 1
                    ? () => currentPage.value++
                    : null,
                icon: const Icon(Icons.chevron_right),
                iconSize: 20,
                color: currentPage.value < totalPages - 1
                    ? AdminColors.textSecondary
                    : AdminColors.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getPageIndex(int currentPage, int totalPages, int index) {
    // Handle pagination display for large page counts
    if (totalPages <= 5) {
      return index;
    }

    if (currentPage <= 2) {
      return index;
    }

    if (currentPage >= totalPages - 3) {
      return totalPages - 5 + index;
    }

    return currentPage - 2 + index;
  }

  Alignment _getAlignment(TextAlign textAlign) {
    switch (textAlign) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      case TextAlign.left:
      case TextAlign.start:
      default:
        return Alignment.centerLeft;
    }
  }
}

/// A filter chip widget for table filters
class AdminFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const AdminFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AdminColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AdminRadius.fullAll,
        child: AnimatedContainer(
          duration: AdminDurations.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: AdminSpacing.md,
            vertical: AdminSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected ? chipColor : Colors.transparent,
            borderRadius: AdminRadius.fullAll,
            border: Border.all(
              color: isSelected ? chipColor : AdminColors.border,
            ),
          ),
          child: Text(
            label,
            style: AdminTextStyles.labelMedium.copyWith(
              color: isSelected
                  ? AdminColors.textOnPrimary
                  : AdminColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

