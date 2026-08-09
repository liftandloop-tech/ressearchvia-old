import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/report.controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_styles.dart';

import 'report_card.dart';
import '../report_detail.screen.dart';

class TradingCallTab extends StatelessWidget {
  final ReportController reportController;

  const TradingCallTab({super.key, required this.reportController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (reportController.isTradingCallsLoading.value &&
          reportController.tradingCalls.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        );
      }

      if (reportController.tradingCalls.isEmpty) {
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 72,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No active Research plans',
                  textAlign: TextAlign.center,
                  style: AppStyles.heading2,
                ),
                const SizedBox(height: 12),
                Text(
                  'Trading calls Access requires an active Research plan.',
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppTheme.textGrey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.toNamed('/quick-renewal');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: AppTheme.backgroundWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Browse Plans',
                      style: AppStyles.button,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!reportController.isTradingCallsLoadingMore.value &&
              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            reportController.loadMoreTradingCalls();
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: () async {
            await reportController.fetchTradingCalls(refresh: true);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount:
                reportController.tradingCalls.length +
                (reportController.isTradingCallsLoadingMore.value ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == reportController.tradingCalls.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final report = reportController.tradingCalls[index];
              return ReportCard(
                title: report.title,
                category: report.category,
                date: report.formattedDateTime,
                description: report.description,
                isLocked: report.isLocked,
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
    });
  }
}
