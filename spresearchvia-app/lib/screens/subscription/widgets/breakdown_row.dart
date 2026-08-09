import 'package:flutter/material.dart';
import 'package:spresearchvia/core/theme/app_theme.dart';

class BreakdownRow extends StatelessWidget {
  final String label;
  final String value;

  const BreakdownRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: AppTheme.textBlack,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textBlack,
          ),
        ),
      ],
    );
  }
}
