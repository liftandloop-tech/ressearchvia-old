import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/users_navigation.controller.dart';
import 'package:spresearch_web/controllers/users/user_details.controller.dart';
import 'widgets/user_header.widget.dart';
import 'widgets/kyc_documents.widget.dart';
import '../widgets/payment_history.widget.dart';
import 'widgets/activity_log.widget.dart';
import 'widgets/personal_info.widget.dart';
import 'widgets/contact_info.widget.dart';

class UserDetailsScreen extends StatelessWidget {
  final String? userId;
  const UserDetailsScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserDetailsController());

    // Initial fetch - handled by controller to avoid duplicates
    if (userId != null && userId!.isNotEmpty) {
      controller.fetchUserDetails(userId!);
    }

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'User Details',
                  style: AppTheme.h2Style.copyWith(color: AppTheme.primaryBlue),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacing24),
            Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacing32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (controller.error.value.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacing32),
                    child: Text(
                      controller.error.value,
                      style: AppTheme.bodyTextStyle.copyWith(
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                );
              }

              if (controller.userDetails.value == null) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacing32),
                    child: Text('No user data available'),
                  ),
                );
              }

              return Column(
                children: [
                  const UserHeader(),
                  SizedBox(height: AppTheme.spacing24),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: PersonalInfo()),
                        SizedBox(width: AppTheme.spacing20),
                        Expanded(child: ContactInfo()),
                      ],
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing24),
                  KYCDocuments(controller: controller),
                  SizedBox(height: AppTheme.spacing20),
                  PaymentHistory(userId: userId, showEditColumn: false),
                  const SizedBox(height: AppTheme.spacing20),
                  ActivityLog(userId: userId),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
