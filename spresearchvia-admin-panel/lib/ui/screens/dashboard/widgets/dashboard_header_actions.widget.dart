import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/config/routes.config.dart';

class DashboardHeaderActions extends StatelessWidget {
  const DashboardHeaderActions({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    return Obx(() {
      final user = authController.user.value;
      final displayName = user?.fullName ?? 'Staff Member';
      final role = (user?.subscriptionPlan ?? 'Staff').capitalizeFirst;
      final isCurrentProfile = Get.currentRoute == AppRoutes.profile;

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCurrentProfile ? AppTheme.primaryBlue.withOpacity(0.04) : Colors.white,
          border: Border(top: BorderSide(color: AppTheme.gray200, width: 1)),
        ),
        child: Column(
          children: [
            // Profile Tile Card (Navigates to /profile)
            InkWell(
              onTap: () {
                if (Get.currentRoute != AppRoutes.profile) {
                  Get.toNamed(AppRoutes.profile);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isCurrentProfile
                      ? AppTheme.primaryBlue.withOpacity(0.08)
                      : AppTheme.gray50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCurrentProfile
                        ? AppTheme.primaryBlue.withOpacity(0.3)
                        : AppTheme.gray200,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryBlue.withOpacity(0.15),
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  role ?? 'Staff',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: isCurrentProfile ? AppTheme.primaryBlue : AppTheme.gray400,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Bottom Buttons Row: My Profile & Logout
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (Get.currentRoute != AppRoutes.profile) {
                        Get.toNamed(AppRoutes.profile);
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: isCurrentProfile ? AppTheme.primaryBlue : Colors.white,
                        border: Border.all(
                          color: isCurrentProfile ? AppTheme.primaryBlue : AppTheme.gray300,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 15,
                            color: isCurrentProfile ? Colors.white : AppTheme.textPrimary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'My Profile',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isCurrentProfile ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Get.find<AuthController>().logout();
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: authController.isImpersonating.value
                            ? const Color(0xFFFEF3C7)
                            : Colors.white,
                        border: Border.all(
                          color: authController.isImpersonating.value
                              ? const Color(0xFFF59E0B)
                              : Colors.red.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            authController.isImpersonating.value
                                ? Icons.arrow_back_rounded
                                : Icons.logout,
                            size: 15,
                            color: authController.isImpersonating.value
                                ? const Color(0xFF92400E)
                                : Colors.red.shade700,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            authController.isImpersonating.value ? 'Exit' : 'Logout',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: authController.isImpersonating.value
                                  ? const Color(0xFF92400E)
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
