import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/reports/report.controller.dart';
import 'reports_page_button.widget.dart';

class ReportsPageNumbers extends StatelessWidget {
  const ReportsPageNumbers({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReportController>();

    return Obx(() {
      final current = controller.currentPage.value;
      final total = controller.totalPages;
      List<Widget> pages = [];

      if (total <= 3) {
        for (int i = 1; i <= total; i++) {
          pages.add(
            ReportsPageButton(
              page: i,
              isActive: current == i,
              onPressed: () => controller.setPage(i),
            ),
          );
          if (i < total) pages.add(const SizedBox(width: 8));
        }
      } else {
        pages.add(
          ReportsPageButton(
            page: 1,
            isActive: current == 1,
            onPressed: () => controller.setPage(1),
          ),
        );
        if (current > 2) {
          pages.add(const SizedBox(width: 8));
          pages.add(
            Text('...', style: TextStyle(color: AppTheme.textSecondary)),
          );
        }
        if (current > 1 && current < total) {
          pages.add(const SizedBox(width: 8));
          pages.add(
            ReportsPageButton(
              page: current,
              isActive: true,
              onPressed: () => controller.setPage(current),
            ),
          );
        }
        if (current < total - 1) {
          pages.add(const SizedBox(width: 8));
          pages.add(
            Text('...', style: TextStyle(color: AppTheme.textSecondary)),
          );
        }
        pages.add(const SizedBox(width: 8));
        pages.add(
          ReportsPageButton(
            page: total,
            isActive: current == total,
            onPressed: () => controller.setPage(total),
          ),
        );
      }

      return Row(children: pages);
    });
  }
}
