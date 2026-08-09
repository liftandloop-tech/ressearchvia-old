import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/user.controller.dart';
import '../../../../models/user.model.dart';
import 'user_table_cell.widget.dart';
import 'user_status_badge.widget.dart';
import 'user_manager_dropdown.widget.dart';
import 'user_actions.widget.dart';

class UserRow extends StatelessWidget {
  final UserModel user;

  const UserRow({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserController>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Obx(
            () => Checkbox(
              value: controller.selectedUsers.contains(user.id),
              onChanged: (_) => controller.toggleUserSelection(user.id),
              activeColor: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          UserTableCell(
            user.userId ?? user.id,
            flex: 1,
            alignment: TextAlign.left,
          ),
          UserTableCell(user.fullName, flex: 2, alignment: TextAlign.left),
          UserTableCell(user.email, flex: 2, alignment: TextAlign.left),
          UserTableCell(user.mobile, flex: 2, alignment: TextAlign.left),
          UserStatusBadge(user.registrationStatus, flex: 1), // Reg Status
          UserStatusBadge(user.kycStatus, flex: 1), // KYC Status
          UserTableCell(
            user.subscriptionPlan,
            flex: 2,
            alignment: TextAlign.left,
          ),
          UserStatusBadge(user.subscriptionStatus, flex: 2),
          UserManagerDropdown(user.manager ?? 'Rohit Sharma', flex: 2),
          UserActions(flex: 1, user: user),
        ],
      ),
    );
  }
}
