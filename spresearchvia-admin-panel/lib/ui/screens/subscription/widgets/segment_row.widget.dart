import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class SegmentRow extends TableRow {
  final String name;
  final String category;
  final String status;
  final String date;
  final Color statusColor;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  SegmentRow({
    required this.name,
    required this.category,
    required this.status,
    required this.date,
    required this.statusColor,
    this.onEdit,
    this.onDelete,
  }) : super(
         children: [
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             child: Text(
               name,
               style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
             ),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             child: Text(
               category,
               style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
             ),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             child: Row(
               children: [
                 Container(
                   width: 6,
                   height: 6,
                   decoration: BoxDecoration(
                     color: statusColor,
                     shape: BoxShape.circle,
                   ),
                 ),
                 const SizedBox(width: 6),
                 Text(
                   status,
                   style: TextStyle(
                     fontSize: 12,
                     color: statusColor,
                     fontWeight: FontWeight.w500,
                   ),
                 ),
               ],
             ),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             child: Text(
               date,
               style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
             ),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             child: Row(
               children: [
                 IconButton(
                   onPressed: onEdit,
                   icon: const Icon(
                     Icons.edit,
                     size: 18,
                     color: AppTheme.primaryBlue,
                   ),
                   padding: EdgeInsets.zero,
                   constraints: const BoxConstraints(),
                 ),
                 const SizedBox(width: 8),
                 IconButton(
                   onPressed: onDelete,
                   icon: const Icon(
                     Icons.delete,
                     size: 18,
                     color: AppTheme.errorRed,
                   ),
                   padding: EdgeInsets.zero,
                   constraints: const BoxConstraints(),
                 ),
               ],
             ),
           ),
         ],
       );
}
