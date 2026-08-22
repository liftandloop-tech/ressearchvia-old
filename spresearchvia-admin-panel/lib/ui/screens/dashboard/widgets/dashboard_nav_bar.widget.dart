import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/dashboard/main_dashboard.controller.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';

class DashboardNavBar extends StatelessWidget {
  final MainDashboardController controller;

  const DashboardNavBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      final user = authController.user.value;

      final allItems = [
        {'title': 'Dashboard', 'index': 0},
        {
          'title': 'Users',
          'index': 1,
          'children': [
            {'title': 'All Users', 'index': 1},
            {'title': 'User KYC', 'index': 7},
            {'title': 'Payments', 'index': 8},
          ],
        },
        {'title': 'Staff', 'index': 2},
        {'title': 'Subscriptions', 'index': 3},
        {'title': 'Reports', 'index': 4},
        {'title': 'Notifications', 'index': 5},
        {'title': 'Settings', 'index': 6},
        {'title': 'Automated Trading', 'index': 9},
        {'title': 'Leads', 'index': 10},
        // {'title': 'Attendance & Monitoring', 'index': 11},
        {'title': 'Job Applicants', 'index': 12},
      ];

      // RBAC: Roles determine visible items
      final List<Map<String, dynamic>> items;
      if (user?.isAdmin == true) {
        items = allItems;
      } else {
        // All non-admin roles (Director, Researcher, Sales, Support, etc.): filter dynamically based on permission groups
        items = allItems
            .map((item) {
              final title = item['title'] as String;
              if (title == 'Dashboard') return item;

              if (title == 'Users') {
                final children = ((item['children'] as List<Map<String, dynamic>>?) ?? [])
                    .where((child) {
                      final childTitle = child['title'] as String;
                      if (childTitle == 'All Users') {
                        return user?.has('users.view') ?? false;
                      } else if (childTitle == 'User KYC') {
                        return user?.has('kyc.view') ?? false;
                      } else if (childTitle == 'Payments') {
                        return user?.has('payments.view_pending') ?? false;
                      }
                      return false;
                    })
                    .toList();
                if (children.isNotEmpty) {
                  return {...item, 'children': children};
                }
                return null;
              }

              if (title == 'Staff') {
                return (user?.has('staff.view') ?? false) ? item : null;
              }
              if (title == 'Reports') {
                return (user?.has('reports.view') ?? false) ? item : null;
              }
              if (title == 'Notifications') {
                return (user?.has('notifications.view') ?? false) ? item : null;
              }
              if (title == 'Settings') {
                return (user?.has('settings.view') ?? false) ? item : null;
              }
              if (title == 'Leads') {
                return (user?.has('leads.view_all') ?? user?.has('leads.view_assigned') ?? false) ? item : null;
              }
              if (title == 'Job Applicants') {
                return (user?.has('staff.view_applicants') ?? false) ? item : null;
              }

              return null;
            })
            .where((item) => item != null)
            .cast<Map<String, dynamic>>()
            .toList();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items.map((item) => _buildNavItem(item)).toList(),
      );
    });
  }

  Widget _buildNavItem(Map<String, dynamic> item) {
    final title = item['title'] as String;
    final hasChildren = item.containsKey('children');
    final children = hasChildren
        ? item['children'] as List<Map<String, dynamic>>
        : [];

    // Auto-expand if a child is active
    bool isChildActive = false;
    if (hasChildren) {
      isChildActive = children.any(
        (child) => controller.selectedTab.value == child['index'],
      );
      if (isChildActive && controller.expandedItem.value == '') {
        controller.expandedItem.value = title;
      }
    }

    final isActive =
        controller.selectedTab.value == item['index'] || isChildActive;
    final isExpanded = controller.expandedItem.value == title;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
          child: InkWell(
            onTap: () {
              if (hasChildren) {
                controller.expandedItem.value = isExpanded ? '' : title;
              } else {
                controller.changeTab(item['index'] as int);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: (isActive && !hasChildren)
                    ? AppTheme.primaryBlue.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: (isActive && !hasChildren)
                    ? Border(
                        left: BorderSide(color: AppTheme.primaryBlue, width: 4),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? AppTheme.primaryBlue
                          : AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (hasChildren)
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: isActive
                          ? AppTheme.primaryBlue
                          : AppTheme.textSecondary,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (hasChildren && isExpanded)
          ...children.map((child) => _buildChildNavItem(child)).toList(),
      ],
    );
  }

  Widget _buildChildNavItem(Map<String, dynamic> child) {
    final isActive = controller.selectedTab.value == child['index'];
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 16, top: 2, bottom: 2),
      child: InkWell(
        onTap: () => controller.changeTab(child['index'] as int),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primaryBlue.withOpacity(0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border(
                    left: BorderSide(color: AppTheme.primaryBlue, width: 3),
                  )
                : null,
          ),
          child: Row(
            children: [
              Text(
                child['title'] as String,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? AppTheme.primaryBlue
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
