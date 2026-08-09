import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';
import 'package:spresearch_web/controllers/notifications/push_notifications.controller.dart';

class PushNotificationsPanel extends StatelessWidget {
  const PushNotificationsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PushNotificationsController());

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
          Text(
            AppStrings.sendPushNotification,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.titleController,
                      onChanged: controller.updateTitle,
                      decoration: InputDecoration(
                        hintText: AppStrings.enterNotificationTitle,
                        hintStyle: TextStyle(color: AppTheme.gray300),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: AppTheme.gray200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: AppTheme.gray200),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppStrings.message,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.messageController,
                      onChanged: controller.updateMessage,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: AppStrings.enterYourMessage,
                        hintStyle: TextStyle(color: AppTheme.gray300),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: AppTheme.gray200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: AppTheme.gray200),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Image (Optional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      if (controller.selectedImageBytes.value != null) {
                        return Stack(
                          children: [
                            Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.gray200),
                                image: DecorationImage(
                                  image: MemoryImage(
                                    controller.selectedImageBytes.value!,
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: InkWell(
                                onTap: controller.clearImage,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return InkWell(
                        onTap: controller.pickImage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.gray200,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                color: AppTheme.primaryBlue,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Click to upload image',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    Text(
                      AppStrings.audience,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.gray200),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Obx(
                        () => DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: controller.selectedAudienceType.value,
                            isExpanded: true,
                            items:
                                [
                                      AppStrings.allUsers,
                                      AppStrings.activeUsers,
                                      'Segment Specific',
                                      'Plan Specific',
                                    ]
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(
                                          e,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: controller.updateAudienceType,
                          ),
                        ),
                      ),
                    ),
                    Obx(() {
                      if (controller.selectedAudienceType.value ==
                              'Segment Specific' ||
                          controller.selectedAudienceType.value ==
                              'Plan Specific') {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              controller.selectedAudienceType.value ==
                                      'Segment Specific'
                                  ? 'Select Segment'
                                  : 'Select Plan',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.gray200),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value:
                                      controller
                                          .selectedAudienceId
                                          .value
                                          .isEmpty
                                      ? null
                                      : controller.selectedAudienceId.value,
                                  isExpanded: true,
                                  hint: Text(
                                    'Choose ${controller.selectedAudienceType.value == 'Segment Specific' ? 'Segment' : 'Plan'}',
                                    style: TextStyle(
                                      color: AppTheme.gray300,
                                      fontSize: 14,
                                    ),
                                  ),
                                  items:
                                      (controller.selectedAudienceType.value ==
                                                  'Segment Specific'
                                              ? controller.segments
                                              : controller.plans)
                                          .map(
                                            (e) => DropdownMenuItem(
                                              value: e['id'],
                                              child: Text(
                                                e['name'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: controller.updateAudienceId,
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.schedule,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => InkWell(
                        onTap: () => controller.toggleSendNow(true),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: controller.sendNow.value
                                      ? AppTheme.primaryBlue
                                      : AppTheme.gray300,
                                  width: 2,
                                ),
                              ),
                              child: controller.sendNow.value
                                  ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.sendNow,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => InkWell(
                        onTap: () => controller.toggleSendNow(false),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: !controller.sendNow.value
                                      ? AppTheme.primaryBlue
                                      : AppTheme.gray300,
                                  width: 2,
                                ),
                              ),
                              child: !controller.sendNow.value
                                  ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.scheduleForLater,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Obx(() {
                      if (!controller.sendNow.value) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: InkWell(
                            onTap: () => controller.pickDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.gray200),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    controller.scheduledDate.value
                                            ?.toString()
                                            .split('.')
                                            .first ??
                                        'Select Date & Time',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          controller.scheduledDate.value == null
                                          ? AppTheme.gray300
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    const SizedBox(height: 20),
                    Text(
                      AppStrings.preview,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.gray50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.gray200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.analytics,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Obx(
                                  () => Text(
                                    controller.notificationTitle.value.isEmpty
                                        ? AppStrings.notificationTitle
                                        : controller.notificationTitle.value,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Obx(
                                  () => Text(
                                    controller.notificationMessage.value.isEmpty
                                        ? AppStrings.messagePreview
                                        : controller.notificationMessage.value,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Obx(() {
                                  if (controller.selectedImageBytes.value !=
                                      null) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.memory(
                                          controller.selectedImageBytes.value!,
                                          height: 100,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }),
                                const SizedBox(height: 8),
                                Text(
                                  AppStrings.justNow,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: BorderSide(color: AppTheme.gray200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  AppStrings.saveDraft,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Obx(
                () => ElevatedButton.icon(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.sendNotification,
                  icon: controller.isLoading.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send, size: 18),
                  label: Text(
                    controller.isLoading.value
                        ? 'Sending...'
                        : AppStrings.sendNotification,
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          Text(
            'Scheduled Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.scheduledNotifications.isEmpty) {
              return Text(
                'No scheduled notifications found.',
                style: TextStyle(color: AppTheme.textSecondary),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.scheduledNotifications.length,
              separatorBuilder: (c, i) => const Divider(),
              itemBuilder: (context, index) {
                final item = controller.scheduledNotifications[index];
                final status = item['status'] ?? 'pending';
                final date =
                    DateTime.tryParse(
                      item['scheduleTime'].toString(),
                    )?.toLocal().toString().split('.')[0] ??
                    item['scheduleTime'];

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    item['title'] ?? 'No Title',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '${item['message']}\nScheduled: $date',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: status == 'sent'
                              ? Colors.green.withOpacity(0.1)
                              : status == 'failed'
                              ? Colors.red.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: status == 'sent'
                                ? Colors.green
                                : status == 'failed'
                                ? Colors.red
                                : Colors.orange,
                          ),
                        ),
                      ),
                      if (status == 'pending')
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              controller.deleteScheduled(item['_id']),
                        ),
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
