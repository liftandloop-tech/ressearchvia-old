import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class PlanTextField extends StatelessWidget {
  final String? label;
  final TextEditingController controller;
  final String hint;
  final bool required;

  const PlanTextField({
    super.key,
    this.label,
    required this.controller,
    required this.hint,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: AppTheme.gray400),
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
          borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      style: TextStyle(fontSize: 13),
    );

    if (label == null) {
      return field;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryBlue,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: TextStyle(fontSize: 13, color: AppTheme.errorRed),
              ),
          ],
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}
