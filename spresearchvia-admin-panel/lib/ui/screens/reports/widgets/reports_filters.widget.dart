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
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.gray200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: Obx(() {
                      final seenCatIds = <String>{};
                      final validCats = controller.categories.where((cat) {
                        final id = (cat['_id'] ?? cat['id'])?.toString();
                        return id != null && id.isNotEmpty && seenCatIds.add(id);
                      }).toList();

                      final currentCat = controller.categoryFilter.value;
                      final safeCatValue = (currentCat == 'All Categories' || validCats.any((cat) => (cat['_id'] ?? cat['id'])?.toString() == currentCat))
                          ? currentCat
                          : 'All Categories';

                      return DropdownButton<String>(
                        value: safeCatValue,
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
                          const DropdownMenuItem<String>(
                            value: 'All Categories',
                            child: Text('All Categories'),
                          ),
                          ...validCats.map((cat) {
                            final catId = (cat['_id'] ?? cat['id'])?.toString() ?? '';
                            final catName = (cat['segmentName'] ?? cat['name'] ?? 'Unknown').toString();
                            return DropdownMenuItem<String>(
                              value: catId,
                              child: Text(catName),
                            );
                          }),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            controller.categoryFilter.value = v;
                            controller.applyFilters();
                          }
                        },
                      );
                    }),
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
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.gray200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: Obx(() {
                      final seenPlanIds = <String>{};
                      final validPlans = controller.allPlans.where((plan) {
                        final id = (plan['id'] ?? plan['_id'])?.toString();
                        return id != null && id.isNotEmpty && seenPlanIds.add(id);
                      }).toList();

                      final currentPlan = controller.planFilter.value;
                      final safePlanValue = (currentPlan == 'All Plans' || validPlans.any((p) => (p['id'] ?? p['_id'])?.toString() == currentPlan))
                          ? currentPlan
                          : 'All Plans';

                      return DropdownButton<String>(
                        value: safePlanValue,
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
                          const DropdownMenuItem<String>(
                            value: 'All Plans',
                            child: Text(
                              'All Plans',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ...validPlans.map((plan) {
                            final planId = (plan['id'] ?? plan['_id'])?.toString() ?? '';
                            final planName = (plan['name'] ?? 'Unknown').toString();
                            return DropdownMenuItem<String>(
                              value: planId,
                              child: Text(
                                planName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            controller.planFilter.value = v;
                            controller.applyFilters();
                          }
                        },
                      );
                    }),
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
