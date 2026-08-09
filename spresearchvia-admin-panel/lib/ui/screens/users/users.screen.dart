import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/controllers/users/user.controller.dart';
import 'package:spresearch_web/controllers/users/users_navigation.controller.dart';
import 'package:spresearch_web/ui/layouts/dashboard_layout.widget.dart';
import 'widgets/users_filters.widget.dart';
import 'widgets/users_table.widget.dart';
import 'widgets/bulk_actions.widget.dart';
import 'create_user.screen.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserController());
    final navController = Get.put(UsersNavigationController());

    return Obx(() {
      return DashboardLayout(
        child:
            navController.currentScreen ??
            Container(
              color: AppTheme.gray50,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: Icon(
                            Icons.arrow_back,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'User Management',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            if (Get.find<AuthController>()
                                    .user
                                    .value
                                    ?.isDirector !=
                                true) ...[
                              ElevatedButton.icon(
                                onPressed: () => navController.showCreateUser(),
                                icon: const Icon(
                                  Icons.add,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Add User',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            IconButton(
                              onPressed: () => controller.applyFilters(),
                              icon: Icon(
                                Icons.refresh,
                                color: AppTheme.primaryBlue,
                              ),
                              tooltip: 'Refresh Users',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage and monitor all user accounts',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    UsersFilters(),
                    const SizedBox(height: 24),
                    Obx(
                      () => controller.selectedUsers.isNotEmpty
                          ? Column(
                              children: [
                                BulkActions(),
                                const SizedBox(height: 16),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                    UsersTable(),
                  ],
                ),
              ),
            ),
      );
    });
  }
}
