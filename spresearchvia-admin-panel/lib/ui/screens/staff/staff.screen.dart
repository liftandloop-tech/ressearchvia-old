import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';
import 'package:spresearch_web/controllers/staff/staff.controller.dart';
import 'package:spresearch_web/ui/layouts/dashboard_layout.widget.dart';
import 'package:spresearch_web/ui/widgets/skeleton_loader.widget.dart';
import '../../widgets/button.widget.dart';
import 'widgets/staff_table.widget.dart';
import 'widgets/staff_pagination.widget.dart';

class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<StaffController>()
        ? Get.find<StaffController>()
        : Get.put(StaffController(), permanent: true);

    return DashboardLayout(
      child: Container(
        color: AppTheme.gray50,
        child: Obx(() {
          if (controller.isLoading.value && controller.staffList.isEmpty) {
            return const ScreenSkeleton(hasFilterBar: true, rowCount: 8);
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 700;
                          final actions = Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Obx(() {
                                final hasActiveFilters = controller.filterName.value.isNotEmpty ||
                                    controller.filterMobile.value.isNotEmpty ||
                                    controller.filterEmail.value.isNotEmpty ||
                                    controller.filterSelectedRoles.isNotEmpty ||
                                    controller.filterSelectedStatuses.isNotEmpty;
                                if (!hasActiveFilters) return const SizedBox.shrink();
                                return TextButton.icon(
                                  onPressed: () => controller.clearAllFilters(),
                                  icon: const Icon(Icons.clear_all, color: AppTheme.errorRed, size: 18),
                                  label: const Text(
                                    'Clear Filters',
                                    style: TextStyle(color: AppTheme.errorRed, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                );
                              }),
                              IconButton(
                                onPressed: () => controller.fetchStaffList(),
                                icon: Icon(
                                  Icons.refresh,
                                  color: AppTheme.primaryBlue,
                                ),
                                tooltip: 'Refresh Staff List',
                              ),
                              Button(
                                title: AppStrings.addNewStaff,
                                buttonType: ButtonType.green,
                                icon: Icons.add,
                                onTap: () {
                                  controller.resetForm();
                                  Get.toNamed('/staff/create');
                                },
                              ),
                            ],
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => Get.back(),
                                      icon: Icon(
                                        Icons.arrow_back,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        AppStrings.staffManagement,
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                actions,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              IconButton(
                                onPressed: () => Get.back(),
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppStrings.staffManagement,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              actions,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Active Filter Chips
                      Obx(() {
                        final chips = <Widget>[];
                        
                        if (controller.filterName.value.isNotEmpty) {
                          chips.add(Chip(
                            label: Text('Name: ${controller.filterName.value}', style: const TextStyle(fontSize: 12)),
                            onDeleted: () => controller.filterName.value = '',
                            backgroundColor: AppTheme.gray100,
                            deleteIconColor: AppTheme.errorRed,
                          ));
                        }
                        if (controller.filterMobile.value.isNotEmpty) {
                          chips.add(Chip(
                            label: Text('Mobile: ${controller.filterMobile.value}', style: const TextStyle(fontSize: 12)),
                            onDeleted: () => controller.filterMobile.value = '',
                            backgroundColor: AppTheme.gray100,
                            deleteIconColor: AppTheme.errorRed,
                          ));
                        }
                        if (controller.filterEmail.value.isNotEmpty) {
                          chips.add(Chip(
                            label: Text('Email: ${controller.filterEmail.value}', style: const TextStyle(fontSize: 12)),
                            onDeleted: () => controller.filterEmail.value = '',
                            backgroundColor: AppTheme.gray100,
                            deleteIconColor: AppTheme.errorRed,
                          ));
                        }
                        for (final role in controller.filterSelectedRoles) {
                          chips.add(Chip(
                            label: Text('Role: $role', style: const TextStyle(fontSize: 12)),
                            onDeleted: () => controller.filterSelectedRoles.remove(role),
                            backgroundColor: AppTheme.gray100,
                            deleteIconColor: AppTheme.errorRed,
                          ));
                        }
                        for (final status in controller.filterSelectedStatuses) {
                          chips.add(Chip(
                            label: Text('Status: $status', style: const TextStyle(fontSize: 12)),
                            onDeleted: () => controller.filterSelectedStatuses.remove(status),
                            backgroundColor: AppTheme.gray100,
                            deleteIconColor: AppTheme.errorRed,
                          ));
                        }

                        if (chips.isEmpty) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: chips,
                            ),
                          ),
                        );
                      }),
                      // Staff Table Card
                      Obx(() {
                        final paginatedList = controller.paginatedStaffList;
                        final filteredList = controller.filteredStaffList;
                        return Container(
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.gray200),
                          ),
                          child: paginatedList.isEmpty
                              ? _buildEmptyState()
                              : Column(
                                  children: [
                                    StaffTable(
                                      staffList: paginatedList,
                                      onEdit: (staff) {
                                        controller.populateForEdit(staff);
                                        Get.toNamed('/staff/edit/${staff.id}');
                                      },
                                      onStatusToggle: (staff, isActive) =>
                                          controller.toggleStaffStatus(staff.id, isActive),
                                    ),
                                    StaffPagination(
                                      title: 'Staff',
                                      currentPage: controller.currentPage.value,
                                      totalPages: controller.totalPages,
                                      totalItems: filteredList.length,
                                      itemsPerPage: controller.itemsPerPage,
                                      currentItemsCount: paginatedList.length,
                                      onPageChange: (page) =>
                                          controller.currentPage.value = page,
                                    ),
                                  ],
                                ),
                        );
                      }),
                    ],
                  ),
                ),
                if (controller.isLoading.value)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: AppTheme.primaryBlue,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
              ],
            );
          }),
        ),
      );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppTheme.gray400),
          const SizedBox(height: 16),
          const Text(
            'No staff members found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters or add a new staff member',
            style: TextStyle(fontSize: 14, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }
}
