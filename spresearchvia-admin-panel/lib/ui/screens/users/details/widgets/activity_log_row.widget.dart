import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class ActivityLogRow extends TableRow {
  ActivityLogRow({
    required String dateTime,
    required String type,
    required IconData icon,
    required String description,
    required String source,
    required String status,
    required Color statusColor,
    String severity = 'INFO',
    Color? severityColor,
    Color? severityBgColor,
  }) : super(
         children: [
           // Date & Time
           Padding(
             padding: EdgeInsets.symmetric(
               horizontal: AppTheme.spacing12,
               vertical: AppTheme.spacing16,
             ),
             child: Text(dateTime, style: AppTheme.tableDataStyle),
           ),
           // Activity Type
           Padding(
             padding: EdgeInsets.symmetric(
               horizontal: AppTheme.spacing12,
               vertical: AppTheme.spacing16,
             ),
             child: Text(type, style: AppTheme.tableDataStyle),
           ),
           // Description
           Padding(
             padding: EdgeInsets.symmetric(
               horizontal: AppTheme.spacing12,
               vertical: AppTheme.spacing16,
             ),
             child: Text(description, style: AppTheme.tableDataStyle),
           ),
           // IP / Source
           Padding(
             padding: EdgeInsets.symmetric(
               horizontal: AppTheme.spacing12,
               vertical: AppTheme.spacing16,
             ),
             child: Text(
               source,
               style: AppTheme.bodySmallStyle.copyWith(
                 color: AppTheme.textSecondary,
               ),
             ),
           ),
           // Severity badge
           Padding(
             padding: EdgeInsets.symmetric(
               horizontal: AppTheme.spacing12,
               vertical: AppTheme.spacing12,
             ),
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
               decoration: BoxDecoration(
                 color: severityBgColor ?? _defaultBg(severity),
                 borderRadius: BorderRadius.circular(20),
               ),
               child: Text(
                 severity,
                 style: AppTheme.bodySmallStyle.copyWith(
                   color: severityColor ?? _defaultColor(severity),
                   fontWeight: FontWeight.w700,
                   fontSize: 11,
                 ),
               ),
             ),
           ),
           // Status
           Padding(
             padding: EdgeInsets.symmetric(
               horizontal: AppTheme.spacing12,
               vertical: AppTheme.spacing16,
             ),
             child: Row(
               children: [
                 Icon(Icons.circle, size: 8, color: statusColor),
                 SizedBox(width: AppTheme.spacing4 + 2),
                 Expanded(
                   child: Text(
                     status,
                     style: AppTheme.bodySmallStyle.copyWith(
                       color: statusColor,
                       fontWeight: FontWeight.w500,
                     ),
                     overflow: TextOverflow.ellipsis,
                   ),
                 ),
               ],
             ),
           ),
         ],
       );

  static Color _defaultColor(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return const Color(0xFFDC2626);
      case 'SECURITY':
        return const Color(0xFFD97706);
      case 'WARNING':
        return const Color(0xFF0284C7);
      default:
        return const Color(0xFF16A34A);
    }
  }

  static Color _defaultBg(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return const Color(0xFFFEE2E2);
      case 'SECURITY':
        return const Color(0xFFFEF3C7);
      case 'WARNING':
        return const Color(0xFFE0F2FE);
      default:
        return const Color(0xFFDCFCE7);
    }
  }
}
