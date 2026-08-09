import '../core/config/app.config.dart';
import '../services/api_client.service.dart';
import '../services/mock_payment.service.dart';
import '../core/config/api.config.dart';

abstract class PaymentServiceInterface {
  Future<Map<String, dynamic>?> createOrder({
    required String userId,
    required String packageName,
    required double amount,
  });

  Future<bool> verifyPayment({
    required String paymentId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  });
}

class PaymentService implements PaymentServiceInterface {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final ApiClient _apiClient = ApiClient();
  final MockPaymentService _mockService = MockPaymentService();

  bool get _useMockService =>
      AppConfig.isDevelopment ||
      AppConfig.isFeatureEnabled(FeatureFlag.paymentMockEnabled);

  @override
  Future<Map<String, dynamic>?> createOrder({
    required String userId,
    required String packageName,
    required double amount,
  }) async {
    if (_useMockService) {
      final result = await _mockService.processPayment(
        amount: amount,
        paymentMethodId: 'mock_payment',
        planId: packageName,
      );

      return {
        'razorpayOrderId':
            'mock_order_${DateTime.now().millisecondsSinceEpoch}',
        'paymentId': 'mock_payment_${DateTime.now().millisecondsSinceEpoch}',
        'amount': amount,
        'currency': 'INR',
        'success': result['success'],
      };
    }

    try {
      final response = await _apiClient.post(
        ApiConfig.purchasePlan(userId),
        data: {'packageName': packageName, 'amount': amount},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return {
          'razorpayOrderId': data['orderCreate']['razorpayOrderId'],
          'paymentId': data['orderCreate']['_id'],
          'amount': amount,
          'currency': data['orderCreate']['razorpayCurrency'] ?? 'INR',
          'success': true,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> verifyPayment({
    required String paymentId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    if (_useMockService) {
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    }

    try {
      final response = await _apiClient.post(
        ApiConfig.verifyPayment,
        data: {
          'paymentId': paymentId,
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
        },
      );

      if (response.statusCode == 200) {
        return response.data['success'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
