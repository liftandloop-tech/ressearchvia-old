import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/reports/reports_navigation.controller.dart';
import 'package:spresearch_web/controllers/reports/report.controller.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import '../../../../models/report.model.dart';

class ReportActions extends StatelessWidget {
  final ReportModel report;

  const ReportActions({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final navController = Get.find<ReportsNavigationController>();
    final reportController = Get.find<ReportController>();

    final currentUser = Get.find<AuthController>().user.value;
    final canUpdate = currentUser?.has('reports.update') ?? false;
    final canDelete = currentUser?.has('reports.delete') ?? false;
    return Row(
      children: [
        IconButton(
          onPressed: () => navController.showReportDetails(report),
          tooltip: 'View Details',
          icon: Icon(
            Icons.visibility_outlined,
            size: 18,
            color: AppTheme.primaryBlue,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        if (canUpdate) ...[
          const SizedBox(width: 12),
          IconButton(
            onPressed: () =>
                navController.showUploadReport(reportToEdit: report),
            tooltip: 'Edit Report',
            icon: Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppTheme.warningOrange,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
        if (canDelete) ...[
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  title: const Text('Delete Report'),
                  content: const Text(
                    'Are you sure you want to delete this report?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        if (Get.isSnackbarOpen) {
                          Get.closeAllSnackbars();
                        }
                        Get.back();
                        reportController.deleteReport(report.id);
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Delete Report',
            icon: Icon(
              Icons.delete_outline,
              size: 18,
              color: AppTheme.errorRed,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ],
    );
  }
}
