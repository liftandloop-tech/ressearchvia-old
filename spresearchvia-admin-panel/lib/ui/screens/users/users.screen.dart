import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/controllers/users/user.controller.dart';
import 'package:spresearch_web/controllers/users/users_navigation.controller.dart';
import 'package:spresearch_web/ui/layouts/dashboard_layout.widget.dart';
import 'widgets/users_table.widget.dart';

class UsersScreen extends StatelessWidget {
  final bool isRegisteredClients;
  const UsersScreen({super.key, this.isRegisteredClients = false});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserController());
    final navController = Get.put(UsersNavigationController());

    final isRegistered = isRegisteredClients ||
        Get.currentRoute.startsWith('/registered-clients') ||
        Get.currentRoute.startsWith('/approvals/kyc');

    // Synchronize filter state for Registered Clients vs All Users
    if (isRegistered) {
      if (controller.kycStatusFilter.value != 'VERIFIED') {
        controller.kycStatusFilter.value = 'VERIFIED';
        controller.fetchFilteredUsers(page: 1);
      }
    } else {
      if (controller.kycStatusFilter.value == 'VERIFIED' &&
          !Get.parameters.containsKey('kyc_status')) {
        controller.kycStatusFilter.value = 'All';
        controller.fetchFilteredUsers(page: 1);
      }
    }

    return Obx(() {
      return DashboardLayout(
        child:
            navController.currentScreen ??
            Container(
              color: AppTheme.gray50,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
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
                        isRegistered ? 'Registered Clients' : 'All Clients',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          if (!isRegistered &&
                              (Get.find<AuthController>()
                                      .user
                                      .value
                                      ?.has('users.create') ??
                                  false)) ...[
                            ElevatedButton.icon(
                              onPressed: () => navController.showCreateUser(),
                              icon: const Icon(
                                Icons.add,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Add Client',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
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
                            tooltip: isRegistered
                                ? 'Refresh Registered Clients'
                                : 'Refresh Clients',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Expanded(
                    child: UsersTable(),
                  ),
                ],
              ),
            ),
      );
    });
  }
}
