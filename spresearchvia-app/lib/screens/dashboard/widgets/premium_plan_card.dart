import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/segment_plan.controller.dart';
import '../../../widgets/button.dart';
import '../../../core/routes/app_routes.dart';
import '../../../controllers/auth.controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../tabs.screen.dart';
import '../../profile/profile.screen.dart';
import '../../../controllers/user.controller.dart';

class PremiumPlanCard extends StatelessWidget {
  const PremiumPlanCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensuring controller is registered
    if (!Get.isRegistered<SegmentPlanController>()) {
      Get.put(SegmentPlanController());
    }

    return GetX<SegmentPlanController>(
      builder: (controller) {
        final isLoading = controller.isLoadingSegment.value;
        final segments = controller.activeSegments;
        final hasActiveSegment = controller.hasActiveSegment.value;
        
        // Check for account-level suspension
        final authController = Get.find<AuthController>();
        final isUserSuspended = authController.currentUser.value?.userStatus == 'SUSPENDED';

        final user = authController.currentUser.value;
        final isRegistrationPending = user?.registrationSource == 'APP' &&
                                      (user?.registrationStatus == 'PENDING');
        final isRegistrationRejected = user?.registrationStatus == 'REJECTED';
        
        // Check for partial registration balance - user is ACTIVE but owes registration balance
        final hasRegistrationBalance = controller.hasRegistrationPendingBalance;

        // Check if user has skipped registration (local flag)
        final isRegistrationSkipped = Get.isRegistered<TabsController>()
            ? Get.find<TabsController>().isRegistrationSkipped.value
            : false;
        final isRegistrationActive = user?.registrationStatus == 'ACTIVE' ||
            user?.registrationStatus == 'COMPLETE';

        if (isLoading) {
          return _buildLoadingCard();
        }

        if (isUserSuspended) {
           return _buildSuspendedUserCard();
        }

        if (isRegistrationPending || hasRegistrationBalance || isRegistrationRejected) {
           return _buildRegistrationPendingCard(context, authController, 
               isBalancePending: hasRegistrationBalance,
               isRejected: isRegistrationRejected);
        }

        // User has skipped registration and has no active registration
        if (isRegistrationSkipped && !isRegistrationActive) {
          return _buildRegistrationSkippedCard();
        }

        if (!hasActiveSegment || segments.isEmpty) {
          return _buildNoActivePlanCard();
        }

        // If simple single plan, show it directly
        if (segments.length == 1) {
          return _buildDetailedPlanCard(segments.first, controller);
        }

        // If multiple plans, show in a PageView
        return SizedBox(
          height: 200, // Compact height for clean card display
          child: PageView.builder(
            itemCount: segments.length,
            controller: PageController(viewportFraction: 0.93),
            padEnds: false,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: _buildDetailedPlanCard(segments[index], controller),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff1E4A7C), Color(0xff0D2847)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildNoActivePlanCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff6B7280), Color(0xff4B5563)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'No Active Plan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Subscribe to a segment to access premium features',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 24),
          Button(
            title: 'Select a Segment',
            buttonType: ButtonType.green,
            onTap: () {
              Get.toNamed(AppRoutes.selectSegment);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedPlanCard(Map<String, dynamic> segment, SegmentPlanController controller) {
    final segmentData = segment['segmentId'] as Map<String, dynamic>?;
    final segmentName = segmentData?['segmentName'] ?? 'Segment';
    final planName = segment['planName'] as String?; // Get plan name from response
    final validity = segmentData?['validity']?.toString() ?? '';
    final endDate = segment['expiryDate'] != null
        ? DateTime.parse(segment['expiryDate'].toString())
        : null;

    int daysRemaining = 0;
    if (endDate != null) {
      daysRemaining = endDate.difference(DateTime.now()).inDays;
      if (daysRemaining < 0) daysRemaining = 0;
    }

    final formattedExpiry = endDate != null
        ? DateFormat('MMMM dd, yyyy').format(endDate)
        : null;

    final partialId = controller.activePartialInfo.value?['intentId'];
    final isPartial = segment['_id'] == partialId || (segment['paymentIntentId'] == partialId && partialId != null);
    final partialData = isPartial ? controller.activePartialInfo.value : null;
    final isSuspended = segment['status'] == 'SUSPENDED';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSuspended
            ? [const Color(0xff6B7280), const Color(0xff374151)]
            : isPartial 
              ? [const Color(0xff1E3A8A), const Color(0xff1E40AF)] 
              : [const Color(0xff1E4A7C), const Color(0xff0D2847)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (planName != null && planName.isNotEmpty) ...[
                      Text(
                        planName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      segmentName,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSuspended ? const Color(0xffDC2626) : (isPartial ? Colors.orange.withOpacity(0.4) : const Color(0xff2C4D6F)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isSuspended ? 'Suspended' : (isPartial ? 'Partial' : 'Active'),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (isPartial && partialData != null) ...[
            _buildPartialProgress(partialData),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Plan Amount: ₹${partialData['actual_total_amount']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text("Total Paid so far: ₹${partialData['total_amount_paid']}", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    Text("Remaining Days: ${partialData['days_remaining']}", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
                TextButton(
                  onPressed: () => Get.toNamed(AppRoutes.bankTransferUpload, arguments: {
                    'plan': segment,
                    'amount': partialData['actual_total_amount'],
                    'totalToPay': partialData['actual_total_amount'],
                    'paymentId': partialData['intentId'],
                    'isPartial': true,
                    'isInstallment': true
                  }),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Pay Installment", style: TextStyle(color: Colors.white, fontSize: 12)),
                )
              ],
            )
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  daysRemaining.toString(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 35,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    daysRemaining == 1 ? 'day left' : 'days left',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (formattedExpiry != null) ...[
              const SizedBox(height: 8),
              Text(
                'Expires on $formattedExpiry',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSuspendedUserCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffEF4444), Color(0xffB91C1C)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Account Suspended',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your account has been suspended by the administrator. Please contact support for more details.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          Button(
            title: 'Contact Support',
            buttonType: ButtonType.blue,
            onTap: () {
              Get.toNamed(AppRoutes.contactRM);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPartialProgress(Map<String, dynamic> data) {
    final int current = data['total_duration_granted'] ?? 0;
    final int max = data['max_possible_days'] ?? 1;
    final double progress = (current / max).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("$current / $max Days", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text("${(progress * 100).toInt()}%", style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationSkippedCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff374151), Color(0xff1F2937)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.6)),
                ),
                child: const Text(
                  'Not Active',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Registration Not Active',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your registration to access Research, Plans, and premium features.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.white.withOpacity(0.75),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.registrationScreen),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Complete Now',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationPendingCard(BuildContext context, AuthController authController, {bool isBalancePending = false, bool isRejected = false}) {
    final title = isBalancePending 
        ? 'Registration Balance Due' 
        : isRejected 
            ? 'Registration Rejected' 
            : 'Registration Under Review';
            
    final badgeText = isBalancePending 
        ? 'Balance Pending' 
        : isRejected 
            ? 'REJECTED' 
            : 'Pending Approval';
            
    final message = isBalancePending
        ? 'You have an outstanding registration balance. Please complete your registration payment to unlock plan selection.'
        : isRejected
            ? 'Your registration for ${authController.currentUser.value?.displayRegistrationType ?? "Silver"} plan has been rejected. Please update your details or contact support.'
            : 'Your registration for ${authController.currentUser.value?.displayRegistrationType ?? "Silver"} plan is currently being verified by our team. This usually takes a few hours.';
            
    final buttonTitle = (isBalancePending || isRejected) ? 'Complete Registration Payment' : 'Refresh & Check Status';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff1E4A7C), Color(0xff0D2847)], // Keep premium theme but modify content
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isRejected ? Colors.red : Colors.orange).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isRejected ? Colors.red : Colors.orange),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Button(
            title: buttonTitle,
            buttonType: ButtonType.green,
            onTap: () async {
              if (isBalancePending || isRejected) {
                if (Get.isRegistered<UserController>()) {
                  ProfileScreen.showRegistrationDetailsPopup(context, Get.find<UserController>());
                }
              } else {
                await authController.checkAuthStatus();
                if (authController.currentUser.value?.registrationStatus == 'ACTIVE') {
                  if (Get.isRegistered<SegmentPlanController>()) {
                    Get.find<SegmentPlanController>().fetchActiveSegment();
                  }
                } else {
                  final tabs = Get.find<TabsController>();
                  tabs.changeTab(2);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
