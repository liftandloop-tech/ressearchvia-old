import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:get/get.dart';

import '../core/models/payment_callbacks.dart';
import '../core/models/razorpay_options.dart';

class RazorpayPaymentHandler {
  late final Razorpay _razorpay;
  PaymentCallbacks? _callbacks;

  RazorpayPaymentHandler() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void initiatePayment({
    required RazorpayOptions options,
    required PaymentCallbacks callbacks,
  }) {
    _callbacks = callbacks;
    try {
      Get.log('Opening Razorpay with options: ${options.toMap()}');
      _razorpay.open(options.toMap());
    } catch (e) {
      Get.log('Error opening Razorpay: $e');
      _callbacks?.onError('Failed to open payment gateway: ${e.toString()}');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Get.log('Payment Success: ${response.paymentId}');
    if (_callbacks != null) {
      _callbacks!.onSuccess(
        response.paymentId ?? '',
        response.orderId ?? '',
        response.signature ?? '',
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Get.log('Payment Error: ${response.code} - ${response.message}');
    if (_callbacks != null) {
      final errorMessage = response.message ?? 'Payment failed';
      _callbacks!.onError(errorMessage);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Get.log('External Wallet: ${response.walletName}');
    if (_callbacks != null && _callbacks!.onWallet != null) {
      _callbacks!.onWallet!(response.walletName ?? 'Unknown Wallet');
    }
  }

  void dispose() {
    _razorpay.clear();
    _callbacks = null;
  }
}
