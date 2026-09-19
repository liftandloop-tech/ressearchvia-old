import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/staff/staff.controller.dart';
import '../../../../models/staff.model.dart';

class TableReportingToDropdown extends StatelessWidget {
  final StaffModel staff;

  const TableReportingToDropdown({super.key, required this.staff});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StaffController>();

    return Obx(() {
      final allStaff = controller.staffList;
      // Filter out self so staff member cannot report to themselves
      final potentialSupervisors = allStaff
          .where((s) => s.id.isNotEmpty && s.id != staff.id)
          .toList();

      final currentSupervisorId = staff.assignedDirector;

      // Determine selected value
      String selectedValue;
      if (currentSupervisorId != null &&
          currentSupervisorId.isNotEmpty &&
          currentSupervisorId != 'admin' &&
          potentialSupervisors.any((s) => s.id == currentSupervisorId)) {
        selectedValue = currentSupervisorId;
      } else {
        selectedValue = 'admin';
      }

      return Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.white,
          border: Border.all(color: AppTheme.gray300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedValue,
            isExpanded: true,
            isDense: true,
            itemHeight: 52.0,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AppTheme.gray600,
            ),
            selectedItemBuilder: (context) {
              return [
                // Admin selected preview
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Flexible(
                        child: Text(
                          'Direct',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Other staff selected previews
                ...potentialSupervisors.map((s) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      s.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }),
              ];
            },
            items: [
              // Default option: Admin
              DropdownMenuItem<String>(
                value: 'admin',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Flexible(
                      child: Text(
                        'Admin (Direct / Default)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Staff supervisor options
              ...potentialSupervisors.map((s) {
                final roleName = s.department.isNotEmpty ? s.department : s.role;
                return DropdownMenuItem<String>(
                  value: s.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        roleName,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.gray500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }),
            ],
            onChanged: (newVal) {
              if (newVal == null) return;
              if (newVal == 'admin') {
                controller.assignSupervisor(staff.id, 'admin', 'Admin');
              } else {
                final selectedSup = potentialSupervisors.firstWhereOrNull(
                  (s) => s.id == newVal,
                );
                if (selectedSup != null) {
                  controller.assignSupervisor(
                    staff.id,
                    selectedSup.id,
                    selectedSup.name,
                  );
                }
              }
            },
          ),
        ),
      );
    });
  }
}
