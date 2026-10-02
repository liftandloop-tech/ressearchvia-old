import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';
import 'staff_page_numbers.widget.dart';

class StaffPagination extends StatelessWidget {
  final String title;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final int currentItemsCount;
  final Function(int) onPageChange;
  final Function(int)? onItemsPerPageChange;

  const StaffPagination({
    super.key,
    required this.title,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.currentItemsCount,
    required this.onPageChange,
    this.onItemsPerPageChange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                '${AppStrings.showing} ${(currentPage - 1) * itemsPerPage + 1}-${((currentPage - 1) * itemsPerPage + currentItemsCount)} ${AppStrings.of} $totalItems ${title.toLowerCase()}',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              if (onItemsPerPageChange != null) ...[
                const SizedBox(width: 20),
                Text(
                  'Rows per page:',
                  style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.gray300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: itemsPerPage,
                      isDense: true,
                      style: TextStyle(fontSize: 12.5, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                      items: const [10, 25, 50, 100].map((int val) {
                        return DropdownMenuItem<int>(
                          value: val,
                          child: Text('$val'),
                        );
                      }).toList(),
                      onChanged: (int? newVal) {
                        if (newVal != null && newVal != itemsPerPage) {
                          onItemsPerPageChange!(newVal);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: currentPage > 1
                    ? () => onPageChange(currentPage - 1)
                    : null,
                icon: Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: currentPage > 1
                      ? AppTheme.textPrimary
                      : AppTheme.gray300,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              StaffPageNumbers(
                currentPage: currentPage,
                totalPages: totalPages,
                onPageChange: onPageChange,
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: currentPage < totalPages
                    ? () => onPageChange(currentPage + 1)
                    : null,
                icon: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: currentPage < totalPages
                      ? AppTheme.textPrimary
                      : AppTheme.gray300,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
