import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/models/staff.model.dart';
import 'staff_row.widget.dart';
import 'staff_table_header_cell.widget.dart';

class StaffTable extends StatelessWidget {
  final List<StaffModel> staffList;
  final Function(StaffModel) onEdit;
  final Function(StaffModel) onDelete;
  final Function(StaffModel, bool) onStatusToggle;

  const StaffTable({
    super.key,
    required this.staffList,
    required this.onEdit,
    required this.onDelete,
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
        0: FlexColumnWidth(1.5),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1.2),
        4: FlexColumnWidth(1.5), // Increased width for switch + text
        5: FlexColumnWidth(0.6),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: AppTheme.gray50),
          children: [
            StaffTableHeaderCell(text: 'Name'),
            StaffTableHeaderCell(text: 'Mobile No.'),
            StaffTableHeaderCell(text: 'Email'),
            StaffTableHeaderCell(text: 'Role'),
            StaffTableHeaderCell(text: 'Status'),
            StaffTableHeaderCell(text: 'Actions'),
          ],
        ),
        ...staffList.map(
          (staff) => StaffRow(
            staff: staff,
            onEdit: () => onEdit(staff),
            onDelete: () => onDelete(staff),
            onStatusToggle: (value) => onStatusToggle(staff, value),
          ),
        ),
      ],
    );
  }
}
