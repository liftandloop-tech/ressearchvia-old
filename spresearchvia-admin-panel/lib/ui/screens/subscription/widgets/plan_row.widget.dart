import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class PlanRow extends TableRow {
  PlanRow({
    required String planId,
    required String planName,
    required String duration,
    required String price,
    required String status,
    required String createdDate,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) : super(
         children: [
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             child: Text(
               planId,
               style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
             ),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             child: Text(
               planName,
               style: TextStyle(
                 fontSize: 14,
                 fontWeight: FontWeight.w500,
                 color: AppTheme.textPrimary,
               ),
             ),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             child: Text(
               duration,
               style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
             ),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             child: Text(
               price,
               style: TextStyle(
                 fontSize: 14,
                 fontWeight: FontWeight.w500,
                 color: AppTheme.textPrimary,
               ),
             ),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             child: Align(
               alignment: Alignment.centerLeft,
               child: Container(
                 padding: const EdgeInsets.symmetric(
                   horizontal: 12,
                   vertical: 4,
                 ),
                 decoration: BoxDecoration(
                   color: status == 'Active'
                       ? AppTheme.paleGreen
                       : AppTheme.statusErrorLight,
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: Text(
                   status,
                   style: TextStyle(
                     fontSize: 12,
                     fontWeight: FontWeight.w500,
                     color: status == 'Active'
                         ? AppTheme.successGreen
                         : AppTheme.errorRed,
                   ),
                 ),
               ),
             ),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             child: Text(
               createdDate,
               style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
             ),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             child: Row(
               children: [
                 IconButton(
                   onPressed: onEdit,
                   icon: Icon(
                     Icons.edit,
                     size: 18,
                     color: AppTheme.primaryBlue,
                   ),
                   padding: EdgeInsets.zero,
                   constraints: BoxConstraints(),
                 ),
                 const SizedBox(width: 8),
                 IconButton(
                   onPressed: onDelete,
                   icon: Icon(Icons.delete, size: 18, color: AppTheme.errorRed),
                   padding: EdgeInsets.zero,
                   constraints: BoxConstraints(),
                 ),
               ],
             ),
           ),
         ],
       );
}
