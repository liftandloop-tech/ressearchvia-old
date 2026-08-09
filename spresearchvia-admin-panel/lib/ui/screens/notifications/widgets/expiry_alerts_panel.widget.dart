import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';
import '../../../../controllers/notifications/expiry_alerts.controller.dart';
import 'alert_item.widget.dart';

class ExpiryAlertsPanel extends StatelessWidget {
  const ExpiryAlertsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExpiryAlertsController());

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.expiryAlertsTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.expiryAlertsDesc,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    AppStrings.automatedAlerts,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Obx(
                        () => Switch(
                          value: controller.autoAlerts.value,
                          onChanged: (v) => controller.toggleAutoAlerts(v),
                          activeTrackColor: AppTheme.successGreen,
                        ),
                      ),
                      Obx(
                        () => Text(
                          controller.autoAlerts.value
                              ? AppStrings.enabled
                              : AppStrings.disabled,
                          style: TextStyle(
                            fontSize: 12,
                            color: controller.autoAlerts.value
                                ? AppTheme.successGreen
                                : AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.automatedAlertsDesc,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Section: Alert Points Management
              Expanded(
                flex: 2,
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alert Schedule',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Specify when to send notifications before a plan expires.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Add Alert Input
                      Row(
                        children: [
                          SizedBox(
                            width: 100,
                            height: 42,
                            child: TextField(
                              controller: controller.newAlertDayController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Days',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppTheme.gray300,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryBlue,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: controller.addAlert,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Point'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Dynamic Alerts List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.alerts.length,
                        itemBuilder: (context, index) {
                          final alert = controller.alerts[index];
                          final isSelected =
                              controller.selectedAlertIndex.value == index;

                          return GestureDetector(
                            onTap: () => controller.selectAlert(index),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryBlue.withOpacity(0.05)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryBlue
                                      : AppTheme.gray200,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Transform.scale(
                                          scale: 0.8,
                                          child: Switch(
                                            value: alert.enabled,
                                            onChanged: (v) => controller
                                                .toggleAlert(index, v),
                                            activeColor: AppTheme.primaryBlue,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${alert.days} days before',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? AppTheme.primaryBlue
                                                : AppTheme.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: AppTheme.textSecondary,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        controller.removeAlert(index),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 40),

              // Right Section: Template Editor & Preview
              Expanded(
                flex: 3,
                child: Obx(() {
                  if (controller.alerts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 48,
                            color: AppTheme.gray300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Add an alert point to configure its template',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  final selectedAlert =
                      controller.alerts[controller.selectedAlertIndex.value];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edit Template (${selectedAlert.days} Days)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: controller.updateSettings,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text('Save Changes'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Title Editor
                      Text(
                        'Notification Title',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller.titleController,
                        decoration: InputDecoration(
                          hintText: 'Enter title...',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.gray300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Message Editor
                      Text(
                        'Message Body',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller.messageController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Enter message...',
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.gray300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Placeholders: {{customerName}}, {{planName}}, {{days}}',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Preview Section
                      Text(
                        'Mobile App Preview',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildNotificationPreview(controller),
                    ],
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPreview(ExpiryAlertsController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue,
                  AppTheme.primaryBlue.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.access_time_filled,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ValueListenableBuilder(
                      valueListenable: controller.titleController,
                      builder: (context, value, child) {
                        return Text(
                          value.text.isEmpty
                              ? 'Subscription Expiring'
                              : value.text,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        );
                      },
                    ),
                    Text(
                      'Just now',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ValueListenableBuilder(
                  valueListenable: controller.messageController,
                  builder: (context, value, child) {
                    // Simple regex for preview replacement
                    String previewText = value.text.isEmpty
                        ? 'Your subscription will expire soon.'
                        : value.text;

                    previewText = previewText
                        .replaceAll('{{customerName}}', 'John Doe')
                        .replaceAll('{{planName}}', 'Equity Prime')
                        .replaceAll(
                          '{{days}}',
                          '${controller.alerts[controller.selectedAlertIndex.value].days}',
                        );

                    return Text(
                      previewText,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'RENEW NOW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
