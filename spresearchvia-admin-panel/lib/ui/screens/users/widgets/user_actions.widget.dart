import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/users_navigation.controller.dart';
import 'package:spresearch_web/controllers/users/user_management.controller.dart';
import '../../../../models/user.model.dart'; // Import UserModel
import 'assign_entitlements_dialog.dart';

class UserActions extends StatelessWidget {
  final int flex;
  final UserModel user; // Changed from userId to full user object

  const UserActions({super.key, required this.flex, required this.user});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              Icons.verified_user_outlined,
              size: 18,
            ), // Entitlement Icon
            onPressed: () {
              Get.dialog(
                AssignEntitlementsDialog(
                  userId: user.id,
                  currentRegStatus: user.registrationStatus,
                ),
              ).then((_) => _refresh());
            },
            color: AppTheme.primary,
            tooltip: 'Assign Entitlements',
          ),
          IconButton(
            icon: Icon(Icons.card_membership_outlined, size: 18),
            onPressed: () {
              // Manage Users / Subscriptions
              Get.find<UsersNavigationController>().showManageSubscription(
                user.id,
              );
            },
            color: AppTheme.textSecondary,
            tooltip: 'Manage Subscription',
          ),
          IconButton(
            icon: Icon(Icons.visibility_outlined, size: 18),
            onPressed: () {
              Get.find<UsersNavigationController>().showUserDetails(user.id);
            },
            color: AppTheme.textSecondary,
            tooltip: 'View',
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 18),
            onPressed: () {
              Get.find<UsersNavigationController>().showEditProfile(user.id);
            },
            color: AppTheme.textSecondary,
            tooltip: 'Edit',
          ),
        ],
      ),
    );
  }

  void _refresh() {
    if (Get.isRegistered<UserManagementController>()) {
      Get.find<UserManagementController>().fetchUsers();
    }
  }
}
