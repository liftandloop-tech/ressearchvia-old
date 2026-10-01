import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/report.controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_styles.dart';

import 'report_card.dart';
import '../report_detail.screen.dart';

class ReportsTab extends StatelessWidget {
  final ReportController reportController;

  const ReportsTab({super.key, required this.reportController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (reportController.isReportsLoading.value &&
          reportController.reports.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        );
      }

      return Column(
        children: [
          // Compact trading calls accuracy banner
          Obx(() {
            final stats = reportController.effectiveAccuracy;
            if (stats.totalCalls == 0) return const SizedBox.shrink();
            final hasClosed = stats.closedCalls > 0;
            final accStr = hasClosed ? '${stats.accuracyRate.toStringAsFixed(0)}%' : 'Active';

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trading Calls Accuracy: $accStr (${stats.targetAchieved} Target • ${stats.partiallyBooked} Partial • ${stats.stoplossHit} SL)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      reportController.selectedTabIndex.value = 0;
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'View',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 8,
                          color: Color(0xFF2563EB),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          Expanded(
            child: Obx(() {
              final reports = reportController.reports;

              if (reports.isEmpty && !reportController.isReportsLoading.value) {
                return RefreshIndicator(
                  onRefresh: () async {
                    await reportController.fetchReportList(refresh: true);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.description_outlined,
                              size: 80,
                              color: AppTheme.iconGrey,
                            ),
                            SizedBox(height: 16),
                            Text('No reports available', style: AppStyles.bodyLarge),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              return NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (!reportController.isReportsLoadingMore.value &&
                      reportController.reportsHasMore.value &&
                      scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent - 200) {
                    reportController.loadMoreReports();
                  }
                  return false;
                },
                child: RefreshIndicator(
                  onRefresh: () async {
                    await reportController.fetchReportList(refresh: true);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        reports.length +
                        (reportController.isReportsLoadingMore.value ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == reports.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final report = reports[index];
                      return ReportCard(
                        title: report.title,
                        category: report.category,
                        date: report.formattedDateTime,
                        description: report.description,
                        isLocked: report.isLocked,
                        updates: report.updates,
                        onTap: () {
                          Get.to(() => ReportDetailScreen(report: report));
                        },
                        onView: () {
                          Get.to(() => ReportDetailScreen(report: report));
                        },
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      );
    });
  }
}
