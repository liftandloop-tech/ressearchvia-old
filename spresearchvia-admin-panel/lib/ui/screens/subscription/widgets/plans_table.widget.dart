import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/subscription/subscription.controller.dart';
import 'package:spresearch_web/controllers/subscription/subscription_navigation.controller.dart';
import 'package:spresearch_web/models/subscription_plan.model.dart';
import 'plans_table_header_cell.widget.dart';
import 'plan_row.widget.dart';
import 'plans_pagination.widget.dart';

class PlansTable extends StatelessWidget {
  const PlansTable({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SubscriptionController>();
    return Obx(() {
      if (controller.isLoadingPlans.value) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.gray200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            ),
          ),
        );
      }

      if (controller.plans.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.gray200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No subscription plans found',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
            ),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.gray200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Table(
              border: TableBorder(
                horizontalInside: BorderSide(color: AppTheme.gray200),
                top: BorderSide(color: AppTheme.gray200),
                bottom: BorderSide(color: AppTheme.gray200),
              ),
              columnWidths: const {
                0: FlexColumnWidth(0.8),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
                5: FlexColumnWidth(1.2),
                6: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: AppTheme.gray50),
                  children: [
                    PlansTableHeaderCell(text: 'Plan ID'),
                    PlansTableHeaderCell(text: 'Plan Name'),
                    PlansTableHeaderCell(text: 'Duration'),
                    PlansTableHeaderCell(text: 'Price'),
                    PlansTableHeaderCell(text: 'Status'),
                    PlansTableHeaderCell(text: 'Created Date'),
                    PlansTableHeaderCell(text: 'Actions'),
                  ],
                ),
                ...controller.plans.asMap().entries.map((entry) {
                  final index = entry.key;
                  final plan = entry.value;
                  return PlanRow(
                    planId:
                        '#${(index + 1 + (controller.plansCurrentPage.value - 1) * controller.plansItemsPerPage).toString().padLeft(3, '0')}',
                    planName:
                        plan.segmentsName != null &&
                            plan.segmentsName!.isNotEmpty
                        ? '${plan.segmentsName} ${plan.planName}'.trim()
                        : plan.planName,
                    duration: plan.formattedDuration,
                    price: plan.formattedPrice,
                    status: plan.planStatus,
                    createdDate:
                        '${plan.createdAt.year}-${plan.createdAt.month.toString().padLeft(2, '0')}-${plan.createdAt.day.toString().padLeft(2, '0')}',
                    onEdit: () => Get.find<SubscriptionNavigationController>()
                        .showCreatePlan(planToEdit: plan),
                    onDelete: () =>
                        _confirmDeletePlan(context, controller, plan),
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),
            PlansPagination(controller: controller),
          ],
        ),
      );
    });
  }

  void _confirmDeletePlan(
    BuildContext context,
    SubscriptionController controller,
    SubscriptionPlanModel plan,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Plan'),
        content: Text(
          'Are you sure you want to delete "${plan.planName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              if (Get.isSnackbarOpen) {
                Get.closeAllSnackbars();
              }
              Get.back(); // Close dialog
              controller.deletePlan(plan.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}
