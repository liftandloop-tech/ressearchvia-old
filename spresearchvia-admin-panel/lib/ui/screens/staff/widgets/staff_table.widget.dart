import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/models/staff.model.dart';
import 'staff_row.widget.dart';
import 'staff_table_header_cell.widget.dart';
import 'staff_column_filter.widget.dart';

class StaffTable extends StatelessWidget {
  final List<StaffModel> staffList;
  final Function(StaffModel) onEdit;
  final Function(StaffModel, bool) onStatusToggle;

  const StaffTable({
    super.key,
    required this.staffList,
    required this.onEdit,
    required this.onStatusToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: AppTheme.gray200),
        top: BorderSide(color: AppTheme.gray200),
      ),
      columnWidths: const {
        0: FlexColumnWidth(1.3), // Name
        1: FlexColumnWidth(1.1), // Mobile No.
        2: FlexColumnWidth(1.3), // Email
        3: FlexColumnWidth(1.0), // Role
        4: FlexColumnWidth(1.1), // Branch
        5: FlexColumnWidth(1.2), // Assigned HR
        6: FlexColumnWidth(1.4), // Reporting To dropdown
        7: FlexColumnWidth(0.9), // Status switch + text
        8: FlexColumnWidth(1.6), // Actions (Badge, Login As, View, Edit, Delete)
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: AppTheme.gray50),
          children: [
            const StaffTableHeaderCell(
              text: 'Name',
              filterIcon: StaffColumnFilter(columnKey: 'name', columnName: 'Name'),
            ),
            const StaffTableHeaderCell(
              text: 'Mobile No.',
              filterIcon: StaffColumnFilter(columnKey: 'mobile', columnName: 'Mobile No.'),
            ),
            const StaffTableHeaderCell(
              text: 'Email',
              filterIcon: StaffColumnFilter(columnKey: 'email', columnName: 'Email'),
            ),
            const StaffTableHeaderCell(
              text: 'Role',
              filterIcon: StaffColumnFilter(columnKey: 'role', columnName: 'Role'),
            ),
            const StaffTableHeaderCell(
              text: 'Branch',
            ),
            const StaffTableHeaderCell(
              text: 'Assigned HR',
            ),
            const StaffTableHeaderCell(
              text: 'Reporting To',
            ),
            const StaffTableHeaderCell(
              text: 'Status',
              filterIcon: StaffColumnFilter(columnKey: 'status', columnName: 'Status'),
            ),
            const StaffTableHeaderCell(text: 'Actions'),
          ],
        ),
        ...staffList.map(
          (staff) => StaffRow(
            staff: staff,
            onEdit: () => onEdit(staff),
            onStatusToggle: (value) => onStatusToggle(staff, value),
          ),
        ),
      ],
    );
  }
}
