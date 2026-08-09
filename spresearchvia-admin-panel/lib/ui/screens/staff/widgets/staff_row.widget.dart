import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/models/staff.model.dart';

class StaffRow extends TableRow {
  final StaffModel staff;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(bool)? onStatusToggle;

  StaffRow({
    required this.staff,
    this.onEdit,
    this.onDelete,
    this.onStatusToggle,
  }) : super(
         children: [
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             child: InkWell(
               onTap: () => Get.toNamed('/staff/${staff.id}'),
               child: Text(
                 staff.name,
                 style: TextStyle(
                   fontSize: 14,
                   fontWeight: FontWeight.w600,
                   color: AppTheme.primaryBlue,
                   decoration: TextDecoration.underline,
                 ),
               ),
             ),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             child: Text(
               staff.mobile,
               style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
             ),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             child: Text(
               staff.email,
               style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
             ),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             child: Text(
               staff.role,
               style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
             ),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             child: Row(
               children: [
                 Transform.scale(
                   scale: 0.8,
                   child: Switch(
                     value: staff.status == 'Active',
                     onChanged: onStatusToggle,
                     activeColor: AppTheme.successGreen,
                     activeTrackColor: AppTheme.successGreen.withValues(
                       alpha: 0.2,
                     ),
                     inactiveThumbColor: AppTheme.errorRed,
                     inactiveTrackColor: AppTheme.errorRed.withValues(
                       alpha: 0.2,
                     ),
                   ),
                 ),
                 const SizedBox(width: 8),
                 Text(
                   staff.status,
                   style: TextStyle(
                     fontSize: 12,
                     color: staff.status == 'Active'
                         ? AppTheme.successGreen
                         : AppTheme.errorRed,
                     fontWeight: FontWeight.w500,
                   ),
                 ),
               ],
             ),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             child: Row(
               children: [
                 IconButton(
                   onPressed: () => Get.toNamed('/staff/${staff.id}'),
                   icon: Icon(
                     Icons.visibility,
                     size: 18,
                     color: AppTheme.primaryBlue,
                   ),
                   tooltip: 'View Staff Details',
                   padding: EdgeInsets.zero,
                   constraints: const BoxConstraints(),
                 ),
                 const SizedBox(width: 8),
                 IconButton(
                   onPressed: onEdit,
                   icon: Icon(
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
                   icon: Icon(Icons.delete, size: 18, color: AppTheme.errorRed),
                   padding: EdgeInsets.zero,
                   constraints: const BoxConstraints(),
                 ),
               ],
             ),
           ),
         ],
       );
}
