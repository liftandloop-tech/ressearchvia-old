import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/users_navigation.controller.dart';
import 'package:spresearch_web/controllers/users/user_details.controller.dart';
import 'package:spresearch_web/controllers/users/user_management.controller.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/config/app.config.dart';
import 'user_header_button.widget.dart';

class UserHeader extends StatelessWidget {
  const UserHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserDetailsController>();
    final authController = Get.find<AuthController>();

    return Obx(() {
      final userDetails = controller.userDetails.value;
      if (userDetails == null) return SizedBox.shrink();

      return Container(
        padding: EdgeInsets.all(AppTheme.spacing20),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusDefault),
          border: Border.all(color: AppTheme.gray200),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                image:
                    (userDetails.profileImage != null &&
                        userDetails.profileImage!.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(
                          AppConfig.buildImageUrl(userDetails.profileImage),
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child:
                  (userDetails.profileImage != null &&
                      userDetails.profileImage!.isNotEmpty)
                  ? null
                  : Center(
                      child: Text(
                        userDetails.displayName.isNotEmpty
                            ? userDetails.displayName[0].toUpperCase()
                            : 'U',
                        style: AppTheme.h3Style.copyWith(
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
            ),
            SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userDetails.displayName, style: AppTheme.h4Style),
                  Text(
                    'User ID: ${userDetails.id}',
                    style: AppTheme.bodySmallStyle.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (authController.user.value?.has('users.update') ?? false) ...[
              UserHeaderButton(
                title: 'Edit Profile',
                color: AppTheme.primaryBlue,
                icon: Icons.edit,
                onPressed: () => Get.find<UsersNavigationController>()
                    .showEditProfile(userDetails.id),
              ),
              SizedBox(width: AppTheme.spacing12),
              UserHeaderButton(
                title: 'Manage Subscription',
                color: AppTheme.successGreen,
                icon: Icons.credit_card,
                onPressed: () => Get.find<UsersNavigationController>()
                    .showManageSubscription(userDetails.id),
              ),
              SizedBox(width: AppTheme.spacing12),
            ],
            if (authController.user.value?.has('users.generate_temp_pin') ?? false) ...[
              UserHeaderButton(
                title: 'Generate Temp PIN',
                color: Colors.amber.shade800,
                icon: Icons.security,
                onPressed: () => controller.generateTempPin(),
              ),
              SizedBox(width: AppTheme.spacing12),
            ],
            if (authController.user.value?.has('users.suspend_activate') ?? false) ...[
              if (userDetails.status.toUpperCase() == 'SUSPENDED')
                UserHeaderButton(
                  title: 'Activate Account',
                  color: AppTheme.successGreen,
                  icon: Icons.check_circle,
                  onPressed: () {
                    Get.dialog(
                      AlertDialog(
                        title: Text('Activate Account'),
                        content: Text(
                          'Are you sure you want to activate this account? The user will be able to login to the mobile app again.',
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
                              controller.activateUser();
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
                )
              else
                UserHeaderButton(
                  title: 'Suspend Account',
                  color: AppTheme.errorRed,
                  icon: Icons.block,
                  onPressed: () {
                    final reasonController = TextEditingController();
                    final formKey = GlobalKey<FormState>();

                    Get.dialog(
                      AlertDialog(
                        title: Text('Suspend Account'),
                        content: Form(
                          key: formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Are you sure you want to suspend this account? The user will be able to surf the app but will have restricted access (no calls, no plans).',
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
                                controller.suspendUser(
                                  reasonController.text.trim(),
                                );
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
          ],
        ),
      );
    });
  }
}
