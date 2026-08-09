import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PlanDetailRow extends StatelessWidget {
  const PlanDetailRow({
    super.key,
    required this.label,
    required this.value,
    required this.isExpiry,
  });

  final String label;
  final String value;
  final bool isExpiry;

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
            fontWeight: FontWeight.w400,
            color: AppTheme.textGrey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isExpiry ? AppTheme.error : AppTheme.primaryBlueDark,
          ),
        ),
      ],
    );
  }
}
