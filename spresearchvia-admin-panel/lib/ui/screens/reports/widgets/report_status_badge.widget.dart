import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class ReportStatusBadge extends StatelessWidget {
  final String status;

  const ReportStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Published':
        bgColor = AppTheme.paleGreen;
        textColor = AppTheme.successGreen;
        break;
      case 'Draft':
        bgColor = const Color(0xFFFFF3CD);
        textColor = const Color(0xFFFFC107);
        break;
      case 'Unpublished':
        bgColor = AppTheme.statusErrorLight;
        textColor = AppTheme.errorRed;
        break;
      default:
        bgColor = AppTheme.gray100;
        textColor = AppTheme.textSecondary;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
