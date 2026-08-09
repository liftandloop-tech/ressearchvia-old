import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/notifications/push_notifications.controller.dart';
import '../../../widgets/button.widget.dart';
import 'notification_text_field.widget.dart';
import 'notification_audience_dropdown.widget.dart';

class PushNotifications extends StatelessWidget {
  const PushNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PushNotificationsController());
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Push Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 20),
          NotificationTextField(
            label: 'Title',
            controller: controller.titleController,
          ),
          const SizedBox(height: 16),
          NotificationTextField(
            label: 'Message',
            controller: controller.messageController,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          Text(
            'Target Audience',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => NotificationAudienceDropdown(
              value: controller.selectedAudienceType.value,
              onChanged: controller.updateAudienceType,
            ),
          ),
          const SizedBox(height: 20),
          Button(
            title: 'Send Notification',
            buttonType: ButtonType.green,
            icon: Icons.send,
            onTap: controller.sendNotification,
          ),
        ],
      ),
    );
  }
}
