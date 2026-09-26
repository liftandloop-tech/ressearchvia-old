import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/dashboard/dashboard.controller.dart';
import '../../../widgets/button.widget.dart';
import 'filter_dropdown_field.widget.dart';
import 'filter_text_field.widget.dart';
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
      padding: const EdgeInsets.all(20),
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
          const Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: AppTheme.primaryBlue),
              SizedBox(width: 8),
              Text(
                'Performance Filters & Controls',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  SizedBox(
                    width: 260,
                    child: FilterTextField(
                      label: 'Search',
                      hint: 'Staff, client, plan, order ID...',
                      icon: Icons.search_rounded,
                      onChanged: (v) => controller.searchQuery.value = v,
                    ),
                  ),
                  SizedBox(
                    width: 170,
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
                  SizedBox(
                    width: 170,
                    child: Obx(
                      () => FilterDropdownField(
                        label: 'Department',
                        value: controller.selectedDepartmentFilter.value,
                        items: controller.departmentFilterItems,
                        onChanged: (v) =>
                            controller.selectedDepartmentFilter.value = v!,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 145,
                    child: _buildDateField(
                      context: context,
                      label: 'From Date',
                      placeholder: 'Start Date',
                      selectedDate: controller.startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    ),
                  ),
                  SizedBox(
                    width: 145,
                    child: _buildDateField(
                      context: context,
                      label: 'To Date',
                      placeholder: 'End Date',
                      selectedDate: controller.endDate,
                      firstDate: controller.startDate.value ?? DateTime(2020),
                      lastDate: DateTime(2035),
                    ),
                  ),
                  SizedBox(
                    width: 140,
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
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Button(
                      title: 'Reset',
                      buttonType: ButtonType.grey,
                      icon: Icons.restart_alt_rounded,
                      onTap: controller.resetFilters,
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

  Widget _buildDateField({
    required BuildContext context,
    required String label,
    required String placeholder,
    required Rxn<DateTime> selectedDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return Obx(() {
      final date = selectedDate.value;
      final displayDate =
          date != null ? DateFormat('dd MMM yyyy').format(date) : placeholder;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xff11416B),
            ),
          ),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date ?? DateTime.now(),
                firstDate: firstDate ?? DateTime(2020),
                lastDate: lastDate ?? DateTime(2035),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppTheme.primaryBlue,
                        onPrimary: Colors.white,
                        onSurface: AppTheme.gray900,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                selectedDate.value = picked;
              }
            },
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: date != null
                      ? AppTheme.primaryBlue
                      : const Color(0xffE5E7EB),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayDate,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            date != null ? FontWeight.w600 : FontWeight.w400,
                        color: date != null
                            ? const Color(0xff11416B)
                            : AppTheme.gray400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (date != null)
                    GestureDetector(
                      onTap: () => selectedDate.value = null,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.cancel_rounded,
                          size: 16,
                          color: AppTheme.gray400,
                        ),
                      ),
                    ),
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: Color(0xff11416B),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
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
