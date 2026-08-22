import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../../core/config/app.config.dart';
import '../../core/models/payment_callbacks.dart';
import '../../core/models/razorpay_options.dart';
import '../../services/razorpay_payment_handler.dart';
import '../../services/secure_storage.service.dart';
import '../../services/snackbar.service.dart';

class ProxyController extends GetxController {
  final SecureStorageService _storage = SecureStorageService();
  late final dio.Dio _dioClient;
  late final RazorpayPaymentHandler _razorpayHandler;

  final isLoading = false.obs;
  final proxyData = Rxn<Map<String, dynamic>>();
  final pricingData = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    _razorpayHandler = RazorpayPaymentHandler();
    _dioClient = dio.Dio(
      dio.BaseOptions(
        baseUrl: AppConfig.baseUrl, // Point to l-l-backend base URL
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _setupInterceptors();
    fetchProxyInfo();
    fetchPricing();
  }

  @override
  void onClose() {
    _razorpayHandler.dispose();
    super.onClose();
  }

  void _setupInterceptors() {
    _dioClient.interceptors.add(
      dio.InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getAuthToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer ${token.replaceFirst("Bearer ", "")}';
          }
          handler.next(options);
        },
      ),
    );
  }

  Future<void> fetchProxyInfo() async {
    isLoading.value = true;
    try {
      final response = await _dioClient.get('/user/proxy/info');
      if (response.data != null && response.data['status'] == 'success') {
        proxyData.value = response.data['data'];
      }
    } catch (e) {
      debugPrint('Error fetching proxy info: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPricing() async {
    try {
      final response = await _dioClient.get('/user/proxy/pricing');
      if (response.data != null && response.data['status'] == 'success') {
        pricingData.value = response.data['brokers'];
      }
    } catch (e) {
      debugPrint('Error fetching pricing: $e');
    }
  }

  /// Initiates Razorpay payment for Proxy IP Purchase or Renewal
  Future<void> startProxyPurchaseFlow(
    int validityMonths, {
    required bool isRenewal,
    String? brokerCode,
  }) async {
    isLoading.value = true;
    try {
      // 1. Request Order Creation from Backend
      final response = await _dioClient.post(
        '/user/proxy/create-order',
        data: {
          'validity': validityMonths,
          'brokerCode': brokerCode ?? 'angel',
        },
      );

      if (response.data == null || response.data['status'] != 'success') {
        SnackbarService.showError(
          response.data?['remark'] ?? 'Failed to create payment order.',
          title: 'Error',
        );
        isLoading.value = false;
        return;
      }

      final orderData = response.data['data'];
      final String orderId = orderData['razorpayOrderId'];
      final double amountRupees = (orderData['amountRupees'] ?? 1.18).toDouble();

      final userData = await SecureStorageService().getUserData();
      final email = (userData?['email'] ?? userData?['APP_EMAIL'] ?? userData?['userObject']?['APP_EMAIL'] ?? '').toString();
      final rawPhone = (userData?['phone'] ?? userData?['mobile'] ?? userData?['APP_MOB_NO'] ?? userData?['userObject']?['APP_MOB_NO'] ?? '').toString();
      final phone = rawPhone.startsWith('91') && rawPhone.length == 12 ? rawPhone.substring(2) : rawPhone;
      final name = (userData?['fullName'] ?? userData?['name'] ?? userData?['APP_NAME'] ?? userData?['userObject']?['APP_NAME'] ?? 'Client').toString();

      // 2. Build Razorpay Options & Launch Gateway Modal
      final options = RazorpayOptions(
        orderId: orderId,
        amount: amountRupees,
        planName: 'Static Proxy IP (${validityMonths} Month${validityMonths > 1 ? 's' : ''})',
        userEmail: email,
        userPhone: phone,
        userName: name,
      );

      isLoading.value = false;

      _razorpayHandler.initiatePayment(
        options: options,
        callbacks: PaymentCallbacks(
          onSuccess: (paymentId, orderId, signature) async {
            await verifyPaymentAndAssignProxy(
              razorpayOrderId: orderId.isNotEmpty ? orderId : orderData['razorpayOrderId'],
              razorpayPaymentId: paymentId,
              razorpaySignature: signature,
              validity: validityMonths,
              isRenewal: isRenewal,
              brokerCode: brokerCode ?? 'angel',
            );
          },
          onError: (errorMessage) {
            SnackbarService.showError(
              errorMessage,
              title: 'Payment Failed',
            );
          },
        ),
      );
    } catch (e) {
      isLoading.value = false;
      SnackbarService.showError(
        'Something went wrong while initiating payment. Please try again.',
        title: 'Error',
      );
    }
  }

  /// Verifies Payment Signature on backend and assigns/renews Proxy IP
  Future<void> verifyPaymentAndAssignProxy({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required int validity,
    required bool isRenewal,
    String? brokerCode,
  }) async {
    isLoading.value = true;
    try {
      final response = await _dioClient.post(
        '/user/proxy/verify-payment',
        data: {
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
          'validity': validity,
          'isRenewal': isRenewal,
          'brokerCode': brokerCode ?? 'angel',
        },
      );

      if (response.data != null && response.data['status'] == 'success') {
        SnackbarService.showSuccess(
          isRenewal
              ? 'Static Proxy IP renewed successfully!'
              : 'Static Proxy IP assigned successfully!',
          title: 'Success',
        );
        fetchProxyInfo();
      } else {
        SnackbarService.showError(
          response.data?['remark'] ?? 'Payment verification failed.',
          title: 'Verification Failed',
        );
      }
    } catch (e) {
      SnackbarService.showError(
        'Failed to verify payment with server.',
        title: 'Error',
      );
    } finally {
      isLoading.value = false;
    }
  }
}

