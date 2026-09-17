import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/services/user_payment.service.dart';

class UserPaymentController extends GetxController {
  final UserPaymentService _paymentService = Get.find<UserPaymentService>();

  var isLoading = false.obs;
  var error = ''.obs;
  var paymentHistory = <Map<String, dynamic>>[].obs;
  var totalPayments = 0.obs;
  var currentPage = 1.obs;
  var filterType = 'ALL'.obs; // ALL, PLAN, REGISTRATION, REFUND
  final int itemsPerPage = 10;
  String? _currentUserId;

  List<Map<String, dynamic>> get filteredPayments {
    if (filterType.value == 'ALL') return paymentHistory;
    if (filterType.value == 'REFUND') {
      return paymentHistory.where((p) {
        final typeStr = (p['type'] ?? '').toString().toLowerCase();
        final statusStr = (p['status'] ?? '').toString().toUpperCase();
        final sourceStr = (p['source'] ?? '').toString().toLowerCase();
        return typeStr.contains('refund') ||
            statusStr.contains('REFUND') ||
            sourceStr == 'refund';
      }).toList();
    }
    if (filterType.value == 'REGISTRATION') {
      return paymentHistory.where((p) {
        final typeStr = (p['type'] ?? '').toString().toLowerCase();
        final planStr = (p['planName'] ?? '').toString().toLowerCase();
        return typeStr.contains('registration') || planStr.contains('registration');
      }).toList();
    }
    if (filterType.value == 'PLAN') {
      return paymentHistory.where((p) {
        final typeStr = (p['type'] ?? '').toString().toLowerCase();
        final statusStr = (p['status'] ?? '').toString().toUpperCase();
        final isReg = typeStr.contains('registration');
        final isRefund = typeStr.contains('refund') || statusStr.contains('REFUND');
        return !isReg && !isRefund;
      }).toList();
    }
    return paymentHistory;
  }

  void setFilter(String filter) {
    filterType.value = filter;
    currentPage.value = 1;
  }

  void nextPage() {
    final totalPages = (filteredPayments.length / itemsPerPage).ceil();
    if (currentPage.value < totalPages) {
      currentPage.value++;
    }
  }

  void previousPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
    }
  }

  void goToPage(int page) {
    currentPage.value = page;
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'refunded':
        return const Color(0xFF9333EA);
      case 'paid':
      case 'success':
        return AppTheme.successGreen;
      case 'pending':
      case 'created':
        return AppTheme.warningOrange;
      case 'failed':
        return AppTheme.errorRed;
      default:
        return AppTheme.textSecondary;
    }
  }

  Future<void> fetchPaymentHistory(String userId, {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _currentUserId == userId &&
        (isLoading.value || paymentHistory.isNotEmpty)) {
      return;
    }
    _currentUserId = userId;

    isLoading.value = true;

    try {
      final trimmedId = userId.trim();
      debugPrint('Fetching payment history for userId: $trimmedId');
      final response = await _paymentService.getUserPaymentHistory(trimmedId);
      debugPrint('Payment history raw response: $response');

      if (response['status'] != null && response['status'] != 200) {
        error.value = 'API Error: ${response['message'] ?? response['status']}';
        paymentHistory.value = [];
        totalPayments.value = 0;
        return;
      }

      Map? data;
      if (response.containsKey('data') && response['data'] is Map) {
        data = response['data'] as Map;
      } else if (response.containsKey('segmentsPayment')) {
        data = response;
      }

      if (data != null) {
        final List? payments = data['segmentsPayment'];
        final int count = data['segmentsPaymentCount'] ?? 0;

        if (payments != null) {
          paymentHistory.assignAll(
            List<Map<String, dynamic>>.from(payments),
          );
          totalPayments.value = count;
          debugPrint('Successfully loaded ${paymentHistory.length} payments');
        } else {
          error.value = 'Payment list missing in response (Count: $count)';
          paymentHistory.value = [];
          totalPayments.value = 0;
        }
      } else {
        error.value = 'No payment data found in response';
        paymentHistory.value = [];
        totalPayments.value = 0;
      }
    } catch (e) {
      debugPrint('Error fetching payment history: $e');
      error.value = e.toString();
      paymentHistory.value = [];
      totalPayments.value = 0;
    } finally {
      isLoading.value = false;
    }
  }
}
