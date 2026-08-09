import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_styles.dart';
import '../controllers/report.controller.dart';
import '../controllers/plan_purchase.controller.dart';
import '../controllers/auth.controller.dart';
import '../controllers/user.controller.dart';
import '../controllers/segment_plan.controller.dart';
import '../services/secure_storage.service.dart';
import '../core/routes/app_routes.dart';
import 'dashboard/dashboard.screen.dart';
import 'profile/profile.screen.dart';
import 'research/research_reports.screen.dart';
import 'subscription/choose_plan.screen.dart';

class TabsController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final RxBool isRegistrationSkipped = false.obs;

  late final List<Widget> screens;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is int) {
      currentIndex.value = Get.arguments;
    }
    screens = [
      const DashboardScreen(),
      const ResearchReportsScreen(),
      const ChoosePlanScreen(),
      const ProfileScreen(),
    ];

    // Load the skip flag once on startup
    _loadSkipFlag();

    // Show suspension popup if user is suspended
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSuspensionStatus();
    });
  }

  Future<void> _loadSkipFlag() async {
    // Step 1: Immediately read from UserController if already set
    if (Get.isRegistered<UserController>()) {
      final userCtrl = Get.find<UserController>();
      isRegistrationSkipped.value = userCtrl.isRegistrationSkipped.value;

      // Step 2: React to any future changes (e.g. UserController async-loads flag late)
      ever(userCtrl.isRegistrationSkipped, (bool val) {
        isRegistrationSkipped.value = val;
      });

      if (isRegistrationSkipped.value) return;
    }

    // Step 3: Fallback — read directly from storage
    final storage = SecureStorageService();
    final skipped = await storage.isRegistrationSkipped();
    isRegistrationSkipped.value = skipped;

    // Also sync back to UserController so it's consistent
    if (Get.isRegistered<UserController>() && skipped) {
      Get.find<UserController>().isRegistrationSkipped.value = true;
    }
  }

  void _checkSuspensionStatus() {
    Get.find<AuthController>().showSuspensionDialog();
  }

  /// Returns true if user has an active/complete registration from backend
  bool get _isRegistrationActive {
    final user = Get.find<AuthController>().currentUser.value;
    final status = user?.registrationStatus;
    return status == 'ACTIVE' || status == 'COMPLETE';
  }

  /// Returns true if the user should be blocked from Research/Plans tabs
  bool get _isRegistrationBlocked {
    // 1. Block if there is a pending registration balance (universal check)
    final segCtrl = Get.isRegistered<SegmentPlanController>()
        ? Get.find<SegmentPlanController>()
        : null;
    
    if (segCtrl != null && segCtrl.hasRegistrationPendingBalance) {
      Get.log('Tabs: Access blocked due to pending registration balance');
      return true;
    }

    // 2. If ACTIVE or COMPLETE, they are generally allowed
    if (_isRegistrationActive) return false;

    // 3. Block if the user explicitly skipped registration
    if (isRegistrationSkipped.value) {
      Get.log('Tabs: Access blocked because registration was skipped');
      return true;
    }

    return false;
  }

  void changeTab(int index) {
    if (index != currentIndex.value) {
      // Guard: Block Research (1) and Plans (2) for incomplete/skipped registration
      if ((index == 1 || index == 2) && _isRegistrationBlocked) {
        final segCtrl = Get.isRegistered<SegmentPlanController>() ? Get.find<SegmentPlanController>() : null;
        if (segCtrl != null && segCtrl.hasRegistrationPendingBalance) {
          Get.log('Tabs: Redirecting to Profile for pending registration balance.');
          currentIndex.value = 3; // Profile Tab
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Get.context != null) {
              ProfileScreen.showRegistrationDetailsPopup(Get.context!, Get.find<UserController>());
            }
          });
          return;
        }
        _showRegistrationRequiredDialog();
        return;
      }

      // If navigating AWAY from Research (index 1), reset sub-tab to default (Trading Call)
      if (currentIndex.value == 1) {
        if (Get.isRegistered<ReportController>()) {
          Get.find<ReportController>().selectedTabIndex.value = 0;
        }
      }
      currentIndex.value = index;
    }
  }

  void _showRegistrationRequiredDialog() {
    final RxInt countdown = 3.obs;
    Timer? countdownTimer;

    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff1E4A7C), Color(0xff0D2847)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff1E4A7C).withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lock icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Registration Required',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Complete your registration to access Research reports and subscription Plans.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                // Live countdown circle
                Obx(() => Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text(
                      countdown.value.toString(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )),
                const SizedBox(height: 12),
                Text(
                  'Redirecting to registration...',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),
                // "Go now" button
                GestureDetector(
                  onTap: () {
                    countdownTimer?.cancel();
                    if (Get.isDialogOpen == true) Get.back();
                    Get.toNamed(AppRoutes.registrationScreen);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Complete Registration Now',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    // Start the countdown timer after the dialog has been rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (countdown.value <= 1) {
          timer.cancel();
          if (Get.isDialogOpen == true) Get.back();
          Get.toNamed(AppRoutes.registrationScreen);
        } else {
          countdown.value--;
        }
      });
    });
  }
}

class TabsScreen extends StatelessWidget {
  const TabsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TabsController());

    if (!Get.isRegistered<ReportController>()) {
      Get.put(ReportController());
    }
    if (!Get.isRegistered<PlanPurchaseController>()) {
      Get.put(PlanPurchaseController());
    }

    return Obx(
      () => Scaffold(
        body: controller.screens[controller.currentIndex.value],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundWhite,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowMedium,
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: BottomNavigationBar(
                currentIndex: controller.currentIndex.value,
                onTap: controller.changeTab,
                type: BottomNavigationBarType.fixed,
                backgroundColor: AppTheme.backgroundWhite,
                selectedItemColor: AppTheme.primaryGreen,
                unselectedItemColor: AppTheme.iconGrey,
                selectedLabelStyle: AppStyles.tabLabel,
                unselectedLabelStyle: AppStyles.tabLabelInactive,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                enableFeedback: false,
                elevation: 0,
                items: [
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: BottomNavbarIcon(
                        iconPath: 'assets/icons/home.png',
                        isSelected: controller.currentIndex.value == 0,
                      ),
                    ),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: BottomNavbarIcon(
                        iconPath: 'assets/icons/analytics.png',
                        isSelected: controller.currentIndex.value == 1,
                      ),
                    ),
                    label: 'Research',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: BottomNavbarIcon(
                        iconPath: 'assets/icons/premium.png',
                        isSelected: controller.currentIndex.value == 2,
                      ),
                    ),
                    label: 'Plans',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: BottomNavbarIcon(
                        iconPath: 'assets/icons/person.png',
                        isSelected: controller.currentIndex.value == 3,
                      ),
                    ),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BottomNavbarIcon extends StatelessWidget {
  const BottomNavbarIcon({
    super.key,
    required this.iconPath,
    required this.isSelected,
  });

  final String iconPath;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        isSelected ? AppTheme.primaryGreen : AppTheme.iconGrey,
        BlendMode.srcIn,
      ),
      child: Image.asset(iconPath, width: 24, height: 24),
    );
  }
}
