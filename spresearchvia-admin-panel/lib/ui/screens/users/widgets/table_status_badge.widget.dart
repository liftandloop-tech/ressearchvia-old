import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class TableStatusBadge extends StatelessWidget {
  final String status;

  const TableStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor, textColor;
    final normalizedStatus = status.toLowerCase();

    if (normalizedStatus == 'active' || normalizedStatus == 'paid') {
      bgColor = AppTheme.statusSuccessLight;
      textColor = AppTheme.statusSuccess;
    } else if (normalizedStatus == 'expired' || normalizedStatus == 'failed') {
      bgColor = AppTheme.statusErrorLight;
      textColor = AppTheme.statusError;
    } else if (normalizedStatus == 'cancelled' ||
        normalizedStatus == 'pending') {
      bgColor = AppTheme.statusWarningLight;
      textColor = AppTheme.statusWarning;
    } else if (normalizedStatus.contains('silver')) {
      bgColor = const Color(0xFFF3F4F6); // Gray 100
      textColor = const Color(0xFF4B5563); // Gray 600
    } else if (normalizedStatus.contains('gold')) {
      bgColor = const Color(0xFFFFFBEB); // Amber 50
      textColor = const Color(0xFFD97706); // Amber 600
    } else if (normalizedStatus == 'not registered') {
      bgColor = const Color(0xFFFEE2E2); // Red 50
      textColor = const Color(0xFFDC2626); // Red 600
    } else if (normalizedStatus == 'pending approval' ||
        normalizedStatus == 'pending for approval') {
      bgColor = const Color(0xFFFEF3C7); // Amber 100
      textColor = const Color(0xFFD97706); // Amber 600
    } else if (normalizedStatus == 'waiting_for_review') {
      bgColor = const Color(0xFFEFF6FF); // Blue 50
      textColor = const Color(0xFF1D4ED8); // Blue 700
    } else if (normalizedStatus == 'in_progress') {
      bgColor = const Color(0xFFF9FAFB); // Gray 50
      textColor = const Color(0xFF4B5563); // Gray 600
    } else {
      bgColor = AppTheme.backgroundLight;
      textColor = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status.isEmpty ? 'N/A' : status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
