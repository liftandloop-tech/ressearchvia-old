import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/user.controller.dart';

class UserTableHeaderCell extends StatelessWidget {
  final String title;
  final String? sortKey;
  final Widget? filterWidget;
  final bool isCenter;

  const UserTableHeaderCell({
    super.key,
    required this.title,
    this.sortKey,
    this.filterWidget,
    this.isCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserController>();

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          isCenter ? MainAxisAlignment.center : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        if (sortKey != null) ...[
          const SizedBox(width: 2),
          Obx(() {
            final isCurrent = controller.sortColumn.value == sortKey;
            final isAsc = controller.sortAscending.value;

            IconData iconData;
            Color iconColor;
            if (isCurrent) {
              iconData = isAsc ? Icons.arrow_upward : Icons.arrow_downward;
              iconColor = AppTheme.primaryBlue;
            } else {
              iconData = Icons.swap_vert;
              iconColor = AppTheme.gray400;
            }

            return Tooltip(
              message: isCurrent
                  ? (isAsc
                      ? 'Sorted ascending (click for descending)'
                      : 'Sorted descending (click to reset)')
                  : 'Sort by $title',
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () => controller.toggleSort(sortKey!),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 1,
                    vertical: 2,
                  ),
                  child: Icon(
                    iconData,
                    size: 13,
                    color: iconColor,
                  ),
                ),
              ),
            );
          }),
        ],
        if (filterWidget != null) ...[
          const SizedBox(width: 1),
          filterWidget!,
        ],
      ],
    );

    if (isCenter) {
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: content,
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: content,
      ),
    );
  }
}
