import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/reports/report.controller.dart';
import '../../../widgets/button.widget.dart';
import 'reports_filter_dropdown.widget.dart';
import 'reports_filter_date_field.widget.dart';

class ReportsFilters extends StatelessWidget {
  const ReportsFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReportController>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration.copyWith(
        border: Border.all(color: AppTheme.gray200, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.gray200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.categoryFilter.value,
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: AppTheme.textSecondary,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'All Categories',
                            child: Text('All Categories'),
                          ),
                          ...controller.categories.map((cat) {
                            return DropdownMenuItem<String>(
                              value: cat['_id'] as String,
                              child: Text(
                                cat['segmentName'] ?? cat['name'] ?? 'Unknown',
                              ),
                            );
                          }),
                        ],
                        onChanged: (v) {
                          controller.categoryFilter.value = v!;
                          controller.applyFilters();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.gray200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.planFilter.value,
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: AppTheme.textSecondary,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'All Plans',
                            child: Text(
                              'All Plans',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ...controller.allPlans.map((plan) {
                            return DropdownMenuItem<String>(
                              value: plan['id'] as String,
                              child: Text(
                                plan['name'] ?? 'Unknown',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (v) {
                          controller.planFilter.value = v!;
                          controller.applyFilters();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report Type',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => ReportsFilterDropdown(
                    value: controller.reportTypeFilter.value,
                    items: const [
                      'All Types',
                      'Trading calls',
                      'Detailed Reports',
                    ],
                    onChanged: (v) {
                      controller.reportTypeFilter.value = v!;
                      controller.applyFilters();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'From Date',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ReportsFilterDateField(
                  controller: controller.fromDateController,
                  onChanged: controller.applyFilters,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To Date',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ReportsFilterDateField(
                  controller: controller.toDateController,
                  onChanged: controller.applyFilters,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Button(
            title: 'Reset',
            buttonType: ButtonType.grey,
            onTap: controller.resetFilters,
          ),
        ],
      ),
    );
  }
}
