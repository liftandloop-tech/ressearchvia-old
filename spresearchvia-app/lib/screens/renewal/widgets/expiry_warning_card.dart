import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ExpiryWarningCard extends StatelessWidget {
  const ExpiryWarningCard({
    super.key,
    required this.daysRemaining,
    required this.message,
  });

  final int daysRemaining;
  final String message;

  @override
  Widget build(BuildContext context) {
    final isUrgent = daysRemaining <= 7;
    final backgroundColor = isUrgent
        ? AppTheme.errorBackground
        : AppTheme.infoBackground;
    final borderColor = isUrgent ? AppTheme.errorBorder : AppTheme.infoBorder;
    final textColor = isUrgent ? AppTheme.error : AppTheme.infoText;
    final iconColor = isUrgent ? AppTheme.error : AppTheme.textGrey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isUrgent ? Icons.warning : Icons.info_outline,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  daysRemaining == 0
                      ? 'Plan expired'
                      : 'Plan expiring in $daysRemaining days',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
