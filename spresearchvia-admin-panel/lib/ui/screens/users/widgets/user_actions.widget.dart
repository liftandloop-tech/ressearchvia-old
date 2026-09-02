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
    final authController = Get.find<AuthController>();
    final canManageSubscription = (authController.user.value?.isAdmin == true) ||
        (authController.user.value?.has('subscriptions.activate') ?? false) ||
        (authController.user.value?.has('subscriptions.revoke') ?? false) ||
        (authController.user.value?.has('subscriptions.view') ?? false);
    final canEditUser = (authController.user.value?.isAdmin == true) ||
        (authController.user.value?.has('users.update') ?? false);

    return Expanded(
      flex: flex,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (canManageSubscription)
            IconButton(
              icon: const Icon(
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
          if (canManageSubscription)
            IconButton(
              icon: const Icon(Icons.card_membership_outlined, size: 18),
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
            icon: const Icon(Icons.visibility_outlined, size: 18),
            onPressed: () {
              Get.find<UsersNavigationController>().showUserDetails(user.id);
            },
            color: AppTheme.textSecondary,
            tooltip: 'View',
          ),
          if (canEditUser)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
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
