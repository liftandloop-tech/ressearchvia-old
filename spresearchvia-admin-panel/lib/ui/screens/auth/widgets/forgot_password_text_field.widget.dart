import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';

class ForgotPasswordTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const ForgotPasswordTextField({
    super.key,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.emailAddress,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: AppStrings.enterEmail,
            hintStyle: TextStyle(
              fontSize: 13,
              color: AppTheme.gray400,
              fontFamily: 'Poppins',
            ),
            filled: true,
            fillColor: AppTheme.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppTheme.gray300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppTheme.gray300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppTheme.primaryBlue, width: 1.5),
            ),
            errorStyle: TextStyle(
              fontSize: 12,
              color: AppTheme.errorRed,
              fontFamily: 'Poppins',
            ),
          ),
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'Poppins',
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
