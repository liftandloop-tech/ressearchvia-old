import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/report.controller.dart';
import '../../../core/models/research_report.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_styles.dart';

import 'report_card.dart';
import 'trading_accuracy_card.dart';
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
        if (!reportController.hasActiveSubscription.value) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.05),
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

        return Center(
          child: RefreshIndicator(
            onRefresh: () async {
              await reportController.fetchTradingCalls(refresh: true);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.candlestick_chart_outlined,
                    size: 80,
                    color: AppTheme.iconGrey,
                  ),
                  SizedBox(height: 16),
                  Text('No trading calls available', style: AppStyles.bodyLarge),
                ],
              ),
            ),
          ),
        );
      }

      final stats = reportController.effectiveAccuracy;
      final displayCalls = reportController.filteredTradingCalls;
      final selectedFilter = reportController.selectedOutcomeFilter.value;

      return NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!reportController.isTradingCallsLoadingMore.value &&
              reportController.tradingCallsHasMore.value &&
              selectedFilter == null &&
              scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            reportController.loadMoreTradingCalls();
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: () async {
            await reportController.fetchTradingCalls(refresh: true);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 1 + (displayCalls.isEmpty ? 1 : displayCalls.length) +
                (reportController.isTradingCallsLoadingMore.value && selectedFilter == null ? 1 : 0),
            itemBuilder: (context, index) {
              // Item 0: Accuracy Card & Filter Chips Header
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TradingAccuracyCard(
                        stats: stats,
                        title: 'Trading Calls Accuracy',
                        subtitle: 'Target Achieved • Partially Booked • Stoploss',
                        selectedOutcome: selectedFilter,
                        onSelectOutcome: (outcome) {
                          reportController.selectedOutcomeFilter.value = outcome;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildFilterChips(stats),
                    ],
                  ),
                );
              }

              // Empty Filter Result State
              if (displayCalls.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_alt_off_outlined,
                          size: 48,
                          color: AppTheme.textGrey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No calls found for selected filter',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            reportController.selectedOutcomeFilter.value = null;
                          },
                          icon: const Icon(Icons.clear_all_rounded, size: 16),
                          label: const Text('Show All Calls'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryBlue,
                            textStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Loading indicator at bottom
              final callIndex = index - 1;
              if (callIndex == displayCalls.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final report = displayCalls[callIndex];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ReportCard(
                  title: report.title,
                  category: report.category,
                  date: report.formattedDateTime,
                  description: report.description,
                  isLocked: report.isLocked,
                  updates: report.updates,
                  outcome: report.outcome,
                  onTap: () {
                    Get.to(() => ReportDetailScreen(report: report));
                  },
                  onView: () {
                    Get.to(() => ReportDetailScreen(report: report));
                  },
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildFilterChips(TradingAccuracyStats stats) {
    final selected = reportController.selectedOutcomeFilter.value;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(
            label: 'All (${stats.totalCalls})',
            isSelected: selected == null,
            color: AppTheme.primaryBlue,
            onTap: () => reportController.selectedOutcomeFilter.value = null,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Target Hit (${stats.targetAchieved})',
            isSelected: selected == TradingCallOutcome.targetAchieved,
            color: const Color(0xFF16A34A),
            onTap: () => reportController.selectedOutcomeFilter.value =
                selected == TradingCallOutcome.targetAchieved ? null : TradingCallOutcome.targetAchieved,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Partially Booked (${stats.partiallyBooked})',
            isSelected: selected == TradingCallOutcome.partiallyBooked,
            color: const Color(0xFFEA580C),
            onTap: () => reportController.selectedOutcomeFilter.value =
                selected == TradingCallOutcome.partiallyBooked ? null : TradingCallOutcome.partiallyBooked,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Stoploss Hit (${stats.stoplossHit})',
            isSelected: selected == TradingCallOutcome.stoplossHit,
            color: const Color(0xFFDC2626),
            onTap: () => reportController.selectedOutcomeFilter.value =
                selected == TradingCallOutcome.stoplossHit ? null : TradingCallOutcome.stoplossHit,
          ),
          if (stats.active > 0) ...[
            const SizedBox(width: 8),
            _buildChip(
              label: 'Active (${stats.active})',
              isSelected: selected == TradingCallOutcome.active,
              color: AppTheme.primaryBlueDark,
              onTap: () => reportController.selectedOutcomeFilter.value =
                  selected == TradingCallOutcome.active ? null : TradingCallOutcome.active,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
