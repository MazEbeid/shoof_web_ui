import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_radius.dart';
import '../theme/admin_spacing.dart';
import '../theme/admin_typography.dart';

/// A modern, compact date range picker that opens as a dropdown
class AdminDateRangePicker extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTimeRange?> onChanged;
  final String? label;
  final String placeholder;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const AdminDateRangePicker({
    super.key,
    this.startDate,
    this.endDate,
    required this.onChanged,
    this.label,
    this.placeholder = 'Select date range',
    this.firstDate,
    this.lastDate,
  });

  @override
  State<AdminDateRangePicker> createState() => _AdminDateRangePickerState();
}

class _AdminDateRangePickerState extends State<AdminDateRangePicker> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  DateTime? _tempStart;
  DateTime? _tempEnd;
  late DateTime _currentMonth;
  
  // Quick select options
  static const _quickOptions = [
    ('Today', 0),
    ('Yesterday', 1),
    ('Last 7 days', 7),
    ('Last 30 days', 30),
    ('Last 90 days', 90),
    ('This month', -1),
    ('Last month', -2),
    ('All time', -99),
  ];

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.startDate ?? DateTime.now();
    _tempStart = widget.startDate;
    _tempEnd = widget.endDate;
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _tempStart = widget.startDate;
    _tempEnd = widget.endDate;
    _currentMonth = widget.startDate ?? DateTime.now();
    
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  void _applySelection() {
    if (_tempStart != null && _tempEnd != null) {
      widget.onChanged(DateTimeRange(start: _tempStart!, end: _tempEnd!));
    }
    _closeDropdown();
  }

  void _clearSelection() {
    widget.onChanged(null);
    _closeDropdown();
  }

  /// Check if the current selection matches a quick option
  int? _getMatchingQuickOption() {
    if (_tempStart == null || _tempEnd == null) return -99; // All time
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Today
    if (_isSameDay(_tempStart!, today) && _isSameDay(_tempEnd!, today)) {
      return 0;
    }
    
    // Yesterday
    final yesterday = today.subtract(const Duration(days: 1));
    if (_isSameDay(_tempStart!, yesterday) && _isSameDay(_tempEnd!, yesterday)) {
      return 1;
    }
    
    // Last 7 days
    final last7 = today.subtract(const Duration(days: 6));
    if (_isSameDay(_tempStart!, last7) && _isSameDay(_tempEnd!, today)) {
      return 7;
    }
    
    // Last 30 days
    final last30 = today.subtract(const Duration(days: 29));
    if (_isSameDay(_tempStart!, last30) && _isSameDay(_tempEnd!, today)) {
      return 30;
    }
    
    // Last 90 days
    final last90 = today.subtract(const Duration(days: 89));
    if (_isSameDay(_tempStart!, last90) && _isSameDay(_tempEnd!, today)) {
      return 90;
    }
    
    // This month
    final thisMonthStart = DateTime(now.year, now.month, 1);
    if (_isSameDay(_tempStart!, thisMonthStart) && _isSameDay(_tempEnd!, today)) {
      return -1;
    }
    
    // Last month
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0);
    if (_isSameDay(_tempStart!, lastMonthStart) && _isSameDay(_tempEnd!, lastMonthEnd)) {
      return -2;
    }
    
    return null; // Custom range
  }

  void _selectQuickOption(int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    DateTime start;
    DateTime end = today;
    
    if (days == 0) {
      // Today
      start = today;
    } else if (days == 1) {
      // Yesterday
      start = today.subtract(const Duration(days: 1));
      end = start;
    } else if (days == -1) {
      // This month
      start = DateTime(now.year, now.month, 1);
    } else if (days == -2) {
      // Last month
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      start = lastMonth;
      end = DateTime(now.year, now.month, 0);
    } else if (days == -99) {
      // All time
      widget.onChanged(null);
      _closeDropdown();
      return;
    } else {
      start = today.subtract(Duration(days: days - 1));
    }
    
    setState(() {
      _tempStart = start;
      _tempEnd = end;
    });
    _overlayEntry?.markNeedsBuild();
  }

  void _selectDate(DateTime date) {
    setState(() {
      if (_tempStart == null || _tempEnd != null) {
        // Start new selection
        _tempStart = date;
        _tempEnd = null;
      } else {
        // Complete selection
        if (date.isBefore(_tempStart!)) {
          _tempEnd = _tempStart;
          _tempStart = date;
        } else {
          _tempEnd = date;
        }
      }
    });
    _overlayEntry?.markNeedsBuild();
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Dropdown
          Positioned(
            width: 520,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 4),
              child: Material(
                elevation: 8,
                borderRadius: AdminRadius.lgAll,
                color: AdminColors.surface,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: AdminRadius.lgAll,
                    border: Border.all(color: AdminColors.divider),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick options
                      Container(
                        width: 140,
                        padding: const EdgeInsets.all(AdminSpacing.md),
                        decoration: BoxDecoration(
                          color: AdminColors.backgroundHover,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Quick Select',
                              style: AdminTextStyles.labelSmall.copyWith(
                                color: AdminColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: AdminSpacing.sm),
                            ..._quickOptions.map((option) {
                              final isSelected = _getMatchingQuickOption() == option.$2;
                              return _QuickOptionButton(
                                label: option.$1,
                                isSelected: isSelected,
                                onTap: () => _selectQuickOption(option.$2),
                              );
                            }),
                          ],
                        ),
                      ),
                      // Calendar
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AdminSpacing.md),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCalendarHeader(),
                              const SizedBox(height: AdminSpacing.md),
                              _buildCalendar(),
                              const SizedBox(height: AdminSpacing.md),
                              _buildFooter(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 20),
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
            });
            _overlayEntry?.markNeedsBuild();
          },
          splashRadius: 16,
        ),
        Text(
          _formatMonth(_currentMonth),
          style: AdminTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 20),
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
            });
            _overlayEntry?.markNeedsBuild();
          },
          splashRadius: 16,
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // 0 = Sunday
    
    final days = <Widget>[];
    
    // Weekday headers
    for (final day in ['S', 'M', 'T', 'W', 'T', 'F', 'S']) {
      days.add(Center(
        child: Text(
          day,
          style: AdminTextStyles.labelSmall.copyWith(color: AdminColors.textMuted),
        ),
      ));
    }
    
    // Empty cells before first day
    for (var i = 0; i < startWeekday; i++) {
      days.add(const SizedBox());
    }
    
    // Day cells
    for (var day = 1; day <= lastDay.day; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isSelected = _isDateSelected(date);
      final isInRange = _isDateInRange(date);
      final isRangeStart = _tempStart != null && _isSameDay(date, _tempStart!);
      final isRangeEnd = _tempEnd != null && _isSameDay(date, _tempEnd!);
      final isToday = _isSameDay(date, DateTime.now());
      
      days.add(_DayCell(
        day: day,
        isSelected: isSelected,
        isInRange: isInRange,
        isRangeStart: isRangeStart,
        isRangeEnd: isRangeEnd,
        isToday: isToday,
        onTap: () => _selectDate(date),
      ));
    }
    
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 7,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      childAspectRatio: 1.3,
      physics: const NeverScrollableScrollPhysics(),
      children: days,
    );
  }

  Widget _buildFooter() {
    final hasSelection = _tempStart != null && _tempEnd != null;
    
    return Row(
      children: [
        if (hasSelection)
          Expanded(
            child: Text(
              '${_formatDate(_tempStart!)} - ${_formatDate(_tempEnd!)}',
              style: AdminTextStyles.bodySmall,
            ),
          )
        else
          Expanded(
            child: Text(
              _tempStart != null ? 'Select end date' : 'Select start date',
              style: AdminTextStyles.bodySmall.copyWith(color: AdminColors.textMuted),
            ),
          ),
        TextButton(
          onPressed: _clearSelection,
          child: Text('Clear', style: TextStyle(color: AdminColors.textMuted)),
        ),
        const SizedBox(width: AdminSpacing.sm),
        ElevatedButton(
          onPressed: hasSelection ? _applySelection : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }

  bool _isDateSelected(DateTime date) {
    return (_tempStart != null && _isSameDay(date, _tempStart!)) ||
           (_tempEnd != null && _isSameDay(date, _tempEnd!));
  }

  bool _isDateInRange(DateTime date) {
    if (_tempStart == null || _tempEnd == null) return false;
    return date.isAfter(_tempStart!) && date.isBefore(_tempEnd!);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatMonth(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String get _displayText {
    if (widget.startDate == null || widget.endDate == null) {
      return widget.placeholder;
    }
    
    // Check if it matches a quick option
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = widget.startDate!;
    final end = widget.endDate!;
    
    // Today
    if (_isSameDay(start, today) && _isSameDay(end, today)) {
      return 'Today';
    }
    
    // Yesterday
    final yesterday = today.subtract(const Duration(days: 1));
    if (_isSameDay(start, yesterday) && _isSameDay(end, yesterday)) {
      return 'Yesterday';
    }
    
    // Last 7 days
    final last7 = today.subtract(const Duration(days: 6));
    if (_isSameDay(start, last7) && _isSameDay(end, today)) {
      return 'Last 7 days';
    }
    
    // Last 30 days
    final last30 = today.subtract(const Duration(days: 29));
    if (_isSameDay(start, last30) && _isSameDay(end, today)) {
      return 'Last 30 days';
    }
    
    // Last 90 days
    final last90 = today.subtract(const Duration(days: 89));
    if (_isSameDay(start, last90) && _isSameDay(end, today)) {
      return 'Last 90 days';
    }
    
    // This month
    final thisMonthStart = DateTime(now.year, now.month, 1);
    if (_isSameDay(start, thisMonthStart) && _isSameDay(end, today)) {
      return 'This month';
    }
    
    // Last month
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0);
    if (_isSameDay(start, lastMonthStart) && _isSameDay(end, lastMonthEnd)) {
      return 'Last month';
    }
    
    // Custom range - show dates
    return '${_formatDate(start)} - ${_formatDate(end)}';
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.startDate != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AdminTextStyles.labelSmall.copyWith(color: AdminColors.textMuted),
          ),
          const SizedBox(height: 4),
        ],
        CompositedTransformTarget(
          link: _layerLink,
          child: InkWell(
            onTap: _toggleDropdown,
            borderRadius: AdminRadius.smAll,
            child: Container(
              height: 48, // Match DropdownButton height
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AdminColors.surface,
                borderRadius: AdminRadius.smAll,
                border: Border.all(
                  color: _isOpen ? AdminColors.primary : AdminColors.divider,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: hasValue ? AdminColors.primary : AdminColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _displayText,
                      style: AdminTextStyles.bodySmall.copyWith(
                        color: hasValue ? AdminColors.textPrimary : AdminColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: AdminColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickOptionButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickOptionButton({
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AdminRadius.smAll,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AdminColors.primary.withOpacity(0.15) : null,
          borderRadius: AdminRadius.smAll,
        ),
        child: Row(
          children: [
            if (isSelected) ...[
              Icon(
                Icons.check,
                size: 14,
                color: AdminColors.primary,
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                label,
                style: AdminTextStyles.bodySmall.copyWith(
                  color: isSelected ? AdminColors.primary : null,
                  fontWeight: isSelected ? FontWeight.w600 : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isSelected;
  final bool isInRange;
  final bool isRangeStart;
  final bool isRangeEnd;
  final bool isToday;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isInRange,
    required this.isRangeStart,
    required this.isRangeEnd,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? backgroundColor;
    Color textColor = AdminColors.textPrimary;
    BorderRadius? borderRadius;
    
    if (isSelected) {
      backgroundColor = AdminColors.primary;
      textColor = Colors.white;
      borderRadius = BorderRadius.circular(6);
    } else if (isInRange) {
      backgroundColor = AdminColors.primary.withOpacity(0.15);
    }
    
    // Handle range edges
    if (isRangeStart && !isRangeEnd) {
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(6),
        bottomLeft: Radius.circular(6),
      );
    } else if (isRangeEnd && !isRangeStart) {
      borderRadius = const BorderRadius.only(
        topRight: Radius.circular(6),
        bottomRight: Radius.circular(6),
      );
    }
    
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
          border: isToday && !isSelected
              ? Border.all(color: AdminColors.primary, width: 1)
              : null,
        ),
        child: Center(
          child: Text(
            day.toString(),
            style: AdminTextStyles.bodySmall.copyWith(
              color: textColor,
              fontWeight: isSelected || isToday ? FontWeight.w600 : null,
            ),
          ),
        ),
      ),
    );
  }
}

