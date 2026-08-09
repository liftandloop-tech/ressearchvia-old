import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spresearchvia/controllers/auth.controller.dart';
import 'package:spresearchvia/controllers/user.controller.dart';
import '../profile/profile.screen.dart';
import '../../widgets/active_plan_card.dart';
import '../../core/models/plan.dart';
import '../../controllers/segment_plan.controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/button.dart';
import 'widgets/feature_item.dart';

class ChoosePlanScreen extends StatefulWidget {
  const ChoosePlanScreen({super.key});

  @override
  State<ChoosePlanScreen> createState() => _ChoosePlanScreenState();
}

class _ChoosePlanScreenState extends State<ChoosePlanScreen> {
  final segmentController = Get.put(SegmentPlanController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      segmentController.fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;
    final isSuspended = user?.userStatus == 'SUSPENDED';
    
    // Check if registration is pending
    // Rule 1: If SELF_REGISTERED and Status is PENDING
    // Rule 2: If ACTIVE but has unpaid registration balance
    final segCtrl = Get.isRegistered<SegmentPlanController>()
        ? Get.find<SegmentPlanController>()
        : null;
    final hasRegistrationBalance = segCtrl?.hasRegistrationPendingBalance ?? false;
    final isRegistrationPending = (user?.registrationSource == 'APP' &&
                                  (user?.registrationStatus == 'PENDING')) ||
                                  hasRegistrationBalance;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Choose Your Segment',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryBlueDark,
          ),
        ),
        centerTitle: true,
      ),
      body: isSuspended || isRegistrationPending
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSuspended ? Icons.lock_person_rounded : Icons.pending_actions_rounded, 
                      size: 80, 
                      color: isSuspended ? AppTheme.error.withOpacity(0.5) : AppTheme.primaryBlue.withOpacity(0.5)
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isSuspended ? 'Access Restricted' : 'Registration Pending',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlueDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isSuspended 
                        ? 'Subscription plans are not available for suspended accounts. Please contact support to resolve this issue.'
                        : hasRegistrationBalance
                          ? 'You have an outstanding registration balance. Please complete your registration payment to access and purchase subscription plans.'
                          : 'Your registration is currently being verified by our admin team. Once approved, you will be able to browse and subscribe to segment plans. This usually takes 2-4 hours.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: AppTheme.textGrey,
                      ),
                    ),
                    if (!isSuspended) ...[
                      const SizedBox(height: 32),
                      if (hasRegistrationBalance)
                        Button(
                          title: 'Complete Registration Payment',
                          buttonType: ButtonType.blue,
                          onTap: () {
                             if (Get.context != null && Get.isRegistered<UserController>()) {
                               ProfileScreen.showRegistrationDetailsPopup(Get.context!, Get.find<UserController>());
                             }
                          },
                        )
                      else
                        Button(
                          title: 'Refresh Status',
                          buttonType: ButtonType.blue,
                          onTap: () async {
                            await authController.checkAuthStatus();
                            if (authController.currentUser.value?.registrationStatus == 'ACTIVE') {
                              segmentController.fetchData();
                            }
                          },
                        ),
                    ],
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlueDark,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),





              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'What\'s included:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlueDark,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              FeatureItem(icon: Icons.show_chart, text: 'Advanced Analytics'),
              const SizedBox(height: 12),
              FeatureItem(
                icon: Icons.all_inclusive,
                text: 'Unlimited Transactions',
              ),
              const SizedBox(height: 12),
              FeatureItem(icon: Icons.headset_mic, text: 'Priority Support'),
              const SizedBox(height: 12),
              FeatureItem(icon: Icons.security, text: 'Enhanced Security'),
              const SizedBox(height: 32),

              Button(
                title: 'Choose segment',
                buttonType: ButtonType.green,
                onTap: () {
                  Get.toNamed(AppRoutes.selectSegment);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
