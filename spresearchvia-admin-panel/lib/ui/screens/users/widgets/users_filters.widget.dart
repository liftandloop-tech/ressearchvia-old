import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/user.controller.dart';
import 'package:spresearch_web/ui/widgets/button.widget.dart';
import 'filter_dropdown.widget.dart';
import '../../../widgets/date_picker.widget.dart';

class UsersFilters extends StatelessWidget {
  const UsersFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserController>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.searchController,
                  onSubmitted: (_) => controller.applyFilters(),
                  decoration: AppTheme.inputDecoration(
                    'Search Client Name, Pan, Email or Phone',
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  style: AppTheme.inputStyle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilterDropdown(
                  label: 'Registration Status',
                  value: controller.planTypeFilter,
                  items: const [
                    'All Statuses',
                    'Silver',
                    'Gold',
                    'Pending for Approval',
                    'Not Registered',
                  ],
                  onChanged: (v) {
                    controller.planTypeFilter.value = v!;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilterDropdown(
                  label: 'KYC Status',
                  value: controller.kycStatusFilter,
                  items: const [
                    'All',
                    'Verified',
                    'Rejected',
                    'Waiting_for_review',
                    'In_progress',
                    'Not_started',
                  ],
                  onChanged: (v) {
                    controller.kycStatusFilter.value = v!;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Created At',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => InkWell(
                        onTap: () {
                          showCustomDatePicker(
                            context: context,
                            title: 'Select Date',
                            onConfirm: (date) {
                              controller.registrationDateFilter.value =
                                  "${date.day}/${date.month}/${date.year}";
                            },
                          );
                        },
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.gray300),
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  controller
                                          .registrationDateFilter
                                          .value
                                          .isEmpty
                                      ? 'dd/mm/yyyy'
                                      : controller.registrationDateFilter.value,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        controller
                                            .registrationDateFilter
                                            .value
                                            .isEmpty
                                        ? AppTheme.gray400
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: AppTheme.gray600,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
                    icon: Icons.refresh,
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
