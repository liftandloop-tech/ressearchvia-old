import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'staff_page_button.widget.dart';

class StaffPageNumbers extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChange;

  const StaffPageNumbers({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChange,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [];
    if (totalPages <= 3) {
      for (int i = 1; i <= totalPages; i++) {
        pages.add(
          StaffPageButton(
            page: i,
            isActive: currentPage == i,
            onPageChange: onPageChange,
          ),
        );
        if (i < totalPages) pages.add(const SizedBox(width: 8));
      }
    } else {
      pages.add(
        StaffPageButton(
          page: 1,
          isActive: currentPage == 1,
          onPageChange: onPageChange,
        ),
      );
      if (currentPage > 2) {
        pages.add(const SizedBox(width: 8));
        pages.add(Text('...', style: TextStyle(color: AppTheme.textSecondary)));
      }
      if (currentPage > 1 && currentPage < totalPages) {
        pages.add(const SizedBox(width: 8));
        pages.add(
          StaffPageButton(
            page: currentPage,
            isActive: true,
            onPageChange: onPageChange,
          ),
        );
      }
      if (currentPage < totalPages - 1) {
        pages.add(const SizedBox(width: 8));
        pages.add(Text('...', style: TextStyle(color: AppTheme.textSecondary)));
      }
      pages.add(const SizedBox(width: 8));
      pages.add(
        StaffPageButton(
          page: totalPages,
          isActive: currentPage == totalPages,
          onPageChange: onPageChange,
        ),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: pages);
  }
}
