import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/dashboard/dashboard.controller.dart';

import 'filter_dropdown_field.widget.dart';
import 'filter_text_field.widget.dart';
import 'sales_metrics_cards.widget.dart';
import 'sales_metrics_chart.widget.dart';
import 'staff_orders_table.widget.dart';
import 'staff_sales_leaderboard.widget.dart';
import '../../../widgets/button.widget.dart';

class SalesPerformanceSection extends StatelessWidget {
  final DashboardController controller;

  const SalesPerformanceSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Admin Sales Performance Metric Cards (Matrices Cart)
        const SalesMetricsCards(),

        const SizedBox(height: 24),

        // 2. Interactive Staff Sales Charts (Matrices Chart)
        const SalesMetricsChart(),

        const SizedBox(height: 24),

        // 3. Main Data Tables Container
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.white,
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
              // Header & Refresh Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tab Toggle Buttons
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

                  IconButton(
                    onPressed: () => controller.refreshData(),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    tooltip: 'Refresh Sales Performance Data',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Filter Controls Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.gray50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.gray200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: FilterTextField(
                        label: 'Search',
                        hint: 'Search staff, client, plan, order ID...',
                        icon: Icons.search_rounded,
                        onChanged: (v) => controller.searchQuery.value = v,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Obx(
                        () => FilterDropdownField(
                          label: 'Order Status',
                          value: controller.selectedRenewalStatus.value,
                          items: const ['All', 'Active', 'Paid', 'Pending', 'Expired'],
                          onChanged: (v) =>
                              controller.selectedRenewalStatus.value = v!,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Obx(
                        () => FilterDropdownField(
                          label: 'Date Range',
                          value: controller.selectedDateFilter.value,
                          items: const [
                            'All Time',
                            'Today',
                            'This Week',
                            'This Month',
                          ],
                          onChanged: (v) =>
                              controller.selectedDateFilter.value = v!,
                          icon: Icons.calendar_today_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Obx(
                        () => FilterDropdownField(
                          label: 'Staff Member',
                          value: controller.selectedManagerFilter.value,
                          items: controller.managerFilterItems,
                          onChanged: (v) =>
                              controller.selectedManagerFilter.value = v!,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        const SizedBox(height: 18),
                        Button(
                          title: 'Reset',
                          buttonType: ButtonType.grey,
                          onTap: controller.resetFilters,
                        ),
                      ],
                    ),
                  ],
                ),
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
        ),
      ],
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
