import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class PaymentTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final String amount;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const PaymentTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.validator,
    this.onFieldSubmitted,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.labelTextStyle.copyWith(fontFamily: 'Poppins'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          style: const TextStyle(fontFamily: 'Poppins'),
          decoration: AppTheme.inputDecoration(
            hintText,
            suffixIcon: Text(
              amount,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.gray500,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
