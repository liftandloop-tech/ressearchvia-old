import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:collection/collection.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';
import 'package:spresearch_web/controllers/subscription/manage_subscription.controller.dart';
import 'package:spresearch_web/controllers/users/users_navigation.controller.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'widgets/current_subscription_details.widget.dart';
import 'widgets/subscription_actions.widget.dart';
import 'widgets/custom_plans.widget.dart';
import 'widgets/payment_history.widget.dart';
import 'widgets/registration_plan_actions.widget.dart';

class ManageSubscriptionScreen extends StatelessWidget {
  final String userId;
  const ManageSubscriptionScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ManageSubscriptionController());

    controller.fetchUserSubscriptions(userId);

    final currentUser = Get.find<AuthController>().user.value;
    final canViewPayments = currentUser?.has('payments.view_pending') ?? false;
    final canUpdateSub = (currentUser?.isAdmin ?? false) || (currentUser?.has('settings.update') ?? false);

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () =>
                      Get.find<UsersNavigationController>().goBack(),
                  icon: Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
                ),
                SizedBox(width: AppTheme.spacing8),
                Text(
                  AppStrings.manageSubscription,
                  style: AppTheme.h2Style.copyWith(color: AppTheme.primaryBlue),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.manageSubscriptionDesc,
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.gray200),
              ),
              child: Obx(() {
                final user = controller.userDetails.value;
                final registrationPlan = controller.userSubscriptions
                    .firstWhereOrNull((s) {
                      final name =
                          s['packageName']?.toString().toLowerCase() ?? '';
                      return s['status'] == 'active' &&
                          name.contains('registration');
                    });

                return Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.gray300,
                        image: DecorationImage(
                          image: AssetImage(
                            'assets/images/avatar.jpg',
                          ), // Fallback or dynamic URL
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? user?.displayName ?? 'Loading...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'User ID: ${user?.id ?? '-'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          if (user?.userObject?.appEmail != null &&
                              user!.userObject!.appEmail.isNotEmpty)
                            Text(
                              user!.userObject!.appEmail,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          if (user?.formattedPhone != null)
                            Text(
                              user!.formattedPhone,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Current Registration',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          registrationPlan != null
                              ? ((registrationPlan['packageName']
                                                ?.toString()
                                                .toLowerCase()
                                                .contains('yearly') ??
                                            false) ||
                                        (registrationPlan['packageName']
                                                ?.toString()
                                                .toLowerCase()
                                                .contains('silver') ??
                                            false) ||
                                        (user?.registrationType
                                                ?.toLowerCase()
                                                .contains('yearly') ??
                                            false)
                                    ? 'Silver'
                                    : 'Gold')
                              : 'No Registration',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    _buildStatusBadge(
                      registrationPlan != null ? 'Active' : 'Inactive',
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 24),
            if (canUpdateSub) ...[
              RegistrationPlanActions(controller: controller),
              const SizedBox(height: 24),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CurrentSubscriptionDetails(controller: controller),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (canViewPayments) ...[
              PaymentHistory(userId: userId),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;

    switch (status.toLowerCase()) {
      case 'active':
        color = const Color(0xFF28A745);
        bgColor = const Color(0xFFD4EDDA);
        break;
      case 'revoked':
        color = const Color(0xFFDC3545);
        bgColor = const Color(0xFFF8D7DA);
        break;
      case 'suspended':
        color = const Color(0xFFFD7E14);
        bgColor = const Color(0xFFFFE5D0);
        break;
      case 'expired':
        color = AppTheme.textSecondary;
        bgColor = AppTheme.gray200;
        break;
      case 'inactive':
      default:
        color = AppTheme.textSecondary;
        bgColor = AppTheme.gray200;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
