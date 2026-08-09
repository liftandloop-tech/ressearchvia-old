import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';
import 'package:spresearch_web/controllers/notifications/notifications.controller.dart';
import 'package:spresearch_web/ui/layouts/dashboard_layout.widget.dart';
import 'widgets/notification_tab.widget.dart';
import 'widgets/push_notifications_panel.widget.dart';
import 'widgets/expiry_alerts_panel.widget.dart';
import 'widgets/bulk_messaging_panel.widget.dart';
import 'widgets/notification_history_panel.widget.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationsController());

    return DashboardLayout(
      child: Container(
        color: AppTheme.gray50,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.communicationNotifications,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.communicationDesc,
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              Obx(
                () => Row(
                  children: [
                    NotificationTab(
                      index: 0,
                      icon: Icons.notifications,
                      label: AppStrings.pushNotifications,
                      isSelected: controller.selectedTab.value == 0,
                      onTap: () => controller.changeTab(0),
                    ),
                    const SizedBox(width: 12),
                    NotificationTab(
                      index: 1,
                      icon: Icons.access_time,
                      label: AppStrings.expiryAlerts,
                      isSelected: controller.selectedTab.value == 1,
                      onTap: () => controller.changeTab(1),
                    ),
                    const SizedBox(width: 12),
                    NotificationTab(
                      index: 2,
                      icon: Icons.email,
                      label: AppStrings.bulkEmailSMS,
                      isSelected: controller.selectedTab.value == 2,
                      onTap: () => controller.changeTab(2),
                    ),
                    const SizedBox(width: 12),
                    NotificationTab(
                      index: 3,
                      icon: Icons.history,
                      label: 'History',
                      isSelected: controller.selectedTab.value == 3,
                      onTap: () => controller.changeTab(3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Obx(() {
                if (controller.selectedTab.value == 0) {
                  return const PushNotificationsPanel();
                } else if (controller.selectedTab.value == 1) {
                  return const ExpiryAlertsPanel();
                } else if (controller.selectedTab.value == 2) {
                  return const BulkMessagingPanel();
                } else {
                  return const NotificationHistoryPanel();
                }
              }),
            ],
          ),
        ),
      ),
    );
  }
}
