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
    final canUpdate = currentUser == null ||
        currentUser.isAdmin ||
        currentUser.isResearcher ||
        currentUser.has('reports.update');
    final canDelete = currentUser == null ||
        currentUser.isAdmin ||
        currentUser.isResearcher ||
        currentUser.has('reports.delete');
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => navController.showReportDetails(report),
            tooltip: 'View Details',
            icon: Icon(
              Icons.visibility_outlined,
              size: 18,
              color: AppTheme.primaryBlue,
            ),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          if (canUpdate) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () =>
                  navController.showUploadReport(reportToEdit: report),
              tooltip: 'Edit Report',
              icon: Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppTheme.warningOrange,
              ),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
          if (canDelete) ...[
            const SizedBox(width: 8),
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
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ],
      ),
    );
  }
}
