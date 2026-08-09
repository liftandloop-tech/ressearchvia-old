import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/notifications/bulk_messaging.controller.dart';
import '../../../widgets/button.widget.dart';
import 'notification_dropdown.widget.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class BulkMessagingPanel extends StatelessWidget {
  const BulkMessagingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BulkMessagingController());
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bulk Email',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      NotificationDropdown(
                        value: controller.selectedAudience.value,
                        items: const [
                          'All Users',
                          'Active Users',
                          'Expired Users',
                          'Premium Users',
                          'Import CSV/Excel',
                          'Manual Entry',
                        ],
                        onChanged: controller.updateAudience,
                      ),
                    ],
                  ),
                ),
                if (controller.selectedAudience.value ==
                    'Import CSV/Excel') ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select File',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Button(
                              title: 'Pick File',
                              buttonType: ButtonType.blue,
                              onTap: controller.pickFile,
                              icon: Icons.upload_file,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                controller.selectedFileName.value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (controller.selectedAudience.value == 'Manual Entry') ...[
              const SizedBox(height: 16),
              Text(
                'Manual Emails (comma separated)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.manualEmailsController,
                maxLines: 2,
                style: const TextStyle(fontFamily: 'Poppins'),
                decoration: InputDecoration(
                  hintText: 'user@example.com, user2@example.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.border),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            Text(
              'Subject',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.subjectController,
              style: const TextStyle(fontFamily: 'Poppins'),
              decoration: InputDecoration(
                hintText: 'Enter email subject',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.border),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              'Message (Content Body)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.messageController,
              maxLines: 5,
              style: const TextStyle(fontFamily: 'Poppins'),
              decoration: InputDecoration(
                hintText: 'Enter your message or HTML content...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.border),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Button(
                  title: controller.isPreviewMode.value ? 'Edit' : 'Preview',
                  buttonType: ButtonType.white,
                  icon: controller.isPreviewMode.value
                      ? Icons.edit
                      : Icons.visibility,
                  onTap: controller.togglePreview,
                ),
                const SizedBox(width: 16),
                Button(
                  title: 'Send Email',
                  buttonType: ButtonType.green,
                  icon: Icons.send,
                  onTap: controller.sendMessage,
                  showLoading: controller.isLoading.value,
                ),
              ],
            ),

            if (controller.isPreviewMode.value) ...[
              const SizedBox(height: 20),
              const Divider(),
              Text('Preview:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: HtmlWidget(controller.previewHtml.value),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
