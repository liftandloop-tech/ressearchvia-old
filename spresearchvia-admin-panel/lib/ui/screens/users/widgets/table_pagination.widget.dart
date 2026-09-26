import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/users_table.controller.dart';

class TablePagination extends StatelessWidget {
  final int totalPages;
  final UsersTableController tableController;

  const TablePagination({
    super.key,
    required this.totalPages,
    required this.tableController,
  });

  List<dynamic> _buildPageNumbers(int current, int total) {
    if (total <= 7) {
      return List.generate(total, (i) => i + 1);
    }
    List<dynamic> pages = [];
    pages.add(1);

    if (current > 3) {
      pages.add('...');
    }

    int start = (current - 1).clamp(2, total - 1);
    int end = (current + 1).clamp(2, total - 1);

    for (int i = start; i <= end; i++) {
      if (!pages.contains(i)) pages.add(i);
    }

    if (current < total - 2) {
      pages.add('...');
    }

    if (!pages.contains(total)) {
      pages.add(total);
    }
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Obx(() {
        final current = tableController.currentPage.value;
        final pageSize = tableController.itemsPerPage.value;
        final total = tableController.totalCount.value;
        final pagesCount = totalPages < 1 ? 1 : totalPages;
        final startItem = total == 0 ? 0 : (current - 1) * pageSize + 1;
        final endItem = (current * pageSize).clamp(0, total);

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
            // Left: Showing X to Y of Z users
            Text(
              'Showing $startItem to $endItem of $total users',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),

            // Middle: Rows per page
            Row(
              children: [
                Text(
                  'Rows per page:',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: [10, 15, 25, 50, 100].contains(pageSize)
                          ? pageSize
                          : 15,
                      items: const [10, 15, 25, 50, 100].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(
                            '$value',
                            style: const TextStyle(
                              fontSize: 13,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (newSize) {
                        if (newSize != null) {
                          tableController.setPageSize(newSize);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),

            // Right: Navigation buttons
            Row(
              children: [
                // First Page (<<)
                IconButton(
                  icon: const Icon(Icons.first_page, size: 20),
                  onPressed: current > 1
                      ? () => tableController.goToPage(1)
                      : null,
                  tooltip: 'First page',
                  color: current > 1 ? AppTheme.textPrimary : AppTheme.gray300,
                ),
                // Previous (<)
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: current > 1
                      ? () => tableController.previousPage()
                      : null,
                  tooltip: 'Previous page',
                  color: current > 1 ? AppTheme.textPrimary : AppTheme.gray300,
                ),
                const SizedBox(width: 4),

                // Page Number Buttons
                ..._buildPageNumbers(current, pagesCount).map((item) {
                  if (item is String) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '...',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  final pageNum = item as int;
                  final isSelected = pageNum == current;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => tableController.goToPage(pageNum),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : AppTheme.gray300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$pageNum',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.gray700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(width: 4),
                // Next (>)
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: current < pagesCount
                      ? () => tableController.nextPage(pagesCount)
                      : null,
                  tooltip: 'Next page',
                  color: current < pagesCount
                      ? AppTheme.textPrimary
                      : AppTheme.gray300,
                ),
                // Last Page (>>)
                IconButton(
                  icon: const Icon(Icons.last_page, size: 20),
                  onPressed: current < pagesCount
                      ? () => tableController.goToPage(pagesCount)
                      : null,
                  tooltip: 'Last page',
                  color: current < pagesCount
                      ? AppTheme.textPrimary
                      : AppTheme.gray300,
                ),
              ],
            ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
