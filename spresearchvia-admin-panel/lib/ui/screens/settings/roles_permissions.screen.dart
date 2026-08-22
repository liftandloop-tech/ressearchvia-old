import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/theme.config.dart';
import '../../../controllers/settings/role_permission.controller.dart';
import '../../../models/permission_group.model.dart';
import '../../../models/role.model.dart';
import '../../layouts/dashboard_layout.widget.dart';

class RolesPermissionsScreen extends StatelessWidget {
  const RolesPermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RolePermissionController());

    return Container(
      color: AppTheme.gray50,
      child: Obx(
        () => controller.isLoading.value
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryBlue),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Get.back(),
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Roles & Dynamic Permissions',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Navigation Tabs
                    _buildTabs(controller),
                    const SizedBox(height: 24),

                    // Tab View Panels
                    controller.activeTab.value == 0
                        ? _buildRolesPanel(context, controller)
                        : _buildGroupsPanel(context, controller),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTabs(RolePermissionController controller) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.gray200, width: 1)),
      ),
      child: Row(
        children: [
          _buildTabItem(controller, index: 0, label: 'Roles'),
          _buildTabItem(controller, index: 1, label: 'Permission Groups'),
        ],
      ),
    );
  }

  Widget _buildTabItem(RolePermissionController controller, {required int index, required String label}) {
    final isSelected = controller.activeTab.value == index;
    return GestureDetector(
      onTap: () => controller.activeTab.value = index,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppTheme.primaryBlue : AppTheme.gray500,
          ),
        ),
      ),
    );
  }

  // --- ROLES TAB PANEL ---
  Widget _buildRolesPanel(BuildContext context, RolePermissionController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'User Roles Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            ElevatedButton.icon(
              onPressed: () => _showRoleDialog(context, controller),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Role'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisExtent: 220,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
          ),
          itemCount: controller.roles.length,
          itemBuilder: (context, idx) {
            final role = controller.roles[idx];
            return _buildRoleCard(context, controller, role);
          },
        ),
      ],
    );
  }

  Widget _buildRoleCard(BuildContext context, RolePermissionController controller, RoleModel role) {
    final isAdmin = role.name == 'Admin';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                role.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              if (!isAdmin)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryBlue),
                      onPressed: () => _showRoleDialog(context, controller, role: role),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorRed),
                      onPressed: () => _confirmDeleteRole(context, controller, role),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            role.description ?? 'No description provided.',
            style: const TextStyle(fontSize: 14, color: AppTheme.gray500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          const Divider(color: AppTheme.gray200),
          const SizedBox(height: 4),
          Text(
            'Linked Groups: ${role.permissionGroups.map((pg) => pg.name).join(", ")}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.primaryBlue),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- PERMISSION GROUPS TAB PANEL ---
  Widget _buildGroupsPanel(BuildContext context, RolePermissionController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Permission Groups Presets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            ElevatedButton.icon(
              onPressed: () => _showGroupDialog(context, controller),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 450,
            mainAxisExtent: 260,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
          ),
          itemCount: controller.permissionGroups.length,
          itemBuilder: (context, idx) {
            final group = controller.permissionGroups[idx];
            return _buildGroupCard(context, controller, group);
          },
        ),
      ],
    );
  }

  Widget _buildGroupCard(BuildContext context, RolePermissionController controller, PermissionGroupModel group) {
    final isAdminGroup = group.name == 'admin';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                group.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              if (!isAdminGroup)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryBlue),
                      onPressed: () => _showGroupDialog(context, controller, group: group),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorRed),
                      onPressed: () => _confirmDeleteGroup(context, controller, group),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            group.description ?? 'No description provided.',
            style: const TextStyle(fontSize: 14, color: AppTheme.gray500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(color: AppTheme.gray200),
          const SizedBox(height: 4),
          const Text(
            'Permissions:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.gray600),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: group.permissions.map((perm) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.gray100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${perm.feature}: ${perm.actions.join(",")}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.gray700, fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CONFIRMATIONS ---
  void _confirmDeleteRole(BuildContext context, RolePermissionController controller, RoleModel role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Role'),
        content: Text('Are you sure you want to delete the role "${role.name}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteRole(role.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context, RolePermissionController controller, PermissionGroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permission Group'),
        content: Text('Are you sure you want to delete the permission group "${group.name}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deletePermissionGroup(group.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }

  // --- ADD/EDIT ROLE DIALOG ---
  void _showRoleDialog(BuildContext context, RolePermissionController controller, {RoleModel? role}) {
    final nameCtrl = TextEditingController(text: role?.name ?? '');
    final descCtrl = TextEditingController(text: role?.description ?? '');
    final selectedGroups = <String>[].obs;

    if (role != null) {
      selectedGroups.addAll(role.permissionGroups.map((pg) => pg.id));
    }

    showDialog(
      context: context,
      builder: (context) => Obx(() {
        return AlertDialog(
          title: Text(role == null ? 'Create Role' : 'Edit Role'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Role Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select Permission Groups:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(border: Border.all(color: AppTheme.gray200), borderRadius: BorderRadius.circular(8)),
                    child: ListView.builder(
                      itemCount: controller.permissionGroups.length,
                      itemBuilder: (context, idx) {
                        final group = controller.permissionGroups[idx];
                        return Obx(() {
                          final isChecked = selectedGroups.contains(group.id);
                          return CheckboxListTile(
                            title: Text(group.name),
                            subtitle: Text(group.description ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                            value: isChecked,
                            activeColor: AppTheme.primaryBlue,
                            onChanged: (val) {
                              if (val == true) {
                                if (!selectedGroups.contains(group.id)) {
                                  selectedGroups.add(group.id);
                                }
                              } else {
                                selectedGroups.remove(group.id);
                              }
                            },
                          );
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            Obx(() {
              final isSaving = controller.isLoading.value;
              return ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final success = await controller.saveRole(
                          id: role?.id,
                          name: nameCtrl.text,
                          description: descCtrl.text,
                          groupIds: selectedGroups.toList(),
                        );
                        if (success && context.mounted) Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save'),
              );
            }),
          ],
        );
      }),
    );
  }

  // --- ADD/EDIT PERMISSION GROUP DIALOG ---
  void _showGroupDialog(BuildContext context, RolePermissionController controller, {PermissionGroupModel? group}) {
    final nameCtrl = TextEditingController(text: group?.name ?? '');
    final descCtrl = TextEditingController(text: group?.description ?? '');

    // Map feature to list of active actions
    final Map<String, RxList<String>> permissionsMap = {};
    for (final feature in controller.availableFeatures) {
      permissionsMap[feature] = <String>[].obs;
    }

    if (group != null) {
      for (final perm in group.permissions) {
        if (permissionsMap.containsKey(perm.feature)) {
          permissionsMap[perm.feature]!.assignAll(perm.actions);
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(group == null ? 'Create Permission Group' : 'Edit Permission Group'),
        content: SizedBox(
          width: 750,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Group Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              const Text(
                'Configure Feature Permissions:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: AppTheme.gray200), borderRadius: BorderRadius.circular(8)),
                  child: ListView.separated(
                    itemCount: controller.availableFeatures.length,
                    separatorBuilder: (context, idx) => const Divider(height: 1, color: AppTheme.gray200),
                    itemBuilder: (context, idx) {
                      final feature = controller.availableFeatures[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 150,
                              child: Text(
                                feature,
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                              ),
                            ),
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                alignment: WrapAlignment.end,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: controller.getFeatureActions(feature).map((action) {
                                  return Obx(() {
                                    final actionsList = permissionsMap[feature]!;
                                    final isChecked = actionsList.contains(action);
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Checkbox(
                                          value: isChecked,
                                          activeColor: AppTheme.primaryBlue,
                                          onChanged: (val) {
                                            if (val == true) {
                                              actionsList.add(action);
                                            } else {
                                              actionsList.remove(action);
                                            }
                                          },
                                        ),
                                        Text(
                                          action,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    );
                                  });
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          Obx(() {
            final isSaving = controller.isLoading.value;
            return ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      // Build permissions list for saving
                      final List<PermissionItem> saveList = [];
                      permissionsMap.forEach((feature, actionsRx) {
                        if (actionsRx.isNotEmpty) {
                          saveList.add(PermissionItem(feature: feature, actions: actionsRx.toList()));
                        }
                      });

                      final success = await controller.savePermissionGroup(
                        id: group?.id,
                        name: nameCtrl.text,
                        description: descCtrl.text,
                        permissions: saveList,
                      );
                      if (success && context.mounted) Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save'),
            );
          }),
        ],
      ),
    );
  }
}
