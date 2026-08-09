import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/subscription/subscription.controller.dart';
import 'plans_page_numbers.widget.dart';

class PlansPagination extends StatelessWidget {
  final SubscriptionController controller;

  const PlansPagination({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final start =
        (controller.plansCurrentPage.value - 1) * controller.plansItemsPerPage +
        1;
    final end = start + controller.plans.length - 1;
    final total = controller.totalPlansCount.value;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing $start to $end of $total results',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        Row(
          children: [
            IconButton(
              onPressed: controller.plansCurrentPage.value > 1
                  ? () => controller.setPlansPage(
                      controller.plansCurrentPage.value - 1,
                    )
                  : null,
              icon: Icon(
                Icons.chevron_left,
                size: 20,
                color: controller.plansCurrentPage.value > 1
                    ? AppTheme.textPrimary
                    : AppTheme.gray300,
              ),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
            const SizedBox(width: 8),
            PlansPageNumbers(controller: controller),
            const SizedBox(width: 8),
            IconButton(
              onPressed:
                  controller.plansCurrentPage.value < controller.plansTotalPages
                  ? () => controller.setPlansPage(
                      controller.plansCurrentPage.value + 1,
                    )
                  : null,
              icon: Icon(
                Icons.chevron_right,
                size: 20,
                color:
                    controller.plansCurrentPage.value <
                        controller.plansTotalPages
                    ? AppTheme.textPrimary
                    : AppTheme.gray300,
              ),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }
}
