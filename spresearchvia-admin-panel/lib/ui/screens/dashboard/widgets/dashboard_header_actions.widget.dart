import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';

class DashboardHeaderActions extends StatelessWidget {
  const DashboardHeaderActions({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    return Obx(() {
      final user = authController.user.value;
      final displayName = user?.fullName ?? 'User';
      final role = (user?.subscriptionPlan ?? 'N/A').capitalizeFirst;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.gray200, width: 1)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Welcome back, $displayName ($role) 👋',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                Get.find<AuthController>().logout();
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: authController.isImpersonating.value
                      ? const Color(0xFFFEF3C7)
                      : Colors.transparent,
                  border: Border.all(
                    color: authController.isImpersonating.value
                        ? const Color(0xFFF59E0B)
                        : AppTheme.primaryBlue.withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      authController.isImpersonating.value
                          ? Icons.arrow_back_rounded
                          : Icons.logout,
                      color: authController.isImpersonating.value
                          ? const Color(0xFF92400E)
                          : AppTheme.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      authController.isImpersonating.value
                          ? 'Return to Admin'
                          : 'Logout',
                      style: TextStyle(
                        color: authController.isImpersonating.value
                            ? const Color(0xFF92400E)
                            : AppTheme.primaryBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
