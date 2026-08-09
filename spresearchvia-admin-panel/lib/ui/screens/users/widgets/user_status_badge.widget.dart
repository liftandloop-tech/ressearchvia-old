import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class UserStatusBadge extends StatelessWidget {
  final String status;
  final int flex;

  const UserStatusBadge(this.status, {super.key, required this.flex});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Active':
        bgColor = AppTheme.statusSuccessLight;
        textColor = AppTheme.statusSuccess;
        break;
      case 'Expired':
        bgColor = AppTheme.statusErrorLight;
        textColor = AppTheme.statusError;
        break;
      case 'Cancelled':
        bgColor = AppTheme.statusWarningLight;
        textColor = AppTheme.statusWarning;
        break;
      default:
        bgColor = AppTheme.backgroundLight;
        textColor = AppTheme.textSecondary;
    }

    return Expanded(
      flex: flex,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(100),
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
      ),
    );
  }
}
