import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spresearch_web/config/theme.config.dart';

class CompactDateRangePickerDialog extends StatefulWidget {
  final DateTimeRange? initialDateRange;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;

  const CompactDateRangePickerDialog({
    super.key,
    this.initialDateRange,
    required this.firstDate,
    required this.lastDate,
    this.title = 'Select Date Range',
  });

  @override
  State<CompactDateRangePickerDialog> createState() =>
      _CompactDateRangePickerDialogState();
}

class _CompactDateRangePickerDialogState
    extends State<CompactDateRangePickerDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  late DateTime _displayMonth;
  String? _activePreset;

  @override
  void initState() {
    super.initState();
    if (widget.initialDateRange != null) {
      _startDate = DateTime(
        widget.initialDateRange!.start.year,
        widget.initialDateRange!.start.month,
        widget.initialDateRange!.start.day,
      );
      _endDate = DateTime(
        widget.initialDateRange!.end.year,
        widget.initialDateRange!.end.month,
        widget.initialDateRange!.end.day,
      );
      _displayMonth = DateTime(_endDate!.year, _endDate!.month, 1);
    } else {
      final now = DateTime.now();
      _displayMonth = DateTime(now.year, now.month, 1);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _applyPreset(String presetName) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime start;
    DateTime end;

    switch (presetName) {
      case 'Today':
        start = today;
        end = today;
        break;
      case 'Yesterday':
        final y = today.subtract(const Duration(days: 1));
        start = y;
        end = y;
        break;
      case 'Last 7 Days':
        start = today.subtract(const Duration(days: 6));
        end = today;
        break;
      case 'Last 30 Days':
        start = today.subtract(const Duration(days: 29));
        end = today;
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        end = today;
        break;
      case 'Last Month':
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0);
        break;
      default:
        return;
    }

    setState(() {
      _startDate = start;
      _endDate = end;
      _displayMonth = DateTime(end.year, end.month, 1);
      _activePreset = presetName;
    });
  }

  void _onDayTapped(DateTime day) {
    setState(() {
      _activePreset = null;
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        _startDate = day;
        _endDate = null;
      } else {
        if (day.isBefore(_startDate!)) {
          _startDate = day;
        } else {
          _endDate = day;
        }
      }
    });
  }

  void _prevMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 1);
    });
  }

  void _reset() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _activePreset = null;
      final now = DateTime.now();
      _displayMonth = DateTime(now.year, now.month, 1);
    });
  }

  void _submit() {
    if (_startDate == null) return;
    final end = _endDate ?? _startDate!;
    final range = DateTimeRange(
      start: DateTime(_startDate!.year, _startDate!.month, _startDate!.day),
      end: DateTime(end.year, end.month, end.day, 23, 59, 59, 999),
    );
    Navigator.of(context).pop(range);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final firstDayOfMonth = DateTime(
      _displayMonth.year,
      _displayMonth.month,
      1,
    );
    final daysInMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7; // Sunday is 0

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 370,
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header: Title + Close Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    size: 16,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.gray100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppTheme.gray600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Quick Preset Chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildPresetChip('Today'),
                _buildPresetChip('Yesterday'),
                _buildPresetChip('Last 7 Days'),
                _buildPresetChip('Last 30 Days'),
                _buildPresetChip('This Month'),
                _buildPresetChip('Last Month'),
              ],
            ),
            const SizedBox(height: 12),

            // Active Range Summary Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.gray200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'START DATE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppTheme.gray500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _startDate != null
                              ? DateFormat('dd MMM yyyy').format(_startDate!)
                              : 'Select date',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _startDate != null
                                ? AppTheme.primaryBlue
                                : AppTheme.gray400,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppTheme.gray400,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'END DATE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppTheme.gray500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _endDate != null
                              ? DateFormat('dd MMM yyyy').format(_endDate!)
                              : (_startDate != null
                                  ? 'Select end date'
                                  : 'Select date'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _endDate != null
                                ? AppTheme.primaryBlue
                                : AppTheme.gray400,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_startDate != null && _endDate != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_endDate!.difference(_startDate!).inDays + 1}d',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryBlue,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Month Navigation Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  onPressed: _prevMonth,
                  color: AppTheme.gray700,
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_displayMonth),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  onPressed: _nextMonth,
                  color: AppTheme.gray700,
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Day of Week Header
            Row(
              children: const ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.gray400,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 6),

            // Calendar Grid
            _buildCalendarGrid(startWeekday, daysInMonth, today),
            const SizedBox(height: 16),

            // Footer Actions
            Row(
              children: [
                TextButton.icon(
                  onPressed: (_startDate != null || _endDate != null) ? _reset : null,
                  icon: const Icon(Icons.refresh_rounded, size: 13),
                  label: const Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.gray500,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.gray300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.gray700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _startDate != null ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.35),
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text(
                    'Apply Range',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label) {
    final isSelected = _activePreset == label;
    return InkWell(
      onTap: () => _applyPreset(label),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.gray700,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(int startWeekday, int daysInMonth, DateTime today) {
    final totalCells = startWeekday + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rowCount, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: Row(
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              if (cellIndex < startWeekday || cellIndex >= totalCells) {
                return const Expanded(child: SizedBox(height: 32));
              }

              final dayNum = cellIndex - startWeekday + 1;
              final cellDate = DateTime(
                _displayMonth.year,
                _displayMonth.month,
                dayNum,
              );

              final isStart =
                  _startDate != null && _isSameDay(cellDate, _startDate!);
              final isEnd =
                  _endDate != null && _isSameDay(cellDate, _endDate!);
              final isBetween = _startDate != null &&
                  _endDate != null &&
                  cellDate.isAfter(_startDate!) &&
                  cellDate.isBefore(_endDate!);
              final isToday = _isSameDay(cellDate, today);

              final isDisabled = cellDate.isBefore(widget.firstDate) ||
                  cellDate.isAfter(widget.lastDate);

              return Expanded(
                child: GestureDetector(
                  onTap: isDisabled ? null : () => _onDayTapped(cellDate),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    height: 32,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Range highlight background strip
                        if (isBetween)
                          Positioned.fill(
                            child: Container(
                              color: const Color(0xFFEFF6FF),
                            ),
                          ),
                        if (isStart && _endDate != null && !isEnd)
                          Positioned(
                            left: 16,
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              color: const Color(0xFFEFF6FF),
                            ),
                          ),
                        if (isEnd && _startDate != null && !isStart)
                          Positioned(
                            left: 0,
                            right: 16,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              color: const Color(0xFFEFF6FF),
                            ),
                          ),

                        // Day Circle / Pill
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (isStart || isEnd)
                                ? AppTheme.primaryBlue
                                : Colors.transparent,
                            border: (!isStart && !isEnd && isToday)
                                ? Border.all(
                                    color: AppTheme.primaryBlue,
                                    width: 1.2,
                                  )
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$dayNum',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: (isStart || isEnd || isToday)
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: (isStart || isEnd)
                                  ? Colors.white
                                  : (isDisabled
                                      ? AppTheme.gray300
                                      : (isBetween
                                          ? AppTheme.primaryBlue
                                          : AppTheme.textPrimary)),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

/// Helper function to open the sleek, compact SaaS-style date range picker dialog.
Future<DateTimeRange?> showCompactDateRangePicker({
  required BuildContext context,
  DateTimeRange? initialDateRange,
  DateTime? firstDate,
  DateTime? lastDate,
  String title = 'Select Date Range',
}) {
  return showDialog<DateTimeRange>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) => CompactDateRangePickerDialog(
      initialDateRange: initialDateRange,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
      title: title,
    ),
  );
}
