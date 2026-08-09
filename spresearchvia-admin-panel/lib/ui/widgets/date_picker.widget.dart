import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/controllers/common/date_picker.controller.dart';
import 'calendar_view.widget.dart';

class DatePickerDialog extends StatelessWidget {
  final String title;
  final DateTime? initialDate;
  final Function(DateTime) onConfirm;

  const DatePickerDialog({
    super.key,
    this.title = 'Calendar Title',
    this.initialDate,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DatePickerController());
    controller.initialize(initialDate);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                  .map(
                    (day) => SizedBox(
                      width: 40,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            CalendarView(controller: controller),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  onConfirm(controller.selectedDate.value);
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showCustomDatePicker({
  required BuildContext context,
  String title = 'Calendar Title',
  DateTime? initialDate,
  required Function(DateTime) onConfirm,
}) {
  showDialog(
    context: context,
    builder: (context) => DatePickerDialog(
      title: title,
      initialDate: initialDate,
      onConfirm: onConfirm,
    ),
  );
}
