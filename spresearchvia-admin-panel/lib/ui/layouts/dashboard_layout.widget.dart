import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/controllers/dashboard/main_dashboard.controller.dart';
import '../screens/dashboard/widgets/dashboard_header.widget.dart';

class DashboardLayout extends StatelessWidget {
  final Widget child;

  const DashboardLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainDashboardController>();
    final authController = Get.find<AuthController>();

    return SelectionArea(
      child: Scaffold(
        backgroundColor: AppTheme.gray50,
        body: Row(
          children: [
            DashboardHeader(controller: controller),
            Expanded(
              child: ClipRect(
                child: Column(
                  children: [
                    Obx(() {
                      if (!authController.isImpersonating.value) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          border: Border(
                            bottom: BorderSide(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.switch_account_rounded,
                              size: 20,
                              color: Color(0xFF92400E),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Impersonation Mode: Logged in as ${authController.impersonatedStaffName.value.isNotEmpty ? authController.impersonatedStaffName.value : "Staff Member"} (${(authController.user.value?.subscriptionPlan ?? "Staff").capitalizeFirst})',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => authController.exitImpersonation(),
                              icon: const Icon(Icons.arrow_back, size: 16),
                              label: const Text('Return to Admin Account'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF92400E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
