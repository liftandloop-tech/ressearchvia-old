import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/user.controller.dart';
import '../../../../models/user.model.dart';
import 'table_status_badge.widget.dart';
import 'table_manager_dropdown.widget.dart';
import 'table_actions.widget.dart';
import '../../../widgets/button.widget.dart';

class UserDataRow extends DataRow2 {
  UserDataRow({
    required UserModel user,
    required UserController controller,
    required bool isDirector,
  }) : super(
         cells: [
           DataCell(
             Obx(
               () => Checkbox(
                 value: controller.selectedUsers.contains(user.id),
                 onChanged: (_) => controller.toggleUserSelection(user.id),
                 activeColor: AppTheme.primary,
               ),
             ),
           ),
           DataCell(
             Text(_formatDateTime(user.registrationDate), style: _cellStyle),
           ),
           DataCell(Text(_formatName(user.fullName), style: _cellStyle)),

           DataCell(Text(user.mobile, style: _cellStyle)),
           DataCell(Text(user.panCard ?? 'N/A', style: _cellStyle)),
           DataCell(
             Center(
               child: TableStatusBadge(
                 status: _getRegistrationPlanStatus(user),
               ),
             ),
           ),
           DataCell(Center(child: TableStatusBadge(status: user.kycStatus))),
           if (!isDirector)
             DataCell(
               Center(
                 child: Button(
                   title: 'Manage',
                   buttonType: ButtonType.blue,
                   size: ButtonSize.small,
                   onTap: () => Get.toNamed('/manage-user/${user.id}'),
                 ),
               ),
             ),
           DataCell(Center(child: TableManagerDropdown(user: user))),
           DataCell(Center(child: TableActions(user: user))),
         ],
       );

  static String _formatName(String name) {
    if (name.isEmpty) return name;
    return name
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  static String _formatDateTime(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$minute';
    } catch (e) {
      return 'N/A';
    }
  }

  static String _getRegistrationPlanStatus(UserModel user) {
    final type = user.registrationType.toLowerCase();

    // 1. Check for confirmed Silver or Gold registration
    if (type.contains('yearly')) {
      return 'Silver';
    } else if (type.contains('lifetime')) {
      return 'Gold';
    }

    // 2. Check for Pending Approval
    // Logic: Checks for paymentIntent with purchaseType 'REGISTRATION' and status not 'PAID'
    final paymentIntent = user.paymentIntent;

    if (paymentIntent != null) {
      final purchaseType =
          paymentIntent['purchaseType']?.toString().toLowerCase() ?? '';
      final status = paymentIntent['status']?.toString().toLowerCase() ?? '';

      // Backend guarantees purchaseType is REGISTRATION, but we check explicitly
      if ((purchaseType == 'registration' || purchaseType == 'plan') &&
          status != 'paid') {
        return 'Pending for Approval';
      }
    }

    // 3. Default to Not Registered
    return 'Not Registered';
  }

  static const TextStyle _cellStyle = TextStyle(
    fontSize: 13,
    color: AppTheme.textPrimary,
  );
}
