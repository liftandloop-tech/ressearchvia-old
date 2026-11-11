import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/controllers/staff/staff.controller.dart';
import 'package:spresearch_web/models/staff.model.dart';
import 'package:spresearch_web/models/branch.model.dart';
import 'table_reporting_to_dropdown.widget.dart';
import 'staff_digital_id_dialog.widget.dart';
import 'package:spresearch_web/ui/widgets/offer_letter_dialog.widget.dart';

class StaffRow extends TableRow {
  final StaffModel staff;
  final VoidCallback? onEdit;
  final Function(bool)? onStatusToggle;

  StaffRow({
    required this.staff,
    this.onEdit,
    this.onStatusToggle,
  }) : super(
         children: _buildCells(staff, onEdit, onStatusToggle),
       );

  static List<Widget> _buildCells(
    StaffModel staff,
    VoidCallback? onEdit,
    Function(bool)? onStatusToggle,
  ) {
    final auth = Get.find<AuthController>();
    final currentUser = auth.user.value;
    final isAdmin = currentUser?.isAdmin == true;
    final canUpdate = isAdmin || (currentUser?.has('staff.update') ?? false);
    final canDelete = isAdmin || (currentUser?.has('staff.delete') ?? false);
    final canAssign = isAdmin || (currentUser?.has('staff.assignment') ?? false);
    final canImpersonate = isAdmin;

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: InkWell(
          onTap: () => Get.toNamed('/staff/${staff.id}'),
          child: Text(
            staff.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlue,
              decoration: TextDecoration.underline,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Text(
          staff.mobile,
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Text(
          staff.email,
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Text(
          staff.role,
          style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          overflow: TextOverflow.ellipsis,
        ),
      ),

      // Branch Cell
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: canUpdate ? () => _showBranchPicker(staff) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: staff.branchName != null && staff.branchName!.isNotEmpty
                  ? Colors.teal.shade50
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: staff.branchName != null && staff.branchName!.isNotEmpty
                    ? Colors.teal.shade200
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.apartment_rounded,
                  size: 13,
                  color: staff.branchName != null && staff.branchName!.isNotEmpty
                      ? Colors.teal.shade700
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    staff.branchName?.isNotEmpty == true ? staff.branchName! : '—',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: staff.branchName != null && staff.branchName!.isNotEmpty
                          ? Colors.teal.shade800
                          : Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (canUpdate) ...[
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey.shade600),
                ],
              ],
            ),
          ),
        ),
      ),

      // Assigned HR Cell
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: canUpdate ? () => _showHRPicker(staff) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: staff.assignedHRName != null && staff.assignedHRName!.isNotEmpty
                  ? Colors.purple.shade50
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: staff.assignedHRName != null && staff.assignedHRName!.isNotEmpty
                    ? Colors.purple.shade200
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.badge_outlined,
                  size: 13,
                  color: staff.assignedHRName != null && staff.assignedHRName!.isNotEmpty
                      ? Colors.purple.shade700
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    staff.assignedHRName?.isNotEmpty == true ? staff.assignedHRName! : '—',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: staff.assignedHRName != null && staff.assignedHRName!.isNotEmpty
                          ? Colors.purple.shade800
                          : Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (canUpdate) ...[
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey.shade600),
                ],
              ],
            ),
          ),
        ),
      ),

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: canAssign
            ? TableReportingToDropdown(staff: staff)
            : Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  staff.assignedDirectorName?.isNotEmpty == true
                      ? staff.assignedDirectorName!
                      : (staff.assignedDirector == 'admin' ? 'Admin' : 'None'),
                  style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canDelete)
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: staff.status == 'Active',
                    onChanged: onStatusToggle,
                    activeThumbColor: AppTheme.successGreen,
                    activeTrackColor: AppTheme.successGreen.withValues(
                      alpha: 0.2,
                    ),
                    inactiveThumbColor: AppTheme.errorRed,
                    inactiveTrackColor: AppTheme.errorRed.withValues(
                      alpha: 0.2,
                    ),
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: staff.status == 'Active'
                        ? AppTheme.successGreen
                        : AppTheme.errorRed,
                  ),
                ),
              const SizedBox(width: 4),
              Text(
                staff.status,
                style: TextStyle(
                  fontSize: 12,
                  color: staff.status == 'Active'
                      ? AppTheme.successGreen
                      : AppTheme.errorRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  Get.dialog(
                    StaffDigitalIdDialog(staff: staff),
                  );
                },
                icon: const Icon(
                  Icons.badge_outlined,
                  size: 19,
                  color: Color(0xFF0F172A),
                ),
                tooltip: 'Digital ID Card',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  OfferLetterDialog.show(
                    Get.context!,
                    applicant: staff,
                    onSuccess: () {
                      try {
                        Get.find<StaffController>().fetchStaffList();
                      } catch (_) {}
                    },
                  );
                },
                icon: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 19,
                  color: Color(0xFF4F46E5),
                ),
                tooltip: 'Offer Letter (Preview & Send)',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              if (canImpersonate) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    Get.find<AuthController>().loginAsStaff(staff.id, staff.name);
                  },
                  icon: Icon(
                    Icons.login_rounded,
                    size: 18,
                    color: AppTheme.primaryBlue,
                  ),
                  tooltip: 'Login as ${staff.name}',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => Get.toNamed('/staff/${staff.id}'),
                icon: Icon(
                  Icons.visibility,
                  size: 18,
                  color: AppTheme.primaryBlue,
                ),
                tooltip: 'View Staff Details',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              if (canUpdate) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(
                    Icons.edit,
                    size: 18,
                    color: AppTheme.primaryBlue,
                  ),
                  tooltip: 'Edit Staff Member',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
              if (canDelete) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    Get.find<StaffController>().deleteStaff(staff.id, staff.name);
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppTheme.errorRed,
                  ),
                  tooltip: 'Delete Staff Member',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  static void _showBranchPicker(StaffModel staff) async {
    final controller = Get.find<StaffController>();
    if (controller.branchList.isEmpty) {
      await controller.loadBranchesAndHR();
    }

    final subInfo = await controller.getSubordinatesCount(staff.id);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.apartment_rounded, color: Colors.teal, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Assign Branch: ${staff.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        if (subInfo.count > 0)
                          Text('Supervises ${subInfo.count} staff members', style: TextStyle(fontSize: 11, color: Colors.purple.shade700, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              // Unassigned option
              ListTile(
                dense: true,
                leading: const Icon(Icons.clear, color: Colors.grey, size: 18),
                title: const Text('— Unassigned —', style: TextStyle(fontStyle: FontStyle.italic)),
                onTap: () async {
                  Get.back();
                  await controller.assignBranchToStaff(staff.id, null);
                },
              ),
              const Divider(height: 1),
              // Branch list
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: controller.branchList.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final b = controller.branchList[idx];
                    final isCurrent = staff.branchId == b.id || staff.branchName?.toLowerCase() == b.name.toLowerCase();

                    return ListTile(
                      dense: true,
                      leading: Icon(Icons.location_city, color: isCurrent ? Colors.teal : Colors.grey.shade600, size: 18),
                      title: Row(
                        children: [
                          Text(b.name, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
                          if (b.code != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(b.code!, style: TextStyle(fontSize: 9.5, color: Colors.teal.shade800, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text([b.city, b.state].where((e) => e != null && e.isNotEmpty).join(', '), style: const TextStyle(fontSize: 11)),
                      trailing: isCurrent ? const Icon(Icons.check, color: Colors.teal, size: 18) : null,
                      onTap: () {
                        Get.back();
                        _handleBranchSelection(staff, b, subInfo.count, controller);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _handleBranchSelection(StaffModel staff, BranchModel branch, int subordinatesCount, StaffController controller) {
    if (subordinatesCount > 0) {
      Get.defaultDialog(
        title: 'Cascade Branch Assignment?',
        titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${staff.name} has $subordinatesCount subordinate staff members reporting to them in their hierarchy.\n\nDo you want to cascade this branch assignment ("${branch.name}") to all $subordinatesCount subordinates?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      Get.back();
                      await controller.assignBranchToStaff(staff.id, branch.id, branchName: branch.name, cascade: false);
                    },
                    child: Text('Only Update ${staff.name.split(' ').first}', style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      Get.back();
                      await controller.assignBranchToStaff(staff.id, branch.id, branchName: branch.name, cascade: true);
                    },
                    child: Text('Cascade to All ($subordinatesCount)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      controller.assignBranchToStaff(staff.id, branch.id, branchName: branch.name, cascade: false);
    }
  }

  static void _showHRPicker(StaffModel staff) async {
    final controller = Get.find<StaffController>();
    if (controller.hrStaffList.isEmpty) {
      await controller.loadBranchesAndHR();
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.badge_outlined, color: Colors.purple, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Assign HR: ${staff.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const Text('Select dedicated HR representative', style: TextStyle(fontSize: 11, color: AppTheme.gray500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              // Unassigned option
              ListTile(
                dense: true,
                leading: const Icon(Icons.clear, color: Colors.grey, size: 18),
                title: const Text('— Unassigned —', style: TextStyle(fontStyle: FontStyle.italic)),
                onTap: () async {
                  Get.back();
                  await controller.assignHRToStaff(staff.id, null);
                },
              ),
              const Divider(height: 1),
              // HR list
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: controller.hrStaffList.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final hr = controller.hrStaffList[idx];
                    final isCurrent = staff.assignedHR == hr.id || staff.assignedHRName?.toLowerCase() == hr.name.toLowerCase();

                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: isCurrent ? Colors.purple : Colors.purple.shade50,
                        child: Text(
                          hr.name.isNotEmpty ? hr.name[0].toUpperCase() : 'H',
                          style: TextStyle(fontSize: 11, color: isCurrent ? Colors.white : Colors.purple.shade800, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(hr.name, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
                      subtitle: Text('${hr.role} • ${hr.department}', style: const TextStyle(fontSize: 11)),
                      trailing: isCurrent ? const Icon(Icons.check, color: Colors.purple, size: 18) : null,
                      onTap: () async {
                        Get.back();
                        await controller.assignHRToStaff(staff.id, hr.id, hrName: hr.name);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
