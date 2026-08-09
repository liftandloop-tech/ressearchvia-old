import 'package:flutter/material.dart';
import 'dart:io';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/razorpay_payment_handler.dart';
import '../../widgets/button.dart';
import '../../services/snackbar.service.dart';
import '../../core/models/razorpay_options.dart';
import '../../core/models/payment_callbacks.dart';
import '../../controllers/user.controller.dart';
import '../../controllers/auth.controller.dart';
import '../../core/routes/app_routes.dart';
import '../../controllers/segment_plan.controller.dart';
import '../../widgets/terms_section.dart';
import 'widgets/detail_row.dart';
import 'widgets/breakdown_row.dart';
import 'widgets/payment_option.dart';
import 'widgets/payment_icon_widget.dart';

class ConfirmPaymentScreen extends StatefulWidget {
  const ConfirmPaymentScreen({super.key});

  @override
  State<ConfirmPaymentScreen> createState() => _ConfirmPaymentScreenState();
}

class _ConfirmPaymentScreenState extends State<ConfirmPaymentScreen> {
  final RxBool agreedToTerms = false.obs;
  final RxBool authorizedPayment = false.obs;
  final RxBool isProcessing = false.obs;
  final RxInt selectedPaymentMethod = 1.obs;
  final RxBool isPartialSelection = true.obs;
  final customAmountController = TextEditingController();

  final RxDouble baseAmount = 0.0.obs;
  final RxDouble gstAmount = 0.0.obs;
  final RxDouble totalPayable = 0.0.obs;
  final RxDouble perDayCost = 0.0.obs;
  final RxString perDayCostText = ''.obs;

  final RazorpayPaymentHandler _paymentHandler = RazorpayPaymentHandler();
  late final UserController userController;
  late final SegmentPlanController segmentPlanController;
  SegmentPlan? selectedPlan;
  String? _currentPaymentId;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<UserController>()) {
      Get.put(UserController());
    }
    if (!Get.isRegistered<SegmentPlanController>()) {
      Get.put(SegmentPlanController());
    }
    userController = Get.find<UserController>();
    segmentPlanController = Get.find<SegmentPlanController>();

    final args = Get.arguments as Map<String, dynamic>?;
    selectedPlan = args?['plan'];

    if (selectedPlan != null) {
      _initializeValuesFromPlan();
    }

    customAmountController.addListener(_onCustomAmountChanged);
  }

  void _initializeValuesFromPlan() {
    if (selectedPlan == null) return;
    double amount = _parseAmountString(selectedPlan!.amount);
    _updateCalculations(amount);
  }

  void _onCustomAmountChanged() {
    String text = customAmountController.text.replaceAll(',', '').trim();
    if (text.isEmpty) {
      _initializeValuesFromPlan();
    } else {
      double? customAmount = double.tryParse(text);
      if (customAmount != null) {
        _updateCalculations(customAmount);
      }
    }
  }

  void _updateCalculations(double amount) {
    baseAmount.value = amount;
    gstAmount.value = amount * 0.18;
    totalPayable.value = amount + gstAmount.value;
    perDayCost.value = totalPayable.value / 365;
    perDayCostText.value = '₹${perDayCost.value.toStringAsFixed(0)}/day';
  }

  double _parseAmountString(String amountStr) {
    String cleanStr = amountStr.replaceAll('₹', '').replaceAll(',', '');
    if (cleanStr.toLowerCase().contains('lakh')) {
      cleanStr = cleanStr
          .toLowerCase()
          .replaceAll('lakh/year', '')
          .replaceAll('lakh', '')
          .trim();
      return double.parse(cleanStr) * 100000;
    }
    return double.tryParse(cleanStr) ?? 0.0;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  void dispose() {
    customAmountController.dispose();
    _paymentHandler.dispose();
    super.dispose();
  }

  void handlePaymentSuccess(
    String paymentId,
    String orderId,
    String signature,
  ) async {
    try {
      if (selectedPlan == null) {
        throw Exception('Invalid plan selected');
      }

      if (_currentPaymentId == null) {
        throw Exception('Payment session invalid');
      }

      final verified = await segmentPlanController.verifySegmentPayment(
        segmentId: selectedPlan!.categoryId,
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
      );

      if (verified) {
        SnackbarService.showSuccess('Payment completed successfully!');
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed(AppRoutes.tabs);
      } else {
        throw Exception('Payment verification failed');
      }
    } catch (e) {
      SnackbarService.showError('Payment verification failed: ${e.toString()}');
      Get.offAllNamed(
        AppRoutes.paymentFailure,
        arguments: {
          'message': 'Payment verification failed: ${e.toString()}',
          'backRoute': AppRoutes.selectSegment,
        },
      );
    } finally {
      isProcessing.value = false;
    }
  }

  void handlePaymentError(String errorMessage) {
    isProcessing.value = false;
    SnackbarService.showError(errorMessage);
    Future.delayed(const Duration(milliseconds: 500), () {
      Get.offAllNamed(
        AppRoutes.paymentFailure,
        arguments: {
          'message': errorMessage,
          'backRoute': AppRoutes.selectSegment,
        },
      );
    });
  }

  void handleExternalWallet(String walletName) {
    isProcessing.value = false;
    SnackbarService.showInfo('Payment via $walletName');
  }

  Future<void> _proceedToPay() async {
    debugPrint('DEBUG: _proceedToPay called');
    
    // Block suspended users
    final authController = Get.find<AuthController>();
    if (authController.currentUser.value?.userStatus == 'SUSPENDED') {
      authController.showSuspensionDialog();
      return;
    }

    if (!agreedToTerms.value || !authorizedPayment.value) {
      debugPrint('DEBUG: Terms not agreed or payment not authorized');
      SnackbarService.showWarning(
        'Please agree to the terms and authorize payment',
      );
      return;
    }

    if (selectedPlan == null) {
      debugPrint('DEBUG: No plan selected');
      SnackbarService.showError('Invalid plan selected');
      return;
    }

    debugPrint('DEBUG: Selected Plan ID: ${selectedPlan!.id}');
    isProcessing.value = true;

    try {
      if (selectedPaymentMethod.value == 2) {
        // Direct Bank Transfer Flow
        final isPartial = isPartialSelection.value;
        
        final responseData = await segmentPlanController.purchaseSegment(
          categoryId: segmentPlanController.selectedSegmentId.value ?? selectedPlan!.categoryId,
          planId: selectedPlan!.id,
          paymentMode: 'BANK_TRANSFER',
          isPartial: isPartial,
        );
        
        isProcessing.value = false;

        if (responseData != null) {
          final segmentsPayment = responseData['segmentsPayment'];
          final paymentId = segmentsPayment['_id'];
          final amount = segmentsPayment['amount'];
          
          if (paymentId == null) throw Exception('Payment ID missing');
          
          Get.toNamed(
             AppRoutes.bankTransferUpload, 
             arguments: {
               'plan': selectedPlan,
               'type': 'PLAN', 
               'amount': amount, // This is the base amount (X)
               'paymentId': paymentId,
               'isPartial': isPartial,
               'totalToPay': totalPayable.value, // This is X + GST
             }
          );
          return;
        }
      }

      debugPrint('DEBUG: Calling purchaseSegment...');
      final responseData = await segmentPlanController.purchaseSegment(
        categoryId: segmentPlanController.selectedSegmentId.value ?? selectedPlan!.categoryId,
        planId: selectedPlan!.id,
      );
      debugPrint('DEBUG: purchaseSegment response: $responseData');

      final segmentsPayment = responseData?['segmentsPayment'];
      debugPrint('DEBUG: segmentsPayment: $segmentsPayment');

      if (segmentsPayment == null) {
        throw Exception('Invalid response from server');
      }

      _currentPaymentId = segmentsPayment['_id'];
      final razorpayOrderId = segmentsPayment['razorpayOrderId'];
      
      // Amount from backend (should be total amount in rupees/paise?)
      // Backend: `amount: totalAmount` (Rupees)
      final amountDynamic = segmentsPayment['amount'];
      final double amount = (amountDynamic is int) 
          ? amountDynamic.toDouble() 
          : double.tryParse(amountDynamic.toString()) ?? 0.0;

      debugPrint('DEBUG: Payment ID: $_currentPaymentId');
      debugPrint('DEBUG: Razorpay Order ID: $razorpayOrderId');
      debugPrint('DEBUG: Amount: $amount');

      if (razorpayOrderId == null) {
        throw Exception('Order ID not received from backend');
      }

      final user = userController.currentUser.value;
      final userEmail = user?.email ?? '';
      final userPhone = user?.phone ?? '';
      final userName = user?.name ?? 'User';

      debugPrint(
        'DEBUG: User Info - Email: $userEmail, Phone: $userPhone, Name: $userName',
      );

      final options = RazorpayOptions(
        orderId: razorpayOrderId,
        amount: amount, // Backend calculated authoritative amount
        planName: selectedPlan!.name,
        userEmail: userEmail,
        userPhone: userPhone,
        userName: userName,
      );

      debugPrint('DEBUG: Initiating Razorpay with options: ${options.toMap()}');

      // Small delay to ensure UI state is settled before launching native bridge
      await Future.delayed(const Duration(milliseconds: 100));

      debugPrint('DEBUG: Calling Razorpay open...');
      _paymentHandler.initiatePayment(
        options: options,
        callbacks: PaymentCallbacks(
          onSuccess: handlePaymentSuccess,
          onError: handlePaymentError,
          onWallet: handleExternalWallet,
        ),
      );
    } catch (e) {
      debugPrint('DEBUG: Error in _proceedToPay: $e');
      isProcessing.value = false;
      SnackbarService.showError('Failed to initiate payment: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlueDark),
            onPressed: () => Get.back(),
          ),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Digital purchases are not available in the app.\nPlease contact your administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                color: AppTheme.textGrey,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlueDark),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Confirm Your Payment',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryBlueDark,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Review your selected plan or enter a custom amount to proceed.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppTheme.textGrey,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.maxFinite,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield, color: Color(0xFF10B981), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Secure Payment Gateway – 256-bit Encrypted',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${segmentPlanController.selectedSegment.value} – ${selectedPlan?.name ?? 'Splendid Plan'}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlueDark,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text(
                          'Change Plan',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DetailRow(label: 'Duration', value: '1 Year'),
                  const SizedBox(height: 8),
                  DetailRow(
                    label: 'Base Price',
                    value: selectedPlan?.amount ?? '₹0',
                  ),
                  const SizedBox(height: 8),
                  DetailRow(
                    label: 'Per-Day Cost',
                    value: selectedPlan?.perDay.split('\n')[0] ?? '',
                  ),
                  const SizedBox(height: 8),
                  DetailRow(label: 'Trader Type', value: 'Professional Trader'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const SizedBox(height: 24),
            
            // ... Removed Custom Payment Block ...
            
            const Text(
              'Payment Breakdown',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlueDark,
                ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => Column(
                children: [
                  BreakdownRow(
                    label: 'Subtotal',
                    value: _formatCurrency(baseAmount.value),
                  ),
                  const SizedBox(height: 12),
                  BreakdownRow(
                    label: 'GST (18%)',
                    value: _formatCurrency(gstAmount.value),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.borderGrey),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payable',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlueDark,
                        ),
                      ),
                      Text(
                        _formatCurrency(totalPayable.value),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Payment Options',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlueDark,
              ),
            ),
            const SizedBox(height: 16),
            PaymentOption(
              value: 1,
              groupValue: selectedPaymentMethod,
              title: 'Pay Online (Razorpay)',
              icon: Icons.payment,
            ),
            const SizedBox(height: 12),
            PaymentOption(
              value: 2,
              groupValue: selectedPaymentMethod,
              title: 'Bank Transfer (Offline)',
              icon: Icons.account_balance,
            ),
            
            Obx(() {
              if (selectedPaymentMethod.value == 2) {
                // Ensure partial is always true for bank transfers
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!isPartialSelection.value) isPartialSelection.value = true;
                });
                
                return Padding(
                  padding: const EdgeInsets.only(left: 32.0, top: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Note: Bank transfers allow you to upload your payment proof. An administrator will verify your receipt (Full or Partial) and apply any promised discounts before activating your plan.",
                          style: TextStyle(fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(height: 24),

            Obx(
              () => TermsSection(
                agreedToTerms: agreedToTerms.value,
                authorizedPayment: authorizedPayment.value,
                onTermsChanged: (val) => agreedToTerms.value = val,
                onAuthorizationChanged: (val) => authorizedPayment.value = val,
              ),
            ),
            const SizedBox(height: 24),

            Obx(
              () => Button(
                title: isProcessing.value
                    ? 'Processing...'
                    : 'Proceed to Pay ${_formatCurrency(totalPayable.value)}',
                buttonType: ButtonType.green,
                onTap: isProcessing.value ? null : _proceedToPay,
                showLoading: isProcessing.value,
              ),
            ),
            const SizedBox(height: 12),
            Button(
              title: 'Cancel / Go Back',
              buttonType: ButtonType.greyBorder,
              onTap: () => Get.back(),
            ),
            const SizedBox(height: 24),

            Center(
              child: Column(
                children: [
                  const Text(
                    'Powered by Razorpay Payment Gateway',
                    style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PaymentIconWidget(assetPath: 'assets/icons/visa.png'),
                      const SizedBox(width: 8),
                      PaymentIconWidget(
                        assetPath: 'assets/icons/mastercard.png',
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.lock,
                        color: Color(0xFF10B981),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.credit_card,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All transactions are encrypted and verified by PCI-DSS standards.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: AppTheme.textGrey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
