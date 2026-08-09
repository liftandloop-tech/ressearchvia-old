import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';
import 'package:spresearch_web/controllers/staff/staff.controller.dart';
import 'package:spresearch_web/ui/layouts/dashboard_layout.widget.dart';
import '../../widgets/button.widget.dart';
import 'widgets/staff_section.widget.dart';
import 'widgets/add_staff_dialog.widget.dart';

class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StaffController());

    return DashboardLayout(
      child: Container(
        color: AppTheme.gray50,
        child: Obx(
          () => controller.isLoading.value
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryBlue,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () => Get.back(),
                            icon: Icon(
                              Icons.arrow_back,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.staffManagement,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => controller.fetchStaffList(),
                                icon: Icon(
                                  Icons.refresh,
                                  color: AppTheme.primaryBlue,
                                ),
                                tooltip: 'Refresh Staff List',
                              ),
                              const SizedBox(width: 8),
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Obx(
                        () => controller.isAdminLoggedIn
                            ? Column(
                                children: [
                                  StaffSection(
                                    title: AppStrings.researchers,
                                    count: controller.allResearchers.length,
                                    isExpanded:
                                        controller.researchersExpanded.value,
                                    onToggle: () =>
                                        controller.researchersExpanded.toggle(),
                                    subtitle: AppStrings.researchTeam,
                                    paginatedStaff:
                                        controller.paginatedResearchers,
                                    currentPage:
                                        controller.researchersPage.value,
                                    totalPages:
                                        controller.researchersTotalPages,
                                    totalItems:
                                        controller.allResearchers.length,
                                    itemsPerPage: controller.itemsPerPage,
                                    onPageChange: (page) =>
                                        controller.researchersPage.value = page,
                                    onEdit: (staff) {
                                      controller.populateForEdit(staff);
                                      showDialog(
                                        context: context,
                                        builder: (context) => AddStaffDialog(
                                          controller: controller,
                                        ),
                                      );
                                    },
                                    onDelete: (staff) {
                                      controller.deleteStaff(
                                        staff.id,
                                        staff.name,
                                      );
                                    },
                                    onStatusToggle: (staff, isActive) =>
                                        controller.toggleStaffStatus(
                                          staff.id,
                                          isActive,
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                      Obx(
                        () => StaffSection(
                          title: AppStrings.directors,
                          count: controller.availableDirectors.length,
                          isExpanded: controller.directorsExpanded.value,
                          onToggle: () => controller.directorsExpanded.toggle(),
                          subtitle: AppStrings.managementTeam,
                          paginatedStaff: controller.paginatedDirectors,
                          currentPage: controller.directorsPage.value,
                          totalPages: controller.directorsTotalPages,
                          totalItems: controller.availableDirectors.length,
                          itemsPerPage: controller.itemsPerPage,
                          onPageChange: (page) =>
                              controller.directorsPage.value = page,
                          onEdit: (staff) {
                            controller.populateForEdit(staff);
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  AddStaffDialog(controller: controller),
                            );
                          },
                          onDelete: (staff) {
                            controller.deleteStaff(staff.id, staff.name);
                          },
                          onStatusToggle: (staff, isActive) =>
                              controller.toggleStaffStatus(staff.id, isActive),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(
                        () => StaffSection(
                          title: AppStrings.managers,
                          count: controller.allManagers.length,
                          isExpanded: controller.managersExpanded.value,
                          onToggle: () => controller.managersExpanded.toggle(),
                          subtitle: AppStrings.operationsTeam,
                          paginatedStaff: controller.paginatedManagers,
                          currentPage: controller.managersPage.value,
                          totalPages: controller.managersTotalPages,
                          totalItems: controller.allManagers.length,
                          itemsPerPage: controller.itemsPerPage,
                          onPageChange: (page) =>
                              controller.managersPage.value = page,
                          onEdit: (staff) {
                            // No need to populate manually, screen handles it via ID
                            Get.toNamed('/staff/edit/${staff.id}');
                          },
                          onDelete: (staff) {
                            controller.deleteStaff(staff.id, staff.name);
                          },
                          onStatusToggle: (staff, isActive) =>
                              controller.toggleStaffStatus(staff.id, isActive),
                        ),
                      ),
                      Obx(
                        () => controller.otherStaff.isNotEmpty
                            ? Column(
                                children: [
                                  const SizedBox(height: 16),
                                  StaffSection(
                                    title: 'Other Staff',
                                    count: controller.otherStaff.length,
                                    isExpanded: controller.otherStaffExpanded.value,
                                    onToggle: () => controller.otherStaffExpanded.toggle(),
                                    subtitle: 'Other Department Staff',
                                    paginatedStaff: controller.paginatedOtherStaff,
                                    currentPage: controller.otherStaffPage.value,
                                    totalPages: controller.otherStaffTotalPages,
                                    totalItems: controller.otherStaff.length,
                                    itemsPerPage: controller.itemsPerPage,
                                    onPageChange: (page) =>
                                        controller.otherStaffPage.value = page,
                                    onEdit: (staff) {
                                      Get.toNamed('/staff/edit/${staff.id}');
                                    },
                                    onDelete: (staff) {
                                      controller.deleteStaff(staff.id, staff.name);
                                    },
                                    onStatusToggle: (staff, isActive) =>
                                        controller.toggleStaffStatus(staff.id, isActive),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
