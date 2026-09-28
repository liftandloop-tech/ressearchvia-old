import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/models/staff.model.dart';
import 'table_reporting_to_dropdown.widget.dart';
import 'staff_digital_id_dialog.widget.dart';

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
                    activeColor: AppTheme.successGreen,
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
            ],
          ),
        ),
      ),
    ];
  }
}
