import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/user_management.controller.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/ui/widgets/searchable_manager_dialog.widget.dart';
import '../../../../models/user.model.dart';

class TableManagerDropdown extends StatelessWidget {
  final UserModel user;

  const TableManagerDropdown({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final userManagementController = Get.find<UserManagementController>();
    final authController = Get.find<AuthController>();
    final currentUser = authController.user.value;
    final isAdmin = currentUser?.isAdmin == true;
    final canAssign = isAdmin ||
        (currentUser?.has('staff.assignment') ?? false) ||
        (currentUser?.has('staff.update') ?? false) ||
        (currentUser?.has('users.update') ?? false);

    return Obx(() {
      final rawManagers = userManagementController.managers;
      final seenIds = <String>{};
      final managers = rawManagers.where((m) => m.id.isNotEmpty && seenIds.add(m.id)).toList();
      final currentManagerId = user.managerId;
      final matchedManager = managers.firstWhereOrNull((m) => m.id == currentManagerId);
      final managerName = matchedManager?.name ?? user.manager ?? 'Unassigned';
      final isAssigned = matchedManager != null || (user.manager != null && user.manager!.isNotEmpty);

      return InkWell(
        onTap: canAssign
            ? () {
                showDialog(
                  context: context,
                  builder: (ctx) => SearchableManagerDialog(
                    clientName: user.fullName,
                    currentManagerId: currentManagerId,
                    staffList: managers,
                    onSelected: (staffId, staffName) {
                      userManagementController.assignManager(user.id, staffId);
                    },
                    onUnassign: () {
                      userManagementController.assignManager(user.id, 'unassigned');
                    },
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isAssigned ? const Color(0xFFF8FAFC) : Colors.white,
            border: Border.all(color: isAssigned ? const Color(0xFFCBD5E1) : AppTheme.gray300),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      managerName,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isAssigned ? const Color(0xFF0F172A) : AppTheme.gray500,
                        fontWeight: isAssigned ? FontWeight.w600 : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (matchedManager != null && matchedManager.department.isNotEmpty)
                      Text(
                        matchedManager.department,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (canAssign) ...[
                const SizedBox(width: 4),
                Icon(Icons.search, size: 14, color: AppTheme.gray500),
              ],
            ],
          ),
        ),
      );
    });
  }
}
