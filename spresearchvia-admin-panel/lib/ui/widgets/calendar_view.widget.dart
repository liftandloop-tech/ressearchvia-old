import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/controllers/common/date_picker.controller.dart';

class CalendarView extends StatelessWidget {
  final DatePickerController controller;

  const CalendarView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final displayMonth = controller.displayMonth.value;
      final selectedDate = controller.selectedDate.value;
      final firstDayOfMonth = DateTime(
        displayMonth.year,
        displayMonth.month,
        1,
      );
      final lastDayOfMonth = DateTime(
        displayMonth.year,
        displayMonth.month + 1,
        0,
      );
      final daysInMonth = lastDayOfMonth.day;
      final startWeekday = firstDayOfMonth.weekday % 7;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${_getMonthName(displayMonth.month)} ${displayMonth.year}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              ...List.generate(
                startWeekday,
                (_) => const SizedBox(width: 40, height: 40),
              ),
              ...List.generate(daysInMonth, (index) {
                final day = index + 1;
                final date = DateTime(
                  displayMonth.year,
                  displayMonth.month,
                  day,
                );
                final isSelected =
                    date.year == selectedDate.year &&
                    date.month == selectedDate.month &&
                    date.day == selectedDate.day;
                final isToday =
                    date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;

                return GestureDetector(
                  onTap: () => controller.selectDate(date),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0066FF)
                          : (isToday
                                ? const Color(0xFFE3F2FD)
                                : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? Colors.white : Colors.black,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      );
    });
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
