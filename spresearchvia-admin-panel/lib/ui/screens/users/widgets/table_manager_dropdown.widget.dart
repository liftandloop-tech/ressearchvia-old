import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/user.controller.dart';
import 'package:spresearch_web/controllers/users/user_management.controller.dart';
import '../../../../models/user.model.dart';
import '../../../../models/staff.model.dart';

class TableManagerDropdown extends StatelessWidget {
  final UserModel user;

  const TableManagerDropdown({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final userManagementController = Get.find<UserManagementController>();
    // final controller = Get.find<UserController>(); // UserManagementController handles this now

    return Obx(() {
      final managers = userManagementController.managers;
      final currentManagerId = user.managerId;

      // Ensure we have a valid selection
      // If user has a managerId that exists in managers list, use it.
      // Else use 'unassigned'.
      String? selectedValue;
      if (currentManagerId != null &&
          managers.any((m) => m.id == currentManagerId)) {
        selectedValue = currentManagerId;
      } else {
        selectedValue = 'unassigned';
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.white,
          border: Border.all(color: AppTheme.gray300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedValue,
            isExpanded: true,
            itemHeight: null,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AppTheme.gray600,
            ),
            selectedItemBuilder: (context) {
              return [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Unassigned',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                ...managers.map((m) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          m.name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          m.department.isNotEmpty ? m.department : 'Unassigned',
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
              ];
            },
            items: [
              const DropdownMenuItem<String>(
                value: 'unassigned',
                child: Text(
                  'Unassigned',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              ...managers.map(
                (m) => DropdownMenuItem<String>(
                  value: m.id,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          m.name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m.department.isNotEmpty ? m.department : 'Unassigned',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.gray500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null && value != 'unassigned') {
                userManagementController.assignManager(user.id, value);
              }
            },
          ),
        ),
      );
    });
  }
}
