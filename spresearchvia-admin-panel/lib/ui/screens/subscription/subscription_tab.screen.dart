import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';
import 'package:spresearch_web/controllers/subscription/subscription.controller.dart';
import 'package:spresearch_web/controllers/subscription/subscription_navigation.controller.dart';
import 'package:spresearch_web/ui/layouts/dashboard_layout.widget.dart';
import '../../widgets/button.widget.dart';
import 'widgets/plan_filters.widget.dart';
import 'widgets/plans_table.widget.dart';
import 'widgets/existing_segments.widget.dart';

class SubscriptionTab extends StatelessWidget {
  const SubscriptionTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SubscriptionController());
    final navController = Get.put(SubscriptionNavigationController());

    return Obx(() {
      return DashboardLayout(
        child:
            navController.currentScreen ??
            SingleChildScrollView(
              child: Container(
                color: AppTheme.gray50,
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
                          AppStrings.subscriptionPlans,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Button(
                              title: 'HNI Requests',
                              buttonType: ButtonType.blue,
                              icon: Icons.workspace_premium,
                              onTap: () =>
                                  Get.toNamed('/subscriptions/hni-requests'),
                            ),
                            const SizedBox(width: 12),
                            Button(
                              title: AppStrings.createSegment,
                              buttonType: ButtonType.green,
                              icon: Icons.add,
                              onTap: () => navController.showCreateSegment(),
                            ),
                            const SizedBox(width: 12),
                            Button(
                              title: AppStrings.createNewPlan,
                              buttonType: ButtonType.green,
                              icon: Icons.add,
                              onTap: () => navController.showCreatePlan(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    PlanFilters(
                      selectedStatus: controller.selectedStatus.value,
                      searchController: controller.searchController,
                      onStatusChanged: (v) => controller.updateStatus(v!),
                      onApply: () => controller.applyFilters(),
                      onReset: () => controller.resetFilters(),
                    ),
                    const SizedBox(height: 24),
                    const PlansTable(),
                    const SizedBox(height: 32),
                    ExistingSegments(controller: controller),
                  ],
                ),
              ),
            ),
      );
    });
  }
}
