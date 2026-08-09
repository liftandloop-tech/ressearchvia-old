import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/user.controller.dart';
import 'package:spresearch_web/ui/widgets/date_picker.widget.dart';

class FilterDateField extends StatelessWidget {
  final String label;
  final UserController controller;

  const FilterDateField({
    super.key,
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => InkWell(
            onTap: () {
              showCustomDatePicker(
                context: context,
                title: 'Select Date',
                onConfirm: (date) {
                  controller.registrationDateFilter.value =
                      '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
                  // Removed immediate applyFilters() to allow batch filtering
                },
              );
            },
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.gray300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.registrationDateFilter.value.isEmpty
                          ? 'mm/dd/yyyy'
                          : controller.registrationDateFilter.value,
                      style: TextStyle(
                        fontSize: 13,
                        color: controller.registrationDateFilter.value.isEmpty
                            ? AppTheme.gray400
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Icon(Icons.calendar_today, size: 16, color: AppTheme.gray600),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
