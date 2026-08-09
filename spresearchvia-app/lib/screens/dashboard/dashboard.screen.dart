import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearchvia/core/theme/app_theme.dart';
import 'package:spresearchvia/screens/tabs.screen.dart';
import '../../core/utils/responsive.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../controllers/user.controller.dart';
import '../../controllers/report.controller.dart';

import '../../widgets/reminder.popup.dart';
import '../../widgets/app_logo.dart';
import 'widgets/premium_plan_card.dart';
import '../../controllers/dashboard.controller.dart';
import '../../controllers/segment_plan.controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController controller = Get.put(DashboardController());

  @override
  void initState() {
    super.initState();
    // Fetch required data for dashboard widgets
    if (!Get.isRegistered<ReportController>()) {
      Get.put(ReportController());
    }
    // Trigger silent refresh (Reports + Trading Calls)
    Get.find<ReportController>().refreshData();
    
    if (!Get.isRegistered<SegmentPlanController>()) {
      Get.put(SegmentPlanController());
    }
    Get.find<SegmentPlanController>().fetchActiveSegment();
  }

  @override
  Widget build(BuildContext context) {
    // Controller already injected
    final responsive = Responsive.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: responsive.padding(
                horizontal: AppDimensions.paddingMedium,
                vertical: AppDimensions.paddingSmall,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: responsive.spacing(AppDimensions.spacing10),
                    ),
                    SizedBox(
                      height: responsive.spacing(AppDimensions.logoHeight),
                      width: double.maxFinite,
                      child: const AppLogo(),
                    ),
                    SizedBox(height: responsive.spacing(5)),
                    SizedBox(
                      height: responsive.spacing(AppDimensions.containerMedium),
                      child: Row(
                        children: [
                          Expanded(
                            child: GetX<UserController>(
                              builder: (userController) {
                                final user = userController.currentUser.value;
                                final userName = user?.name ?? 'User';
                                final registrationType = user?.registrationType;

                                return Row(
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userName,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            color: AppTheme.primaryBlue,
                                            fontSize: responsive.sp(18),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          AppStrings.welcomeBackText,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            color: Colors.black,
                                            fontSize: responsive.sp(13),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (registrationType != null &&
                                        registrationType.isNotEmpty) ...[
                                      const Spacer(),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Registration Type',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: responsive.sp(10),
                                              color: AppTheme.textGrey,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: responsive.spacing(4)),
                                            _buildRegistrationBadge(
                                                user?.registrationStatus == 'ACTIVE' 
                                                  ? (user?.displayRegistrationType ?? '') 
                                                  : (user?.registrationStatus ?? 'PENDING'), 
                                                responsive),
                                        ],
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ),
                          /* Container(
                            width: responsive.spacing(
                              AppDimensions.containerSmall,
                            ),
                            height: responsive.spacing(
                              AppDimensions.containerSmall,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlueDark,
                              borderRadius: BorderRadius.circular(
                                responsive.radius(AppDimensions.radiusLarge),
                              ),
                            ),
                            child: Icon(
                              Icons.notifications,
                              color: Colors.white,
                              size: responsive.spacing(AppDimensions.iconLarge),
                            ),
                          ), */
                        ],
                      ),
                    ),
                    SizedBox(
                      height: responsive.spacing(AppDimensions.spacing10),
                    ),
                    const PremiumPlanCard(),

                    SizedBox(
                      height: responsive.spacing(AppDimensions.spacing20),
                    ),
                    Text(
                      AppStrings.thisMonth,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: responsive.sp(16),
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    SizedBox(
                      height: responsive.spacing(AppDimensions.spacing10),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: GetX<ReportController>(
                            init: ReportController(),
                            builder: (reportController) {
                              final reportCount =
                                  reportController.reports.length + 
                                  reportController.tradingCalls.length;
                                return InkWell(
                                  onTap: () {
                                    final reportCtrl = Get.find<ReportController>();
                                    reportCtrl.selectedTabIndex.value = 0;
                                    final tabsCtrl = Get.find<TabsController>();
                                    tabsCtrl.changeTab(1);
                                  },
                                  borderRadius: BorderRadius.circular(
                                    responsive.radius(
                                      AppDimensions.radiusMedium,
                                    ),
                                  ),
                                  child: Container(
                                    height: responsive.spacing(
                                      AppDimensions.containerLarge,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: AppDimensions.borderThin,
                                        color: AppTheme.borderGrey,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        responsive.radius(
                                          AppDimensions.radiusMedium,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          reportCount.toString(),
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: responsive.sp(20),
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.primaryBlue,
                                          ),
                                        ),
                                        Padding(
                                          padding: responsive.padding(
                                            horizontal: AppDimensions.spacing8,
                                          ),
                                          child: Text(
                                            AppStrings.callsAvailable,
                                            overflow: TextOverflow.clip,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              color: Colors.black,
                                              fontSize: responsive.sp(14),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                            },
                          ),
                        ),
                        SizedBox(
                          width: responsive.spacing(AppDimensions.spacing10),
                        ),
                        Expanded(
                          child: GetX<ReportController>(
                            init: ReportController(),
                            builder: (reportController) {
                              final researchReportCount = reportController.reports.length;
                                return InkWell(
                                  onTap: () {
                                    final reportCtrl = Get.find<ReportController>();
                                    reportCtrl.selectedTabIndex.value = 1;
                                    final tabsCtrl = Get.find<TabsController>();
                                    tabsCtrl.changeTab(1);
                                  },
                                  borderRadius: BorderRadius.circular(
                                    responsive.radius(AppDimensions.radiusMedium),
                                  ),
                                  child: Container(
                                    height: responsive.spacing(
                                      AppDimensions.containerLarge,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: AppDimensions.borderThin,
                                        color: AppTheme.borderGrey,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        responsive.radius(AppDimensions.radiusMedium),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          researchReportCount.toString(),
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: responsive.sp(20),
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.primaryBlue,
                                          ),
                                        ),
                                        Padding(
                                          padding: responsive.padding(
                                            horizontal: AppDimensions.spacing8,
                                          ),
                                          child: Text(
                                            AppStrings.researchHours,
                                            overflow: TextOverflow.clip,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              color: Colors.black,
                                              fontSize: responsive.sp(14),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: responsive.spacing(AppDimensions.spacing20),
                    ),
                    
                    // Contact RM Section
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.contactRM),
                      child: Container(
                        padding: responsive.padding(
                          horizontal: AppDimensions.paddingMedium,
                          vertical: AppDimensions.paddingMedium,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryBlue,
                              AppTheme.primaryBlueDark,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            responsive.radius(AppDimensions.radiusMedium),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: responsive.spacing(50),
                              height: responsive.spacing(50),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(
                                  responsive.radius(AppDimensions.radiusSmall),
                                ),
                              ),
                              child: Icon(
                                Icons.support_agent_rounded,
                                color: Colors.white,
                                size: responsive.spacing(28),
                              ),
                            ),
                            SizedBox(width: responsive.spacing(15)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Contact RM',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: responsive.sp(16),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: responsive.spacing(2)),
                                  Text(
                                    'Get in touch with your Relationship Manager',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: responsive.sp(12),
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: responsive.spacing(18),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: responsive.spacing(AppDimensions.spacing20),
                    ),
                  ],
                ),
              ),
            ),
            Obx(
              () => Visibility(
                visible: controller.showReminder.value,
                child: Container(
                  color: const Color.fromARGB(182, 143, 143, 143),
                  child: Obx(
                    () => ReminderPopup(
                      onClose: controller.closeReminder,
                      onRenew: () => controller.renewNow(context),
                      daysRemaining: controller.reminderDays.value,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationBadge(String type, Responsive responsive) {
    Color startColor;
    Color endColor;
    bool isCustom = false;

    String displayText = type;
    final lowerType = type.toLowerCase();

    if (lowerType.contains('gold') || lowerType.contains('lifetime')) {
      displayText = 'GOLD';
      startColor = const Color(0xFFFFD700); // Gold
      endColor = const Color(0xFFB8860B); // Darker Gold
    } else if (lowerType.contains('silver') || lowerType.contains('yearly')) {
      displayText = 'SILVER';
      startColor = const Color(0xFFC0C0C0); // Silver
      endColor = const Color(0xFF708090); // Slate Gray
    } else if (lowerType.contains('alpha') || lowerType.contains('all')) {
      displayText = type.toUpperCase();
      startColor = AppTheme.primaryBlue;
      endColor = AppTheme.primaryBlueDark;
    } else if (lowerType.contains('pending')) {
      displayText = 'PENDING';
      startColor = Colors.orange;
      endColor = Colors.deepOrange;
    } else if (lowerType.contains('rejected')) {
      displayText = 'REJECTED';
      startColor = Colors.red;
      endColor = Colors.redAccent;
    } else {
      displayText = type.toUpperCase();
      startColor = AppTheme.primaryBlue.withOpacity(0.1);
      endColor = AppTheme.primaryBlue.withOpacity(0.2);
      isCustom = true;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(12),
        vertical: responsive.spacing(4),
      ),
      decoration: BoxDecoration(
        gradient: isCustom
            ? null
            : LinearGradient(
                colors: [startColor, endColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isCustom ? startColor : null,
        borderRadius: BorderRadius.circular(responsive.radius(20)),
        boxShadow: isCustom
            ? null
            : [
                BoxShadow(
                  color: startColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
        border: isCustom
            ? Border.all(color: AppTheme.primaryBlue.withOpacity(0.3))
            : null,
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: isCustom ? AppTheme.primaryBlue : Colors.white,
          fontSize: responsive.sp(10),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}
