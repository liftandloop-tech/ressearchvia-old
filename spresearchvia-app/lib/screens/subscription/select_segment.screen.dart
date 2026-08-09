import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearchvia/controllers/segment_plan.controller.dart';
import 'package:spresearchvia/controllers/auth.controller.dart';
import 'package:spresearchvia/core/theme/app_theme.dart';
import 'package:spresearchvia/screens/subscription/widgets/segment.dropdown.dart';
import 'package:spresearchvia/widgets/button.dart';
import '../../core/routes/app_routes.dart';

class SelectSegmentScreen extends StatefulWidget {
  const SelectSegmentScreen({super.key});

  @override
  State<SelectSegmentScreen> createState() => _SelectSegmentScreenState();
}

class _SelectSegmentScreenState extends State<SelectSegmentScreen> {
  final segmentPlanController = Get.find<SegmentPlanController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      segmentPlanController.fetchPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Get.back();
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(
                    Icons.arrow_back,
                    color: AppTheme.textBlack,
                  ),
                ),
                const Text(
                  'Select Your Research Segment',
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Choose the segment and plan type that suits your trading preference.',
                  overflow: TextOverflow.clip,
                  style: TextStyle(fontSize: 12, color: AppTheme.textBlack),
                ),
                const SizedBox(height: 15),
                const Divider(height: 1, color: AppTheme.borderGrey),
                const SizedBox(height: 15),
                const Text(
                  'Select Segment',
                  style: TextStyle(fontSize: 14, color: AppTheme.primaryBlue),
                ),
                const SizedBox(height: 15),
                const SegmentDropdownMenu(),
                const SizedBox(height: 10),
                const Divider(color: AppTheme.infoBorder),
                const SizedBox(height: 15),

                Obx(() {
                  if (segmentPlanController.isLoading.value) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Loading plans...',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (segmentPlanController.error.value != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Failed to load plans',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              segmentPlanController.error.value ?? '',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textGrey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () => segmentPlanController.retry(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final plans = segmentPlanController.availablePlans;
                  if (plans.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text(
                          'No plans available',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (final plan in plans) ...[ 
                        SegmentPlanCard(
                          id: plan.id,
                          name: plan.name,
                          description: plan.description,
                          amount: plan.amount,
                          perDay: plan.perDay,
                          benefits: plan.benefits,
                          badge: plan.badge,
                          isPopular: plan.isPopular,
                          isHni: plan.isHni,
                          isSelected: segmentPlanController.isPlanSelected(
                            plan.id,
                          ),
                          onTap: () =>
                              segmentPlanController.selectPlan(plan.id),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                }),

              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Obx(() {
              final hasSelection =
                  segmentPlanController.selectedPlanId.value != null;
              final selectedPlan = segmentPlanController.selectedPlan;
              final isHniPlan = selectedPlan?.isHni ?? false;

              return Button(
                title: isHniPlan ? 'Request Custom Plan' : 'Continue to Payment',
                buttonType: ButtonType.green,
                onTap: hasSelection
                    ? () async {
                        // Block suspended users
                        final authController = Get.find<AuthController>();
                        if (authController.currentUser.value?.userStatus == 'SUSPENDED') {
                          authController.showSuspensionDialog();
                          return;
                        }

                        if (isHniPlan) {
                          // Handle HNI plan request
                          await segmentPlanController.requestHniPlan(
                            categoryId: segmentPlanController.selectedSegmentId.value ?? selectedPlan!.categoryId,
                            planId: selectedPlan!.id,
                          );
                        } else {
                          // Regular plan flow
                          Get.toNamed(
                            AppRoutes.confirmPayment,
                            arguments: {'plan': selectedPlan},
                          );
                        }
                      }
                    : null,
              );
            }),
          ),
        ),
      ),
    );
  }
}

class SegmentPlanCard extends StatelessWidget {
  const SegmentPlanCard({
    super.key,
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    required this.perDay,
    required this.benefits,
    required this.isSelected,
    this.badge,
    this.isPopular = false,
    this.isHni = false,
    this.onTap,
  });

  final String id;
  final String name, description, amount, perDay;
  final List<String> benefits;
  final bool isSelected;
  final String? badge;
  final bool isPopular;
  final bool isHni;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.borderGrey,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? AppTheme.primaryGreen.withValues(alpha: 0.05)
              : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPopular
                        ? AppTheme.primaryGreen
                        : AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      if (isHni) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppTheme.textGrey,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? AppTheme.primaryGreen : AppTheme.textGrey,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: const TextStyle(fontSize: 12, color: AppTheme.textBlack),
            ),
            const SizedBox(height: 15),
            if (!isHni)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          amount,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        perDay.split('\n')[0],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      if (perDay.contains('\n'))
                        Text(
                          perDay.split('\n')[1],
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textGrey,
                          ),
                        ),
                    ],
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Custom pricing and validity will be provided by our team',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 15),
            for (String benefit in benefits)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
