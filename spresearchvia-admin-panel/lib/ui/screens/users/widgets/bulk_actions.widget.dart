import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/user.controller.dart';
import 'bulk_action_button.widget.dart';

class BulkActions extends StatelessWidget {
  const BulkActions({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserController>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Row(
        children: [
          Obx(
            () => Checkbox(
              value:
                  controller.selectedUsers.length ==
                  controller.filteredUsers.length,
              onChanged: (_) => controller.toggleSelectAll(),
            ),
          ),
          Text(
            'Select All',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          Obx(
            () => Text(
              '${controller.selectedUsers.length} selected',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ),
          const Spacer(),
          BulkActionButton(
            title: 'Send Notification',
            color: AppTheme.successGreen,
            icon: Icons.notifications,
            onTap: controller.sendNotification,
          ),
          const SizedBox(width: 12),
          BulkActionButton(
            title: 'Activate',
            color: AppTheme.successGreen,
            icon: Icons.check_circle,
            onTap: () {
              Get.dialog(
                AlertDialog(
                  title: Text('Activate Selected Accounts'),
                  content: Text(
                    'Are you sure you want to activate ${controller.selectedUsers.length} selected accounts?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                      ),
                      onPressed: () {
                        controller.activateUsers();
                        Get.back();
                      },
                      child: Text(
                        'Activate',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          BulkActionButton(
            title: 'Suspend',
            color: AppTheme.errorRed,
            icon: Icons.block,
            onTap: () {
              final reasonController = TextEditingController();
              final formKey = GlobalKey<FormState>();

              Get.dialog(
                AlertDialog(
                  title: Text('Suspend Selected Accounts'),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Are you sure you want to suspend ${controller.selectedUsers.length} selected accounts? Users will be able to surf the app but will have restricted access.',
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: reasonController,
                          decoration: InputDecoration(
                            labelText: 'Suspension Reason',
                            hintText: 'Enter reason for suspension',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Reason is mandatory';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorRed,
                      ),
                      onPressed: () {
                        if (formKey.currentState?.validate() ?? false) {
                          controller.suspendUsers(reasonController.text.trim());
                          Get.back();
                        }
                      },
                      child: Text(
                        'Suspend',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
