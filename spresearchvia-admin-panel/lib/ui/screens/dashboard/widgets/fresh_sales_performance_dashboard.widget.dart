import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/dashboard/dashboard.controller.dart';
import 'package:spresearch_web/ui/widgets/compact_date_range_picker.widget.dart';
import 'filter_dropdown_field.widget.dart';
import 'sales_metrics_cards.widget.dart';
import 'staff_orders_table.widget.dart';
import 'staff_sales_leaderboard.widget.dart';

class FreshSalesPerformanceDashboard extends StatelessWidget {
  const FreshSalesPerformanceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : Get.put(DashboardController(), permanent: true);

    return Container(
      color: AppTheme.gray50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Dashboard Header
            _buildDashboardHeader(controller),

            const SizedBox(height: 24),

            // 2. Control Filters & Dropdowns Bar
            _buildDropdownsFilterBar(context, controller),

            const SizedBox(height: 24),

            // 3. Sales Performance Cards ("Matrices Cart")
            const SalesMetricsCards(),

            const SizedBox(height: 24),

            // 4. Data Tables (Leaderboard & Orders)
            _buildDataTableSection(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHeader(DashboardController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => Text(
                controller.isAdmin
                    ? 'Overall Sales & Staff Performance'
                    : (controller.hasTeamMembers
                        ? 'Team Sales & Performance Dashboard'
                        : 'My Sales & Performance'),
                style: AppTheme.h1Style.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Obx(
              () => Text(
                controller.isAdmin
                    ? 'Live performance analytics, sales metric cards, staff leaderboard & orders monitoring.'
                    : (controller.hasTeamMembers
                        ? 'Live team performance analytics, sales metric cards, team leaderboard & orders monitoring.'
                        : 'Live personal performance analytics, sales metric cards, your leaderboard & orders monitoring.'),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () => controller.refreshData(),
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  size: 22,
                  color: AppTheme.primaryBlue,
                ),
              ),
              tooltip: 'Refresh Performance Data',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownsFilterBar(
    BuildContext context,
    DashboardController controller,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 15, color: AppTheme.primaryBlue),
              const SizedBox(width: 6),
              const Text(
                'Performance Filters & Controls',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  SizedBox(
                    width: 175,
                    child: Obx(
                      () => FilterDropdownField(
                        label: 'Staff Member',
                        value: controller.selectedManagerFilter.value,
                        items: controller.managerFilterItems,
                        onChanged: (v) =>
                            controller.selectedManagerFilter.value = v!,
                        height: 36,
                        fontSize: 12,
                        labelFontSize: 11.5,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: Obx(
                      () => FilterDropdownField(
                        label: 'Department',
                        value: controller.selectedDepartmentFilter.value,
                        items: controller.departmentFilterItems,
                        onChanged: (v) =>
                            controller.selectedDepartmentFilter.value = v!,
                        height: 36,
                        fontSize: 12,
                        labelFontSize: 11.5,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 155,
                    child: Obx(
                      () => FilterDropdownField(
                        label: 'Date Range',
                        value: controller.selectedDateFilter.value,
                        items: const [
                          'Today',
                          'This Week',
                          'This Month',
                          'This Quarter',
                          'Custom',
                          'All Time',
                        ],
                        onChanged: (v) async {
                          if (v == null) return;
                          if (v == 'Custom') {
                            controller.setDateFilter('Custom');
                            final picked = await showCompactDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              initialDateRange: (controller.startDate.value != null &&
                                      controller.endDate.value != null)
                                  ? DateTimeRange(
                                      start: controller.startDate.value!,
                                      end: controller.endDate.value!,
                                    )
                                  : DateTimeRange(
                                      start: DateTime(DateTime.now().year, DateTime.now().month, 1),
                                      end: DateTime.now(),
                                    ),
                            );
                            if (picked != null) {
                              controller.setCustomDateRange(picked.start, picked.end);
                            }
                          } else {
                            controller.setDateFilter(v);
                          }
                        },
                        height: 36,
                        fontSize: 12,
                        labelFontSize: 11.5,
                      ),
                    ),
                  ),
                  Obx(() {
                    if (controller.selectedDateFilter.value == 'Custom') {
                      final start = controller.startDate.value;
                      final end = controller.endDate.value;
                      String customDateText = "Select Dates";
                      if (start != null && end != null) {
                        customDateText =
                            "${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM').format(end)}";
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Custom Dates',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 36,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor: AppTheme.primaryBlue,
                                side: BorderSide(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                backgroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                final picked = await showCompactDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                  initialDateRange: (start != null && end != null)
                                      ? DateTimeRange(start: start, end: end)
                                      : DateTimeRange(
                                          start: DateTime(DateTime.now().year, DateTime.now().month, 1),
                                          end: DateTime.now(),
                                        ),
                                );
                                if (picked != null) {
                                  controller.setCustomDateRange(picked.start, picked.end);
                                }
                              },
                              icon: const Icon(Icons.date_range_rounded, size: 14),
                              label: Text(
                                customDateText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  SizedBox(
                    width: 130,
                    child: Obx(
                      () => FilterDropdownField(
                        label: 'Order Status',
                        value: controller.selectedRenewalStatus.value,
                        items: const [
                          'All',
                          'Active',
                          'Paid',
                          'Pending',
                          'Expired',
                        ],
                        onChanged: (v) =>
                            controller.selectedRenewalStatus.value = v!,
                        height: 36,
                        fontSize: 12,
                        labelFontSize: 11.5,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.gray700,
                        side: const BorderSide(color: AppTheme.gray300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        backgroundColor: Colors.white,
                      ),
                      icon: const Icon(
                        Icons.restart_alt_rounded,
                        size: 15,
                        color: AppTheme.gray600,
                      ),
                      label: const Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.gray700,
                        ),
                      ),
                      onPressed: controller.resetFilters,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }



  Widget _buildDataTableSection(DashboardController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab Toggle Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(
                () => Row(
                  children: [
                    _buildTabButton(
                      title: 'Staff Performance Leaderboard',
                      icon: Icons.leaderboard_rounded,
                      isSelected: controller.activeTab.value == 0,
                      onTap: () => controller.activeTab.value = 0,
                    ),
                    const SizedBox(width: 12),
                    _buildTabButton(
                      title: 'Staff Orders & Transactions',
                      icon: Icons.receipt_long_rounded,
                      isSelected: controller.activeTab.value == 1,
                      onTap: () => controller.activeTab.value = 1,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Active Table View
          Obx(() {
            if (controller.activeTab.value == 0) {
              return const StaffSalesLeaderboardTable();
            } else {
              return const StaffOrdersTable();
            }
          }),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue.withOpacity(0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.gray600,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.gray700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
