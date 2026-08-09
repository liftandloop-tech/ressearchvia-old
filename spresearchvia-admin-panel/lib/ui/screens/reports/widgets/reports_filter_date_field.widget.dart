import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class ReportsFilterDateField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onChanged;

  const ReportsFilterDateField({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        if (picked != null) {
          final String formattedDate =
              '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
          controller.text = formattedDate;
          if (onChanged != null) onChanged!();
        }
      },
      decoration: InputDecoration(
        hintText: 'mm/dd/yyyy',
        hintStyle: TextStyle(color: AppTheme.gray300),
        suffixIcon: Icon(
          Icons.calendar_today,
          size: 18,
          color: AppTheme.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: AppTheme.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: AppTheme.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: AppTheme.primaryBlue),
        ),
      ),
      style: const TextStyle(fontSize: 14),
    );
  }
}
