import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/controllers/reports/report.controller.dart';
import 'package:spresearch_web/controllers/reports/reports_navigation.controller.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';
import 'package:spresearch_web/ui/layouts/dashboard_layout.widget.dart';
import '../../widgets/button.widget.dart';
import 'widgets/reports_filters.widget.dart';
import 'widgets/reports_table.widget.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ReportController());
    final navController = Get.put(ReportsNavigationController());

    return Obx(() {
      return DashboardLayout(
        child:
            navController.currentScreen ??
            Container(
              color: AppTheme.gray50,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.reportsManagement,
                              style: AppTheme.h1Style.copyWith(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppStrings.manageOrganizeReports,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () =>
                                  Get.find<ReportController>().fetchReports(),
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.refresh,
                                  size: 20,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              tooltip: 'Refresh Reports',
                            ),
                            if (Get.find<AuthController>().user.value?.has('reports.create') ?? false) ...[
                              const SizedBox(width: 12),
                              Button(
                                title: AppStrings.uploadReport,
                                buttonType: ButtonType.green,
                                icon: Icons.add_rounded,
                                onTap: () => navController.showUploadReport(),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ReportsFilters(),
                    const SizedBox(height: 24),
                    ReportsTable(),
                  ],
                ),
              ),
            ),
      );
    });
  }
}
