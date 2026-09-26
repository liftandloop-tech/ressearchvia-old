import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/user.controller.dart';
import '../../../../models/user.model.dart';
import 'table_status_badge.widget.dart';
import 'table_manager_dropdown.widget.dart';
import 'table_actions.widget.dart';
import '../../../widgets/button.widget.dart';
import '../../subscription/pending_bank_transfers.screen.dart';

class UserDataRow extends DataRow2 {
  UserDataRow({
    required UserModel user,
    UserController? controller,
    required bool isDirector,
    required bool canManageSubscription,
  }) : super(
         cells: [
           DataCell(
             Text(_formatDateTime(user.registrationDate), style: _cellStyle),
           ),
           DataCell(
             Text(
               _formatName(user.fullName),
               style: _cellStyle,
               maxLines: 2,
               softWrap: true,
               overflow: TextOverflow.ellipsis,
             ),
           ),

           DataCell(Text(user.mobile, style: _cellStyle)),
           DataCell(Center(child: TableStatusBadge(status: user.kycStatus))),
           if (!isDirector && canManageSubscription)
             DataCell(
               Center(
                 child: Button(
                   title: 'Manage',
                   buttonType: ButtonType.blue,
                   size: ButtonSize.small,
                   onTap: () => PendingBankTransfersScreen.showUserDossierDialogByUserId(
                     user.id,
                     userModel: user,
                   ),
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
      return '$day/$month/$year';
    } catch (e) {
      return 'N/A';
    }
  }


  static const TextStyle _cellStyle = TextStyle(
    fontSize: 13,
    color: AppTheme.textPrimary,
  );
}
