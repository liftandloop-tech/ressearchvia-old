import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/subscription/subscription.controller.dart';
import 'plans_page_button.widget.dart';

class PlansPageNumbers extends StatelessWidget {
  final SubscriptionController controller;

  const PlansPageNumbers({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final current = controller.plansCurrentPage.value;
    final total = controller.plansTotalPages;
    List<Widget> pages = [];

    if (total <= 3) {
      for (int i = 1; i <= total; i++) {
        pages.add(
          PlansPageButton(
            page: i,
            isActive: current == i,
            controller: controller,
          ),
        );
        if (i < total) pages.add(const SizedBox(width: 8));
      }
    } else {
      pages.add(
        PlansPageButton(
          page: 1,
          isActive: current == 1,
          controller: controller,
        ),
      );
      if (current > 2) {
        pages.add(const SizedBox(width: 8));
        pages.add(Text('...', style: TextStyle(color: AppTheme.textSecondary)));
      }
      if (current > 1 && current < total) {
        pages.add(const SizedBox(width: 8));
        pages.add(
          PlansPageButton(
            page: current,
            isActive: true,
            controller: controller,
          ),
        );
      }
      if (current < total - 1) {
        pages.add(const SizedBox(width: 8));
        pages.add(Text('...', style: TextStyle(color: AppTheme.textSecondary)));
      }
      pages.add(const SizedBox(width: 8));
      pages.add(
        PlansPageButton(
          page: total,
          isActive: current == total,
          controller: controller,
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: pages);
  }
}
