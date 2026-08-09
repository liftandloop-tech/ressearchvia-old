import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/user.controller.dart';
import '../../controllers/auth.controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_styles.dart';
import '../../core/models/user.dart';

import 'view_profile.screen.dart';
import 'widgets/KycStatus.Item.dart';
import 'widgets/profile.image.dart';
import 'widgets/profile.tile.dart';
import '../subscription/subscription_history.screen.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/button.dart';
import '../../controllers/segment_plan.controller.dart';
import '../../services/snackbar.service.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _maskAadhar(String? aadhar) {
    if (aadhar == null || aadhar.isEmpty) return 'Not Available';
    if (aadhar.length < 4) return aadhar;

    // Show last 4 digits, mask the rest
    final last4 = aadhar.substring(aadhar.length - 4);
    return 'XXXX XXXX $last4';
  }

  String _getKycStatusText(KycStatus? status) {
    switch (status) {
      case KycStatus.verified:
        return 'Verified';
      case KycStatus.waitingForReview:
        return 'Under Review';
      case KycStatus.inProgress:
        return 'In Progress';
      case KycStatus.rejected:
        return 'Rejected';
      case KycStatus.notStarted:
      default:
        return 'Not Verified';
    }
  }

  Color _getKycStatusColor(KycStatus? status) {
    switch (status) {
      case KycStatus.verified:
        return const Color(0xff16A34A);
      case KycStatus.waitingForReview:
      case KycStatus.inProgress:
        return const Color(0xffF59E0B);
      case KycStatus.rejected:
        return const Color(0xffEF4444);
      case KycStatus.notStarted:
      default:
        return const Color(0xff6B7280);
    }
  }

  String _getKycStatusLabel(KycStatus? status) {
    switch (status) {
      case KycStatus.verified:
        return 'Completed';
      case KycStatus.waitingForReview:
        return 'Pending';
      case KycStatus.inProgress:
        return 'In Progress';
      case KycStatus.rejected:
        return 'Rejected';
      case KycStatus.notStarted:
      default:
        return 'Not Started';
    }
  }
  static String _getRegistrationLabel(String? type, bool isSkipped) {
    if (isSkipped) return 'Not Registered';
    if (type == null) return 'Silver';
    final t = type.toUpperCase();
    if (t == 'LIFETIME' || t == 'GOLD') return 'Gold';
    if (t == 'ANNUAL' || t == 'YEARLY' || t == 'SILVER') return 'Silver';
    return type;
  }

  static Color _getRegistrationColor(String? type) {
    final t = type?.toUpperCase();
    if (t == 'YEARLY' || t == 'ANNUAL' || t == 'SILVER') return const Color(0xff94a3b8);
    if (t == 'LIFETIME' || t == 'GOLD') return const Color(0xffF59E0B);
    return AppTheme.primaryBlue;
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<UserController>()) {
      Get.put(UserController());
    }
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController());
    }

    final userController = Get.find<UserController>();
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: AppStyles.appBarTitle),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.backgroundWhite,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xff11416B)),
            tooltip: 'Settings',
            onPressed: () => Get.toNamed(AppRoutes.settings),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.iconRed),
            tooltip: 'Logout',
            onPressed: () => authController.logout(),
          ),
        ],
      ),
      body: Obx(() {
        final user = userController.currentUser.value;

        if (user == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_off,
                  size: 80,
                  color: AppTheme.iconGrey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No user data available',
                  style: AppStyles.bodyLarge,
                ),
                const SizedBox(height: 24),
                Button(
                  title: 'Logout',
                  buttonType: ButtonType.blue,
                  onTap: () => authController.logout(),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            children: [
              ProfileImageAvatar(
                imagePath:
                    user.profileImage ??
                    'assets/images/profile_placeholder.jpg',
              ),
              const SizedBox(height: 20),
              Text(
                user.name,
                style: AppStyles.heading3.copyWith(color: AppTheme.primaryBlue),
              ),
              Text(
                user.email ?? '',
                style: AppStyles.bodySmall.copyWith(color: AppTheme.textGrey),
              ),
              const SizedBox(height: 20),
              if (user.contactDetails?.phone != null || user.phone != null)
                ProfileTile(
                  icon: Icons.phone,
                  title: 'Phone Number',
                  value: user.contactDetails?.phone?.toString() ?? user.phone!,
                ),
              if (user.contactDetails?.phone != null || user.phone != null)
                const SizedBox(height: 10),
              ProfileTile(
                icon: Icons.credit_card,
                title: 'PAN Number',
                value: user.panNumber ?? 'Not Available',
              ),
              
              const SizedBox(height: 10),
              KycStatusItem(
                icon: Icons.verified_user,
                title: 'KYC Status',
                value: _getKycStatusText(user.kycStatus),
                statusColor: _getKycStatusColor(user.kycStatus),
                statusLabel: _getKycStatusLabel(user.kycStatus),
              ),
              
              const SizedBox(height: 10),
              // Registration Status Card - Always Show
              GestureDetector(
                onTap: () {
                  if (userController.isRegistrationSkipped.value) {
                    Get.toNamed(AppRoutes.registrationScreen);
                  } else if (user.registrationType != null) {
                    ProfileScreen.showRegistrationDetailsPopup(context, userController);
                  } else {
                    Get.toNamed(AppRoutes.registrationScreen);
                  }
                },
                child: KycStatusItem(
                  icon: Icons.card_membership,
                  title: 'Registration Type',
                  value: _getRegistrationLabel(user.registrationType, userController.isRegistrationSkipped.value),
                  statusColor: userController.isRegistrationSkipped.value 
                      ? Colors.grey
                      : user.registrationStatus == 'REJECTED'
                          ? Colors.red
                          : (user.registrationFeePaid == true || user.adminAccessGranted == true) 
                              ? _getRegistrationColor(user.registrationType) 
                              : Colors.orange,
                  statusLabel: userController.isRegistrationSkipped.value
                      ? 'Action Required'
                      : user.registrationStatus == 'REJECTED'
                          ? 'Rejected'
                          : (user.registrationFeePaid == true || user.adminAccessGranted == true) 
                              ? 'Active' 
                              : (user.registrationStatus == 'PENDING' ? 'Pending Payment' : 'Partial Payment'),
                ),
              ),
              
              // Warning for pending balance
              GetX<SegmentPlanController>(
                init: SegmentPlanController(),
                builder: (segController) {
                  if (segController.hasRegistrationPendingBalance) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No access to plans until registration amount is fully paid.',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 15),
              Button(
                title: 'View Profile',
                buttonType: ButtonType.blue,
                icon: Icons.person,
                onTap: () => Get.to(() => const ViewProfileScreen()),
              ),
              const SizedBox(height: 10),
              Button(
                title: 'Active Plans',
                buttonType: ButtonType.blueBorder,
                icon: Icons.history,
                onTap: () => Get.to(() => const SubscriptionHistoryScreen()),
              ),
              const SizedBox(height: 10),
              Button(
                title: 'Billing History',
                buttonType: ButtonType.blueBorder,
                icon: Icons.receipt_long,
                onTap: () => Get.toNamed(AppRoutes.billingHistory),
              ),
              const SizedBox(height: 10),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        );
      }),
    );
  }

  static void showRegistrationDetailsPopup(BuildContext context, UserController userController) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final data = await userController.fetchRegistrationDetails();
    Get.back(); // Dismiss loading

    if (data == null) {
      SnackbarService.showError('Could not fetch registration details');
      return;
    }

    final String regType = data['registrationType'] ?? 'YEARLY';
    final String validity = data['validityLabel'] ?? '';
    final String? expiryStr = data['expiryDate'];
    final DateTime? expiry = expiryStr != null ? DateTime.parse(expiryStr) : null;
    final Map<String, dynamic>? payment = data['paymentStatus'];
    final Map<String, dynamic>? trial = data['trialInfo'];

    final double totalAmount = (payment?['totalAmount'] ?? 0).toDouble();
    final double targetAmount = (payment?['targetAmount'] ?? totalAmount).toDouble();
    final double discount = (payment?['discount'] ?? 0).toDouble();
    final double walletBalance = (payment?['walletBalance'] ?? 0).toDouble();
    final double amountPaid = (payment?['amountPaid'] ?? 0).toDouble();
    final double approvedByAdmin = (payment?['approvedAmount'] ?? 0).toDouble();
    final double pendingApproval = (payment?['pendingAmount'] ?? 0).toDouble();
    final double remaining = (payment?['remainingAmount'] ?? 0).toDouble();
    final bool isPartial = payment?['isPartial'] ?? false;
    final String? intentId = payment?['paymentIntentId'];
    final String? intentStatus = payment?['status'];
    final bool hasRejected = payment?['hasRejectedInstallment'] ?? false;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Registration Details', style: AppStyles.heading3),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              
              _buildInfoRow('Plan', '${_getRegistrationLabel(regType, false)} ($validity)'),
              if (expiry != null)
                _buildInfoRow('Expiry Date', DateFormat('dd MMM, yyyy').format(expiry)),
              
              if (trial != null) ...[
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 18, color: AppTheme.primaryBlue),
                          const SizedBox(width: 8),
                          Text('Free Trial Active', 
                            style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Plan: ${trial['planName'] ?? "Trial Plan"}', style: AppStyles.bodySmall),
                      Text('Remaining: ${trial['daysRemaining'] ?? 0} Days', style: AppStyles.bodySmall),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 15),
              Text('Payment Status', style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (intentStatus == 'REJECTED') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your previous payment proof was rejected. Please re-upload a valid proof or complete the payment.',
                              style: AppStyles.bodySmall.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow('Plan Amount', '₹$totalAmount'),
                      _buildInfoRow('Status', 'REJECTED', valueColor: Colors.red),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Button(
                  title: 'Re-upload Payment Proof',
                  buttonType: ButtonType.blue,
                  icon: Icons.upload_file,
                  onTap: () {
                    Get.back(); // Close popup
                    Get.toNamed(AppRoutes.bankTransferUpload, arguments: {
                      'plan': {'planName': '${_getRegistrationLabel(regType, false)} Registration'},
                      'amount': targetAmount, 
                      'totalToPay': targetAmount,
                      'paymentId': intentId,
                      'isPartial': isPartial,
                      'isInstallment': isPartial,
                      'planName': '${_getRegistrationLabel(regType, false)} Registration'
                    });
                  },
                ),
              ] else if (isPartial && remaining > 0) ...[
                if (hasRejected) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('One of your previous installments was rejected. Please re-upload.', style: AppStyles.bodySmall.copyWith(color: Colors.red))),
                      ],
                    ),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Plan Amount', '₹$totalAmount'),
                      if (discount > 0)
                        _buildInfoRow('Discount', '-₹$discount', valueColor: Colors.green),
                      if (walletBalance > 0)
                        _buildInfoRow('Advance Wallet', '-₹$walletBalance', valueColor: Colors.blue),
                      const Divider(height: 16),
                      _buildInfoRow('Target Amount', '₹$targetAmount'),
                      _buildInfoRow('Pending Approval', '₹$pendingApproval', valueColor: Colors.orange),
                      _buildInfoRow('Approved by Admin', '₹$approvedByAdmin', valueColor: Colors.green),
                      _buildInfoRow('Total Paid', '₹$amountPaid', isBoldText: true),
                      const Divider(height: 16),
                      _buildInfoRow('Remaining', '₹$remaining', valueColor: AppTheme.error, isBoldText: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Button(
                  title: 'Pay Remaining Balance',
                  buttonType: ButtonType.blue,
                  icon: Icons.payment,
                  onTap: () {
                    Get.back(); // Close popup
                    Get.toNamed(AppRoutes.bankTransferUpload, arguments: {
                      'plan': {'planName': '${_getRegistrationLabel(regType, false)} Registration'},
                      'amount': remaining, // Fixed: Pay the remaining amount
                      'totalToPay': targetAmount, // Pre-fill total target for reference
                      'paymentId': intentId,
                      'isPartial': true,
                      'isInstallment': true,
                      'planName': '${_getRegistrationLabel(regType, false)} Registration'
                    });
                  },
                ),
              ] else if (isPartial && remaining <= 0) ...[
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text('Installments Paid (₹$amountPaid)', style: AppStyles.bodyMedium.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (walletBalance > 0)
                   Padding(
                     padding: const EdgeInsets.only(top: 8.0, left: 28),
                     child: Text('Extra in Wallet: ₹$walletBalance', style: AppStyles.bodySmall.copyWith(color: Colors.blue)),
                   ),
              ] else ...[
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text('Fully Paid (₹$amountPaid)', style: AppStyles.bodyMedium.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildInfoRow(String label, String value, {Color? valueColor, bool isBoldText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppStyles.bodyMedium.copyWith(color: Colors.grey[600])),
          Text(value, style: AppStyles.bodyMedium.copyWith(
            fontWeight: isBoldText ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppTheme.textBlack,
          )),
        ],
      ),
    );
  }
}
