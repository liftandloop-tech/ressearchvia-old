import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/reports/report.controller.dart';
import 'package:spresearch_web/ui/widgets/skeleton_loader.widget.dart';
import 'reports_table_header_cell.widget.dart';
import 'report_row.widget.dart';
import 'reports_pagination.widget.dart';

class ReportsTable extends StatelessWidget {
  const ReportsTable({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReportController>();

    return Obx(() {
      final isLoading = controller.isLoading.value;
      final reports = controller.reports;

      if (isLoading && reports.isEmpty) {
        return const SizedBox(
          height: 420,
          child: TableSkeleton(rowCount: 7, columnCount: 6),
        );
      }

      return Container(
        decoration: AppTheme.cardDecoration.copyWith(
          border: Border.all(color: AppTheme.gray200, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            if (isLoading)
              const LinearProgressIndicator(
                minHeight: 3,
                color: AppTheme.primaryBlue,
                backgroundColor: Colors.transparent,
              ),
            Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.top,
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: AppTheme.gray200,
                  width: 1.0,
                ),
              ),
              columnWidths: const {
                0: FlexColumnWidth(2.0), // Title
                1: FlexColumnWidth(0.8), // Status
                2: FlexColumnWidth(0.5), // File
                3: FlexColumnWidth(1.2), // Created Date
                4: FlexColumnWidth(1.2), // Last Updated
                5: FlexColumnWidth(1.2), // Actions
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: AppTheme.gray50,
                    border: Border(
                      bottom: BorderSide(color: AppTheme.gray200, width: 1),
                    ),
                  ),
                  children: const [
                    ReportsTableHeaderCell(title: 'Title'),
                    ReportsTableHeaderCell(title: 'Status'),
                    ReportsTableHeaderCell(title: 'File'),
                    ReportsTableHeaderCell(title: 'Created Date'),
                    ReportsTableHeaderCell(title: 'Last Updated'),
                    ReportsTableHeaderCell(title: 'Actions'),
                  ],
                ),
                if (reports.isEmpty)
                  TableRow(
                    children: List.generate(
                      6,
                      (_) => Padding(
                        padding: const EdgeInsets.all(48),
                        child: Text(
                          'No reports found',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  ...reports.map(
                    (report) => ReportRow(
                      report: report,
                      categoryName: controller.getCategoryName(report.category),
                    ),
                  ),
              ],
            ),
            Divider(height: 1, color: AppTheme.gray200, thickness: 1),
            const ReportsPagination(),
          ],
        ),
      );
    });
  }
}
