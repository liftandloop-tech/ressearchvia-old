import 'package:flutter/material.dart';
// Refresh
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/dashboard/dashboard.controller.dart';
import '../../../widgets/button.widget.dart';
import '../../../widgets/date_picker.widget.dart';
import 'filter_text_field.widget.dart';
import 'filter_dropdown_field.widget.dart';

class RenewalsFilters extends StatelessWidget {
  final DashboardController controller;

  const RenewalsFilters({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FilterTextField(
                  label: 'Search',
                  hint: 'Search by customer name, mobile...',
                  icon: Icons.search,
                  onChanged: (value) => controller.searchQuery.value = value,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(
                  () => FilterDropdownField(
                    label: 'KYC Status',
                    value: controller.selectedRenewalStatus.value,
                    items: const [
                      'All',
                      'Verified',
                      'Rejected',
                      'Waiting_for_review',
                      'In_progress',
                      'Not_started',
                    ],
                    onChanged: (v) =>
                        controller.selectedRenewalStatus.value = v!,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(
                  () => FilterDropdownField(
                    label: 'Date Filter',
                    value: controller.selectedDateFilter.value,
                    items: const [
                      'All Time',
                      'Today',
                      'This Week',
                      'This Month',
                    ],
                    onChanged: (v) => controller.selectedDateFilter.value = v!,
                    icon: Icons.calendar_today_outlined,
                    onTap: () {
                      showCustomDatePicker(
                        context: context,
                        title: 'Select Date',
                        onConfirm: (date) {
                          // Format date as needed, for now just simple string
                          controller.selectedDateFilter.value =
                              "${date.day}/${date.month}/${date.year}";
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(
                  () => FilterDropdownField(
                    label: 'Manager Filter',
                    value: controller.selectedManagerFilter.value,
                    items: controller.managerFilterItems,
                    onChanged: (v) =>
                        controller.selectedManagerFilter.value = v!,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(' ', style: TextStyle(fontSize: 13, height: 1.5)),
                  const SizedBox(height: 8),
                  Button(
                    title: 'Reset',
                    buttonType: ButtonType.grey,
                    onTap: controller.resetFilters,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
