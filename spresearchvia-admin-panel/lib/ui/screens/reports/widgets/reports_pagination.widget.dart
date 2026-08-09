import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/reports/report.controller.dart';
import 'reports_navigation_button.widget.dart';
import 'reports_page_numbers.widget.dart';

class ReportsPagination extends StatelessWidget {
  const ReportsPagination({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReportController>();

    return Obx(() {
      final start =
          (controller.currentPage.value - 1) * controller.itemsPerPage + 1;
      final end = start + controller.reports.length - 1;
      final total = controller.totalCount.value;

      return Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Showing $start to $end of $total results',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            Row(
              children: [
                ReportsNavigationButton(
                  icon: Icons.chevron_left,
                  onPressed: controller.currentPage.value > 1
                      ? () =>
                            controller.setPage(controller.currentPage.value - 1)
                      : null,
                ),
                const SizedBox(width: 8),
                const ReportsPageNumbers(),
                const SizedBox(width: 8),
                ReportsNavigationButton(
                  icon: Icons.chevron_right,
                  onPressed:
                      controller.currentPage.value < controller.totalPages
                      ? () =>
                            controller.setPage(controller.currentPage.value + 1)
                      : null,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
