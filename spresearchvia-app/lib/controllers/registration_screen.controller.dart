import 'package:get/get.dart';
import '../services/razorpay_payment_handler.dart';
import '../controllers/registration_dropdown.controller.dart';
import '../core/models/razorpay_options.dart';
import '../core/models/payment_callbacks.dart';
import '../controllers/plan_purchase.controller.dart';
import '../controllers/user.controller.dart';
import '../core/models/payment.options.dart';
import '../core/models/plan.dart';
import '../core/routes/app_routes.dart';
import '../services/snackbar.service.dart';
import '../services/payment_preference.service.dart';
import '../services/secure_storage.service.dart';
import '../services/api_exception.service.dart';
import 'auth.controller.dart';

class RegistrationScreenController extends GetxController {
  final RxBool agreedToTerms = false.obs;
  final RxBool authorizedPayment = false.obs;
  final RxBool isProcessing = false.obs;
  final Rxn<String> currentPaymentId = Rxn<String>();
  final RxList<Plan> plans = <Plan>[].obs;
  final Rxn<Plan> selectedPlan = Rxn<Plan>();
  final Rxn<PaymentMethod> selectedPaymentMethod = Rxn<PaymentMethod>();

  // Store last payment options for retry
  RazorpayOptions? _lastPaymentOptions;

  final RazorpayPaymentHandler _paymentHandler = RazorpayPaymentHandler();
  final paymentPreferenceService = PaymentPreferenceService();
  final secureStorage = SecureStorageService();

  late final PlanPurchaseController planPurchaseController;
  late final UserController userController;

  @override
  void onInit() {
    super.onInit();

    if (!Get.isRegistered<PlanPurchaseController>()) {
      Get.put(PlanPurchaseController());
    }
    if (!Get.isRegistered<UserController>()) {
      Get.put(UserController());
    }

    planPurchaseController = Get.find<PlanPurchaseController>();
    userController = Get.find<UserController>();

    loadPlans();
    loadSavedPaymentMethod();
    checkPendingPayment();
  }

  void loadPlans() {
    plans.value = Plan.getMockPlans();
    if (plans.isNotEmpty) {
      selectedPlan.value = plans.first;
    }
  }

  void loadSavedPaymentMethod() {
    final method = paymentPreferenceService.getPaymentMethod();
    selectedPaymentMethod.value = method;
  }

  void checkPendingPayment() async {
    final pending = await secureStorage.getPendingPayment();
    if (pending != null) {
      final paymentId = pending['paymentId'];
      final orderId = pending['orderId'];

      SnackbarService.showInfo('Checking incomplete payment...');

      try {
        final success = await planPurchaseController.verifyPayment(
          paymentId: paymentId!,
          razorpayOrderId: orderId!,
          razorpayPaymentId: paymentId,
          razorpaySignature: '',
        );

        if (success) {
          await secureStorage.clearPendingPayment();
          SnackbarService.showSuccess('Previous payment verified!');
          await Future.delayed(const Duration(milliseconds: 500));
          Get.offAllNamed(AppRoutes.tabs);
        } else {
          await secureStorage.clearPendingPayment();
        }
      } catch (e) {
        Get.log('Error verifying pending payment: $e');
      }
    }
  }

  /// Called when user taps "Skip for now" on the registration screen.
  /// Sets the local skip flag and navigates to limited-access tabs.
  Future<void> skipRegistration() async {
    // 1. Persist to storage
    await secureStorage.setRegistrationSkipped(true);

    // 2. Update UserController's reactive flag immediately (synchronously)
    //    so TabsController reads it instantly without waiting for its own
    //    async _loadSkipFlag() to complete — this was the root cause of the
    //    popup not showing.
    if (Get.isRegistered<UserController>()) {
      Get.find<UserController>().isRegistrationSkipped.value = true;
    }

    Get.offAllNamed(AppRoutes.tabs);
  }

  void selectPaymentMethod(PaymentMethod method) {
    selectedPaymentMethod.value = method;
    paymentPreferenceService.savePaymentMethod(method);
  }

  Future<void> retryLastPayment() async {
    if (_lastPaymentOptions == null) {
      SnackbarService.showError('No payment to retry');
      return;
    }

    if (isProcessing.value) return;

    isProcessing.value = true;

    try {
      Get.log('Retrying payment with stored options');

      _paymentHandler.initiatePayment(
        options: _lastPaymentOptions!,
        callbacks: PaymentCallbacks(
          onSuccess: handlePaymentSuccess,
          onError: handlePaymentError,
          onWallet: handleExternalWallet,
        ),
      );
    } catch (e) {
      isProcessing.value = false;
      final apiError = ApiErrorHandler.handleError(e);
      Get.log('Retry Payment Error: $e');
      SnackbarService.showError('Failed to retry payment: ${apiError.message}');
    }
  }

  @override
  void onClose() {
    _paymentHandler.dispose();
    super.onClose();
  }

  void handlePaymentSuccess(
    String paymentId,
    String orderId,
    String signature,
  ) async {
    try {
      final storedPaymentId = currentPaymentId.value;
      if (storedPaymentId == null) {
        throw Exception('Payment ID not found');
      }

      final success = await planPurchaseController.verifyPayment(
        paymentId: storedPaymentId,
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
      );

      if (success) {
        await secureStorage.clearPendingPayment();
        // Clear skip flag in storage
        await secureStorage.setRegistrationSkipped(false);

        // Clear skip flag in memory so tabs are unlocked instantly
        if (Get.isRegistered<UserController>()) {
          Get.find<UserController>().isRegistrationSkipped.value = false;
        }

        SnackbarService.showSuccess('Payment completed successfully!');
        await Future.delayed(const Duration(milliseconds: 500));
        await Get.find<AuthController>().checkAuthStatus(); // Refresh and navigate
      } else {
        SnackbarService.showError(
          'Payment verification failed. Please contact support.',
        );
        Get.offAllNamed(AppRoutes.paymentFailure);
      }
    } catch (e) {
      final apiError = ApiErrorHandler.handleError(e);
      SnackbarService.showError('Payment verification failed: ${apiError.message}');
    } finally {
      isProcessing.value = false;
      currentPaymentId.value = null;
    }
  }

  void handlePaymentError(String errorMessage) async {
    isProcessing.value = false;

    // Check if payment was cancelled by user
    final isCancelled =
        errorMessage.toLowerCase().contains('cancel') ||
        errorMessage.toLowerCase().contains('back');

    if (isCancelled) {
      // Just show message and stay on current screen
      currentPaymentId.value = null;
      await secureStorage.clearPendingPayment();
      SnackbarService.showWarning('Payment cancelled');
    } else {
      // For actual errors, navigate to failure screen
      currentPaymentId.value = null;
      await secureStorage.clearPendingPayment();
      SnackbarService.showError(errorMessage);
      Get.toNamed(
        AppRoutes.paymentFailure,
        arguments: {
          'message': errorMessage,
          'backRoute': AppRoutes.registrationScreen,
          'canRetry': true,
        },
      );
    }
  }

  void handleExternalWallet(String walletName) async {
    isProcessing.value = false;
    currentPaymentId.value = null;
    await secureStorage.clearPendingPayment();
    SnackbarService.showInfo('Payment via $walletName');
  }

  Future<void> proceedToPay() async {
    if (isProcessing.value) return;
    
    // Block suspended users from paying
    final authController = Get.find<AuthController>();
    if (authController.currentUser.value?.userStatus == 'SUSPENDED') {
      authController.showSuspensionDialog();
      return;
    }

    if (!agreedToTerms.value || !authorizedPayment.value) {
      SnackbarService.showWarning(
        'Please agree to the terms and authorize payment to proceed',
      );
      return;
    }

    if (selectedPlan.value == null) {
      SnackbarService.showError('Please select a plan');
      return;
    }

    if (selectedPaymentMethod.value == null) {
      SnackbarService.showError('Please select a payment method');
      return;
    }

    isProcessing.value = true;

    try {
      final plan = selectedPlan.value!;
      final planName = plan.name;
      
      Get.log('Initiating payment flow for: $planName');

      // Fetch active selections for Trial Bundle
      String? bundledPlanId;
      String? bundledSegmentId;
      try {
        if (Get.isRegistered<RegistrationDropdownController>()) {
           final dropdownController = Get.find<RegistrationDropdownController>();
           bundledPlanId = dropdownController.selectedPlanId;
           bundledSegmentId = dropdownController.selectedSegmentId;
        }
      } catch (e) {
        Get.log('Error fetching bundled plan details: $e');
      }

      if (bundledPlanId == null) {
         SnackbarService.showError('Please select a segment plan for your trial');
         isProcessing.value = false;
         return;
      }

      // --- ADMIN ENTITLEMENT FLOW ---
      if (selectedPaymentMethod.value == PaymentMethod.adminEntitlement) {
         final orderData = await planPurchaseController.purchaseRegistration(
            type: plan.id, 
            paymentMode: 'ADMIN_ENTITLEMENT',
            segmentId: bundledSegmentId,
            planId: bundledPlanId
         );
         
         isProcessing.value = false;
         SnackbarService.showSuccess('Service request submitted to Admin.');
         await Future.delayed(const Duration(milliseconds: 1000));
         await Get.find<AuthController>().checkAuthStatus(); // Refresh and navigate
         return;
      }

      // --- BANK TRANSFER FLOW ---
      if (selectedPaymentMethod.value == PaymentMethod.bankTransfer) {
         
         final orderData = await planPurchaseController.purchaseRegistration(
            type: plan.id, 
            paymentMode: 'BANK_TRANSFER',
            segmentId: bundledSegmentId,
            planId: bundledPlanId,
            isPartial: true,
         );
         
         if (orderData == null) throw Exception('Failed to initiate bank transfer');
         
         final paymentIntentId = orderData['paymentId'];
         final amount = orderData['amount'];

         isProcessing.value = false;
         SnackbarService.showInfo('Redirecting to upload details...');
         
         Get.toNamed(
            AppRoutes.bankTransferUpload, 
            arguments: {
              'plan': plan,
              'type': 'REGISTRATION',
              'amount': amount,
              'paymentId': paymentIntentId,
              'isPartial': true,
            }
         );
         return;
      }

      // --- RAZORPAY FLOW ---
      
      final orderData = await planPurchaseController.purchaseRegistration(
        type: plan.id, // 'YEARLY' or 'LIFETIME'
        paymentMode: 'ONLINE',
        segmentId: bundledSegmentId,
        planId: bundledPlanId
      );

      if (orderData == null) {
        throw Exception('Order creation failed - no response from server');
      }

      Get.log('Order Response: $orderData');

      currentPaymentId.value = orderData['paymentId'];
      final razorpayOrderId = orderData['razorpayOrderId'];
      
      final amount = (orderData['amount'] is int) 
          ? (orderData['amount'] as int).toDouble() 
          : double.tryParse(orderData['amount'].toString()) ?? 0.0;

      if (currentPaymentId.value == null) {
        throw Exception('Payment ID not received from backend');
      }

      if (razorpayOrderId == null) {
        throw Exception('Order ID not received from backend');
      }
      
      await secureStorage.savePendingPayment(
        paymentId: currentPaymentId.value!,
        orderId: razorpayOrderId,
      );

      final user = userController.currentUser.value;
      final userEmail = user?.email ?? '';
      final userPhone = user?.phone ?? '';
      final userName = user?.name ?? 'User';

      final options = RazorpayOptions(
        orderId: razorpayOrderId,
        amount: amount, 
        planName: planName,
        userEmail: userEmail,
        userPhone: userPhone,
        userName: userName,
        hiddenMethod: selectedPaymentMethod.value,
      );

      // Store options for retry
      _lastPaymentOptions = options;

      Get.log('Razorpay Options: ${options.toMap()}');

      // Small delay to ensure UI state is settled before launching native bridge
      await Future.delayed(const Duration(milliseconds: 100));

      _paymentHandler.initiatePayment(
        options: options,
        callbacks: PaymentCallbacks(
          onSuccess: handlePaymentSuccess,
          onError: handlePaymentError,
          onWallet: handleExternalWallet,
        ),
      );
    } catch (e) {
      isProcessing.value = false;
      currentPaymentId.value = null;
      await secureStorage.clearPendingPayment();
      final apiError = ApiErrorHandler.handleError(e);
      Get.log('Payment Error: $e');
      SnackbarService.showError('Failed to initiate payment: ${apiError.message}');
    }
  }
}
