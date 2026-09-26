import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearchvia/controllers/segment_plan.controller.dart';
import 'package:spresearchvia/controllers/auth.controller.dart';
import 'package:spresearchvia/core/theme/app_theme.dart';
import 'package:spresearchvia/screens/subscription/widgets/segment.dropdown.dart';
import 'package:spresearchvia/widgets/button.dart';
import '../../core/routes/app_routes.dart';
import '../../services/validation.service.dart';

class SelectSegmentScreen extends StatefulWidget {
  const SelectSegmentScreen({super.key});

  @override
  State<SelectSegmentScreen> createState() => _SelectSegmentScreenState();
}

class _SelectSegmentScreenState extends State<SelectSegmentScreen> {
  final segmentPlanController = Get.find<SegmentPlanController>();
  final RxnString hniGstin = RxnString();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      segmentPlanController.fetchPlans();
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;
      if (user?.gstin != null && ValidationService.validateGST(user!.gstin!)) {
        hniGstin.value = user.gstin;
      }
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

                // Active Plan Notice Banner
                Obx(() {
                  if (segmentPlanController.hasActiveSegment.value) {
                    final currentPlan = segmentPlanController.activeSegments.firstOrNull?['planName'] ?? 'Active Plan';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Current Subscription: $currentPlan',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBlue,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'A single user can only have one active plan at a time. You can activate or switch segments freely from Settings.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.tune_outlined, size: 16),
                              label: const Text('Manage Segments in Settings'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryBlue,
                                side: const BorderSide(color: AppTheme.primaryBlue),
                              ),
                              onPressed: () => Get.toNamed(AppRoutes.manageSegments),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),

                const Text(
                  'Select Segment',
                  style: TextStyle(fontSize: 14, color: AppTheme.primaryBlue),
                ),
                const SizedBox(height: 10),
                const SegmentDropdownMenu(),
                const SizedBox(height: 6),
                const Text(
                  'Select 1 initial segment included with your plan. You can activate additional segments freely anytime from Settings.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
                ),
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
                          onTap: () async {
                            segmentPlanController.selectPlan(plan.id);
                            if (plan.isHni) {
                              // Immediately open the GSTIN input field upon selection
                              final entered = await _promptForGstin(context);
                              if (entered != null && ValidationService.validateGST(entered)) {
                                hniGstin.value = entered;
                              }
                            }
                          },
                        ),
                        if (plan.isHni) ...[
                          Obx(() {
                            final isSelected = segmentPlanController.isPlanSelected(plan.id);
                            if (!isSelected) return const SizedBox.shrink();
                            final valid = hniGstin.value != null && ValidationService.validateGST(hniGstin.value!);
                            if (valid) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.green.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'GSTIN: ${hniGstin.value}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green.shade900,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          final entered = await _promptForGstin(context);
                                          if (entered != null && ValidationService.validateGST(entered)) {
                                            hniGstin.value = entered;
                                          }
                                        },
                                        child: Text(
                                          'Edit',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryBlue,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: InkWell(
                                  onTap: () async {
                                    final entered = await _promptForGstin(context);
                                    if (entered != null && ValidationService.validateGST(entered)) {
                                      hniGstin.value = entered;
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.amber.shade400),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Valid GSTIN required for HNI plan. Tap to enter.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.amber.shade900,
                                            ),
                                          ),
                                        ),
                                        Icon(Icons.chevron_right, color: Colors.amber.shade900, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                          }),
                        ],
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
              final hasActivePlan = segmentPlanController.hasActiveSegment.value;
              final hasSelection =
                  segmentPlanController.selectedPlanId.value != null;
              final selectedPlan = segmentPlanController.selectedPlan;
              final isHniPlan = selectedPlan?.isHni ?? false;
              final hasValidGst = hniGstin.value != null && ValidationService.validateGST(hniGstin.value!);

              // Without inputting a valid GST number or if user has active plan, button is disabled
              final canContinue = !hasActivePlan && hasSelection && (!isHniPlan || hasValidGst);

              String buttonTitle = 'Continue to Payment';
              if (hasActivePlan) {
                buttonTitle = 'Active Plan Already Exists';
              } else if (hasSelection && isHniPlan && !hasValidGst) {
                buttonTitle = 'Enter GSTIN to Continue';
              }

              return Button(
                title: buttonTitle,
                buttonType: hasActivePlan ? ButtonType.greyBorder : ButtonType.green,
                onTap: canContinue
                    ? () async {
                        // Block suspended users
                        final authController = Get.find<AuthController>();
                        if (authController.currentUser.value?.userStatus == 'SUSPENDED') {
                          authController.showSuspensionDialog();
                          return;
                        }

                        // Block if user already has an active plan
                        if (segmentPlanController.hasActiveSegment.value) {
                          Get.snackbar(
                            'Active Plan Exists',
                            'You already have an active subscription. A single user can only have one plan at a time. Manage your segments in Settings.',
                            backgroundColor: Colors.orange.shade100,
                            colorText: Colors.orange.shade900,
                            duration: const Duration(seconds: 4),
                          );
                          return;
                        }

                        // Strictly validate exactly 1 segment selected
                        final segmentId = segmentPlanController.selectedSegmentId.value;
                        if (segmentId == null || segmentId.trim().isEmpty) {
                          Get.snackbar(
                            'Select Segment',
                            'Please select 1 research segment to proceed with your plan.',
                            backgroundColor: Colors.orange.shade100,
                            colorText: Colors.orange.shade900,
                            duration: const Duration(seconds: 4),
                          );
                          return;
                        }

                        // Strictly validate plan is Spark or Splendid
                        final pName = (selectedPlan?.name ?? '').toUpperCase();
                        if (!pName.contains('SPARK') && !pName.contains('SPLENDID')) {
                          Get.snackbar(
                            'Invalid Plan',
                            'Strict Policy: Only "SPARK" or "SPLENDID" plan is purchasable.',
                            backgroundColor: Colors.red.shade100,
                            colorText: Colors.red.shade900,
                          );
                          return;
                        }

                        Get.toNamed(
                          AppRoutes.confirmPayment,
                          arguments: {
                            'plan': selectedPlan,
                            if (isHniPlan) 'gstin': hniGstin.value,
                          },
                        );
                      }
                    : null, // Strictly null makes the button untappable!
              );
            }),
          ),
        ),
      ),
    );
  }

  Future<String?> _promptForGstin(BuildContext context) async {
    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;
    final initialText = hniGstin.value ?? user?.gstin ?? '';

    final textController = TextEditingController(text: initialText);
    final RxString errorMessage = ''.obs;
    final RxBool isValid = false.obs;

    if (textController.text.trim().isNotEmpty &&
        ValidationService.validateGST(textController.text.trim())) {
      isValid.value = true;
    }

    return await Get.bottomSheet<String>(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.business, color: Colors.amber.shade900),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'GSTIN Required for HNI Plan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'HNI plans strictly require a valid 15-character Goods and Services Tax Identification Number (GSTIN) to purchase.',
              style: TextStyle(fontSize: 13, color: AppTheme.textGrey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: textController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 15,
              decoration: const InputDecoration(
                labelText: 'Enter 15-character GSTIN',
                hintText: 'e.g. 27AAPFU0939L1ZV',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              onChanged: (val) {
                final cleaned = val.trim().toUpperCase();
                if (cleaned.length == 15) {
                  if (ValidationService.validateGST(cleaned)) {
                    errorMessage.value = '';
                    isValid.value = true;
                  } else {
                    errorMessage.value = 'Invalid GSTIN format (e.g. 27AAPFU0939L1ZV)';
                    isValid.value = false;
                  }
                } else {
                  errorMessage.value = '';
                  isValid.value = false;
                }
              },
            ),
            Obx(() => errorMessage.value.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      errorMessage.value,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  )
                : const SizedBox.shrink()),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(
                    () => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isValid.value ? AppTheme.primaryGreen : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isValid.value
                          ? () {
                              final finalGstin = textController.text.trim().toUpperCase();
                              Get.back(result: finalGstin);
                            }
                          : null,
                      child: const Text('Confirm GSTIN'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
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
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Text(
                            'HNI Tier',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
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
            ),
            if (isHni) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_user_outlined, size: 14, color: Colors.amber.shade800),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'GSTIN input strictly required at checkout for this plan',
                        style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
