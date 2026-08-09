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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: tableController.currentPage.value > 1
                  ? () => tableController.previousPage()
                  : null,
              child: Text(
                'Previous',
                style: TextStyle(
                  color: tableController.currentPage.value > 1
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const SizedBox(width: 8),
            ...List.generate(totalPages.clamp(0, 5), (index) {
              final page = index + 1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => tableController.goToPage(page),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tableController.currentPage.value == page
                          ? AppTheme.primaryBlue
                          : AppTheme.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.gray300),
                    ),
                    child: Center(
                      child: Text(
                        '$page',
                        style: TextStyle(
                          fontSize: 13,
                          color: tableController.currentPage.value == page
                              ? AppTheme.white
                              : AppTheme.gray700,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
            TextButton(
              onPressed: tableController.currentPage.value < totalPages
                  ? () => tableController.nextPage(totalPages)
                  : null,
              child: Text(
                'Next',
                style: TextStyle(
                  color: tableController.currentPage.value < totalPages
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
