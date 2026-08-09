import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class EditProfileTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool required;
  final String? Function(String?)? validator;
  final bool enabled;

  const EditProfileTextField({
    super.key,
    required this.label,
    required this.controller,
    this.required = false,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
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
        TextFormField(
          controller: controller,
          validator: validator,
          enabled: enabled,
          decoration: InputDecoration(
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
            errorStyle: TextStyle(
              fontSize: 12,
              color: AppTheme.errorRed,
              fontFamily: 'Poppins',
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
        ),
      ],
    );
  }
}
