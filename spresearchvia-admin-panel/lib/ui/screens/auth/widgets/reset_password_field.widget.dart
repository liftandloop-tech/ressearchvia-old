import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';

class ResetPasswordField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController textController;
  final RxBool obscurePassword;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const ResetPasswordField({
    super.key,
    required this.label,
    required this.hint,
    required this.textController,
    required this.obscurePassword,
    required this.onToggle,
    this.validator,
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
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        Obx(
          () => TextFormField(
            controller: textController,
            obscureText: obscurePassword.value,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
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
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword.value
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: AppTheme.gray500,
                ),
                onPressed: onToggle,
              ),
            ),
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Poppins',
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
