import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/models/staff.model.dart';
import 'staff_table.widget.dart';
import 'staff_pagination.widget.dart';

class StaffSection extends StatelessWidget {
  final String title;
  final int count;
  final bool isExpanded;
  final VoidCallback onToggle;
  final String subtitle;
  final List<StaffModel> paginatedStaff;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final Function(int) onPageChange;
  final Function(StaffModel) onEdit;
  final Function(StaffModel) onDelete;
  final Function(StaffModel, bool) onStatusToggle;

  const StaffSection({
    super.key,
    required this.title,
    required this.count,
    required this.isExpanded,
    required this.onToggle,
    required this.subtitle,
    required this.paginatedStaff,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPageChange,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    color: AppTheme.textPrimary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$title ($count)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            if (paginatedStaff.isEmpty)
              _buildEmptyState()
            else ...[
              StaffTable(
                staffList: paginatedStaff,
                onEdit: onEdit,
                onDelete: onDelete,
                onStatusToggle: onStatusToggle,
              ),
              StaffPagination(
                title: title,
                currentPage: currentPage,
                totalPages: totalPages,
                totalItems: totalItems,
                itemsPerPage: itemsPerPage,
                currentItemsCount: paginatedStaff.length,
                onPageChange: onPageChange,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 64, color: AppTheme.gray400),
          const SizedBox(height: 16),
          Text(
            'No ${title.toLowerCase()} found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding new staff members to this section',
            style: TextStyle(fontSize: 14, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }
}
