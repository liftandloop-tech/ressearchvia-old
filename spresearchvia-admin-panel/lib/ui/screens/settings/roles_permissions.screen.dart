import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/theme.config.dart';
import '../../../controllers/settings/role_permission.controller.dart';
import '../../../models/department.model.dart';
import '../../../models/permission_group.model.dart';
import '../../../models/role.model.dart';

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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Departmental Hierarchy & Access Control',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Manage organizational departments, scoped permission presets, and functional roles',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Navigation Tabs
                    _buildTabs(controller),
                    const SizedBox(height: 24),

                    // Tab View Panels: 0 = Departments, 1 = Permission Groups, 2 = Roles
                    if (controller.activeTab.value == 0)
                      _buildDepartmentsPanel(context, controller)
                    else if (controller.activeTab.value == 1)
                      _buildGroupsPanel(context, controller)
                    else
                      _buildRolesPanel(context, controller),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabItem(controller, index: 0, label: '1. Departments (Top Hierarchy)'),
            _buildTabItem(controller, index: 1, label: '2. Permission Groups'),
            _buildTabItem(controller, index: 2, label: '3. Roles'),
          ],
        ),
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
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppTheme.primaryBlue : AppTheme.gray500,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 1. DEPARTMENTS TAB PANEL (TOP HIERARCHY)
  // =========================================================================
  Widget _buildDepartmentsPanel(BuildContext context, RolePermissionController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Organizational Departments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Define top-level organizational divisions and assign accessible pages to restrict scoped permissions.',
                    style: TextStyle(fontSize: 13, color: AppTheme.gray500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _showDepartmentDialog(context, controller),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Department'),
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
            maxCrossAxisExtent: 460,
            mainAxisExtent: 260,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
          ),
          itemCount: controller.departments.length,
          itemBuilder: (context, idx) {
            final dept = controller.departments[idx];
            return _buildDepartmentCard(context, controller, dept);
          },
        ),
      ],
    );
  }

  Widget _buildDepartmentCard(BuildContext context, RolePermissionController controller, DepartmentModel dept) {
    final isSystemAdmin = dept.code == 'ADMIN' || dept.isGlobal;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dept.isGlobal ? AppTheme.primaryBlue.withValues(alpha: 0.3) : AppTheme.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        dept.name,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (dept.code != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.gray100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          dept.code!,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.gray600),
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryBlue),
                    tooltip: 'Edit Department',
                    onPressed: () => _showDepartmentDialog(context, controller, department: dept),
                  ),
                  if (!isSystemAdmin)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorRed),
                      tooltip: 'Delete Department',
                      onPressed: () => _confirmDeleteDepartment(context, controller, dept),
                    ),
                ],
              ),
            ],
          ),
          if (dept.isGlobal)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 14, color: AppTheme.primaryBlue),
                  const SizedBox(width: 4),
                  Text(
                    'Global Access (All System Pages)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            dept.description ?? 'No description provided.',
            style: const TextStyle(fontSize: 13, color: AppTheme.gray500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(color: AppTheme.gray200, height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Assigned Pages (${dept.assignedPages.length}):',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.gray700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: dept.assignedPages.map((page) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      page,
                      style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
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

  // =========================================================================
  // 2. PERMISSION GROUPS TAB PANEL (SCOPED TO DEPARTMENT)
  // =========================================================================
  Widget _buildGroupsPanel(BuildContext context, RolePermissionController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permission Groups Presets',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Permission groups are scoped to a Department and strictly restricted to the pages assigned to that department.',
                    style: TextStyle(fontSize: 13, color: AppTheme.gray500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
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
            maxCrossAxisExtent: 460,
            mainAxisExtent: 280,
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
    final deptName = group.departmentName ??
        controller.departments.firstWhereOrNull((d) => d.id == group.departmentId)?.name ??
        'Unassigned';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              Expanded(
                child: Text(
                  group.name,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isAdminGroup)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryBlue),
                      tooltip: 'Edit Group',
                      onPressed: () => _showGroupDialog(context, controller, group: group),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorRed),
                      tooltip: 'Delete Group',
                      onPressed: () => _confirmDeleteGroup(context, controller, group),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.apartment_rounded, size: 14, color: AppTheme.primaryBlue),
              const SizedBox(width: 4),
              Text(
                'Department: $deptName',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            group.description ?? 'No description provided.',
            style: const TextStyle(fontSize: 13, color: AppTheme.gray500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(color: AppTheme.gray200, height: 16),
          const Text(
            'Permissions:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.gray600),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxChipWidth = constraints.maxWidth > 0 ? constraints.maxWidth : 380.0;
                return SingleChildScrollView(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: group.permissions.map((perm) {
                      final actionDescriptions = perm.actions
                          .map((act) => '• ${controller.formatActionLabel(act)}: ${controller.formatActionDescription(act)}')
                          .join('\n');
                      return Tooltip(
                        message: actionDescriptions.isNotEmpty ? actionDescriptions : '${perm.feature} permissions',
                        triggerMode: TooltipTriggerMode.tap,
                        waitDuration: Duration.zero,
                        showDuration: const Duration(seconds: 5),
                        preferBelow: false,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        textStyle: const TextStyle(color: Colors.white, fontSize: 11, height: 1.35),
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Container(
                          constraints: BoxConstraints(maxWidth: maxChipWidth),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.gray100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  '${perm.feature}: ${perm.actions.join(",")}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.gray700, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.info_outline_rounded, size: 12, color: AppTheme.gray400),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. ROLES TAB PANEL
  // =========================================================================
  Widget _buildRolesPanel(BuildContext context, RolePermissionController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Roles Configuration',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Bundle permission groups into functional roles assigned directly to staff members.',
                    style: TextStyle(fontSize: 13, color: AppTheme.gray500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
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
            maxCrossAxisExtent: 420,
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
    final deptName = role.departmentName ??
        controller.departments.firstWhereOrNull((d) => d.id == role.departmentId)?.name;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        role.name,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (role.code != null && role.code!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          role.code!,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isAdmin)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryBlue),
                      tooltip: 'Edit Role',
                      onPressed: () => _showRoleDialog(context, controller, role: role),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorRed),
                      tooltip: 'Delete Role',
                      onPressed: () => _confirmDeleteRole(context, controller, role),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (deptName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Dept: $deptName',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Hierarchy Lvl ${role.level}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.purple.shade700),
                ),
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

  // =========================================================================
  // DIALOGS & CONFIRMATIONS
  // =========================================================================

  // --- ADD / EDIT DEPARTMENT DIALOG ---
  void _showDepartmentDialog(BuildContext context, RolePermissionController controller, {DepartmentModel? department}) {
    final nameCtrl = TextEditingController(text: department?.name ?? '');
    final codeCtrl = TextEditingController(text: department?.code ?? '');
    final descCtrl = TextEditingController(text: department?.description ?? '');
    final selectedPages = <String>[].obs;
    final isGlobal = (department?.isGlobal ?? false).obs;

    if (department != null) {
      selectedPages.addAll(department.assignedPages);
    } else {
      // Default to empty to let admin select pages
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(department == null ? 'Create Department' : 'Edit Department'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width > 750 ? 700 : MediaQuery.of(context).size.width * 0.92,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Department Name (e.g. Sales & Business Development)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: codeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Code / Slug (e.g. SALES)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: Obx(() => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Global Access (All Pages)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Grants visibility across all pages', style: TextStyle(fontSize: 11)),
                        value: isGlobal.value,
                        activeColor: AppTheme.primaryBlue,
                        onChanged: (val) {
                          isGlobal.value = val == true;
                          if (isGlobal.value) {
                            selectedPages.assignAll(controller.availableDepartmentPages.map((p) => p['key'].toString()));
                          }
                        },
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Assign Accessible Pages to Department:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            selectedPages.assignAll(controller.availableDepartmentPages.map((p) => p['key'].toString()));
                          },
                          child: const Text('Select All', style: TextStyle(fontSize: 12)),
                        ),
                        TextButton(
                          onPressed: () {
                            selectedPages.clear();
                          },
                          child: const Text('Clear All', style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 280),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.gray200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: controller.availableDepartmentPages.length,
                    separatorBuilder: (context, idx) => const Divider(height: 1, color: AppTheme.gray200),
                    itemBuilder: (context, idx) {
                      final page = controller.availableDepartmentPages[idx];
                      final pageKey = page['key'].toString();
                      final pageLabel = page['label'] ?? pageKey;
                      final pageDesc = page['description'] ?? '';

                      return Obx(() {
                        final isChecked = selectedPages.contains(pageKey) || isGlobal.value;
                        return CheckboxListTile(
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          title: Text(
                            pageLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isChecked ? AppTheme.primaryBlue : AppTheme.textPrimary,
                            ),
                          ),
                          subtitle: Text(pageDesc, style: const TextStyle(fontSize: 11, color: AppTheme.gray500)),
                          value: isChecked,
                          activeColor: AppTheme.primaryBlue,
                          checkColor: Colors.white,
                          side: BorderSide(
                            color: isChecked ? AppTheme.primaryBlue : AppTheme.gray400,
                            width: 1.5,
                          ),
                          checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          selected: isChecked,
                          selectedTileColor: AppTheme.primaryBlue.withValues(alpha: 0.05),
                          onChanged: isGlobal.value
                              ? null
                              : (val) {
                                  if (val == true) {
                                    if (!selectedPages.contains(pageKey)) selectedPages.add(pageKey);
                                  } else {
                                    selectedPages.remove(pageKey);
                                  }
                                },
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
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
                      if (nameCtrl.text.trim().isEmpty) {
                        Get.snackbar('Alert', 'Please enter a department name', backgroundColor: Colors.orange.withValues(alpha: 0.1));
                        return;
                      }
                      if (!isGlobal.value && selectedPages.isEmpty) {
                        Get.snackbar('Alert', 'Please select at least one accessible page for this department', backgroundColor: Colors.orange.withValues(alpha: 0.1));
                        return;
                      }

                      final success = await controller.saveDepartment(
                        id: department?.id,
                        name: nameCtrl.text.trim(),
                        code: codeCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        assignedPages: selectedPages.toList(),
                        isGlobal: isGlobal.value,
                      );
                      if (success && context.mounted) Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Department'),
            );
          }),
        ],
      ),
    );
  }

  void _confirmDeleteDepartment(BuildContext context, RolePermissionController controller, DepartmentModel dept) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Department'),
        content: Text('Are you sure you want to delete the department "${dept.name}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteDepartment(dept.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }

  // --- ADD / EDIT PERMISSION GROUP DIALOG (SCOPED BY DEPARTMENT) ---
  void _showGroupDialog(BuildContext context, RolePermissionController controller, {PermissionGroupModel? group}) {
    final nameCtrl = TextEditingController(text: group?.name ?? '');
    final descCtrl = TextEditingController(text: group?.description ?? '');
    final selectedDeptId = RxnString(group?.departmentId);

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
          width: MediaQuery.of(context).size.width > 820 ? 780 : MediaQuery.of(context).size.width * 0.92,
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Group Name', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Obx(() {
                      return DropdownButtonFormField<String>(
                        key: ValueKey(selectedDeptId.value),
                        initialValue: selectedDeptId.value,
                        decoration: const InputDecoration(
                          labelText: 'Assigned Department *',
                          border: OutlineInputBorder(),
                          helperText: 'Restricts permissions to this department',
                        ),
                        hint: const Text('Select Department'),
                        items: controller.departments.map((dept) {
                          return DropdownMenuItem<String>(
                            value: dept.id,
                            child: Text(
                              '${dept.name} (${dept.assignedPages.length} pages)',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          selectedDeptId.value = val;
                        },
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Permissions section header with active scope badge
              Obx(() {
                final currentDeptId = selectedDeptId.value;
                final dept = controller.departments.firstWhereOrNull((d) => d.id == currentDeptId);
                final visibleFeatures = controller.getFeaturesForDepartment(currentDeptId);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Configure Feature Permissions:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                    ),
                    if (dept != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_clock_outlined, size: 13, color: AppTheme.primaryBlue),
                            const SizedBox(width: 6),
                            Text(
                              'Restricted to ${dept.name} (${visibleFeatures.length} available pages)',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              }),
              const SizedBox(height: 10),

              // Dynamic permissions container
              Expanded(
                child: Obx(() {
                  final currentDeptId = selectedDeptId.value;
                  if (currentDeptId == null || currentDeptId.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.gray50,
                        border: Border.all(color: AppTheme.gray200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.apartment_rounded, size: 48, color: AppTheme.gray400),
                          const SizedBox(height: 12),
                          const Text(
                            'Please select a Department above',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Permissions will be automatically restricted to only the pages assigned to that department.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppTheme.gray500),
                          ),
                        ],
                      ),
                    );
                  }

                  final visibleFeatures = controller.getFeaturesForDepartment(currentDeptId);
                  if (visibleFeatures.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.gray50,
                        border: Border.all(color: AppTheme.gray200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 40, color: Colors.orange),
                          SizedBox(height: 8),
                          Text(
                            'No accessible pages assigned to this department',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Go to the Departments tab to assign accessible pages to this department first.',
                            style: TextStyle(fontSize: 12, color: AppTheme.gray500),
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(border: Border.all(color: AppTheme.gray200), borderRadius: BorderRadius.circular(8)),
                    child: ListView.separated(
                      itemCount: visibleFeatures.length,
                      separatorBuilder: (context, idx) => const Divider(height: 1, color: AppTheme.gray200),
                      itemBuilder: (context, idx) {
                        final feature = visibleFeatures[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: 140,
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
                                      final description = controller.formatActionDescription(action);
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Checkbox(
                                              value: isChecked,
                                              activeColor: AppTheme.primaryBlue,
                                              checkColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                              side: BorderSide(
                                                color: isChecked ? AppTheme.primaryBlue : AppTheme.gray400,
                                                width: 1.5,
                                              ),
                                              onChanged: (val) {
                                                if (val == true) {
                                                  actionsList.add(action);
                                                } else {
                                                  actionsList.remove(action);
                                                }
                                              },
                                            ),
                                            InkWell(
                                              onTap: () {
                                                if (isChecked) {
                                                  actionsList.remove(action);
                                                } else {
                                                  actionsList.add(action);
                                                }
                                              },
                                              borderRadius: BorderRadius.circular(4),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 2),
                                                child: Text(
                                                  controller.formatActionLabel(action),
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Tooltip(
                                              message: description,
                                              triggerMode: TooltipTriggerMode.tap,
                                              waitDuration: Duration.zero,
                                              showDuration: const Duration(seconds: 5),
                                              preferBelow: false,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0F172A),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: const Color(0xFF334155)),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.25),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              textStyle: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w400,
                                                height: 1.35,
                                              ),
                                              constraints: const BoxConstraints(maxWidth: 280),
                                              child: MouseRegion(
                                                cursor: SystemMouseCursors.help,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(2.0),
                                                  child: Icon(
                                                    Icons.info_outline_rounded,
                                                    size: 15,
                                                    color: isChecked ? AppTheme.primaryBlue : AppTheme.gray400,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
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
                  );
                }),
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
                      if (nameCtrl.text.trim().isEmpty) {
                        Get.snackbar('Alert', 'Please enter a group name', backgroundColor: Colors.orange.withValues(alpha: 0.1));
                        return;
                      }
                      if (selectedDeptId.value == null || selectedDeptId.value!.isEmpty) {
                        Get.snackbar('Alert', 'Please select a department for this permission group', backgroundColor: Colors.orange.withValues(alpha: 0.1));
                        return;
                      }

                      // Build permissions list for saving only from visible features
                      final visibleFeatures = controller.getFeaturesForDepartment(selectedDeptId.value);
                      final List<PermissionItem> saveList = [];
                      for (final feat in visibleFeatures) {
                        final actionsRx = permissionsMap[feat];
                        if (actionsRx != null && actionsRx.isNotEmpty) {
                          saveList.add(PermissionItem(feature: feat, actions: actionsRx.toList()));
                        }
                      }

                      final success = await controller.savePermissionGroup(
                        id: group?.id,
                        name: nameCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        departmentId: selectedDeptId.value,
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
                  : const Text('Save Permission Group'),
            );
          }),
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

  // --- ADD / EDIT ROLE DIALOG ---
  void _showRoleDialog(BuildContext context, RolePermissionController controller, {RoleModel? role}) {
    final nameCtrl = TextEditingController(text: role?.name ?? '');
    final codeCtrl = TextEditingController(text: role?.code ?? '');
    final levelCtrl = TextEditingController(text: (role?.level ?? 1).toString());
    final descCtrl = TextEditingController(text: role?.description ?? '');
    final selectedDeptId = RxnString(role?.departmentId);
    final selectedGroups = <String>[].obs;

    if (role != null) {
      selectedGroups.addAll(role.permissionGroups.map((pg) => pg.id));
    }

    showDialog(
      context: context,
      builder: (context) => Obx(() {
        final currentDeptId = selectedDeptId.value;
        final filteredGroups = controller.permissionGroups.where((pg) {
          if (currentDeptId == null || currentDeptId.isEmpty) return true;
          return pg.departmentId == currentDeptId || pg.name == 'admin';
        }).toList();

        return AlertDialog(
          title: Text(role == null ? 'Create Role' : 'Edit Role'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width > 600 ? 550 : MediaQuery.of(context).size.width * 0.92,
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Role Name', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: codeCtrl,
                        decoration: const InputDecoration(labelText: 'Code (e.g. BDE)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: levelCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Level (1..12)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  key: ValueKey(selectedDeptId.value),
                  initialValue: selectedDeptId.value,
                  decoration: const InputDecoration(
                    labelText: 'Associated Department (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('All / Global'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Departments (Global / Any)'),
                    ),
                    ...controller.departments.map((dept) {
                      return DropdownMenuItem<String>(
                        value: dept.id,
                        child: Text(dept.name),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    selectedDeptId.value = val;
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Select Permission Groups:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(width: 8),
                        Obx(() => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: selectedGroups.isNotEmpty
                                ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                                : AppTheme.gray100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selectedGroups.isNotEmpty
                                  ? AppTheme.primaryBlue.withValues(alpha: 0.25)
                                  : AppTheme.gray300,
                            ),
                          ),
                          child: Text(
                            '${selectedGroups.length} selected',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: selectedGroups.isNotEmpty ? AppTheme.primaryBlue : AppTheme.textSecondary,
                            ),
                          ),
                        )),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: filteredGroups.isEmpty
                              ? null
                              : () {
                                  for (final g in filteredGroups) {
                                    if (!selectedGroups.contains(g.id)) {
                                      selectedGroups.add(g.id);
                                    }
                                  }
                                },
                          child: const Text('Select All', style: TextStyle(fontSize: 12)),
                        ),
                        TextButton(
                          onPressed: () => selectedGroups.clear(),
                          child: const Text('Clear All', style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.gray200),
                      borderRadius: BorderRadius.circular(8),
                      color: AppTheme.white,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: filteredGroups.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.folder_off_outlined, size: 40, color: AppTheme.gray400),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'No permission groups available',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Create permission groups in Tab 2 or choose "All Departments" above.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredGroups.length,
                            separatorBuilder: (context, idx) => const Divider(height: 1, color: AppTheme.gray200),
                            itemBuilder: (context, idx) {
                              final group = filteredGroups[idx];
                              final deptName = group.departmentName ??
                                  controller.departments.firstWhereOrNull((d) => d.id == group.departmentId)?.name ??
                                  'General';

                              return Obx(() {
                                final isChecked = selectedGroups.contains(group.id);
                                return CheckboxListTile(
                                  dense: true,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                  title: Text(
                                    group.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                      color: isChecked ? AppTheme.primaryBlue : AppTheme.textPrimary,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.18)),
                                        ),
                                        child: Text(
                                          deptName,
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                                        ),
                                      ),
                                      if (group.description != null && group.description!.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            group.description!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  value: isChecked,
                                  activeColor: AppTheme.primaryBlue,
                                  checkColor: Colors.white,
                                  side: BorderSide(
                                    color: isChecked ? AppTheme.primaryBlue : AppTheme.gray400,
                                    width: 1.5,
                                  ),
                                  checkboxShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  selected: isChecked,
                                  selectedTileColor: AppTheme.primaryBlue.withValues(alpha: 0.05),
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
                          name: nameCtrl.text.trim(),
                          code: codeCtrl.text.trim(),
                          level: int.tryParse(levelCtrl.text.trim()) ?? 1,
                          description: descCtrl.text.trim(),
                          departmentId: selectedDeptId.value,
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
                    : const Text('Save Role'),
              );
            }),
          ],
        );
      }),
    );
  }

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
}
