import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/services/user_payment.service.dart';
import 'user_details.controller.dart';
import '../subscription/manage_subscription.controller.dart'; // import just in case, but unused for now

class UserPaymentController extends GetxController {
  final UserPaymentService _paymentService = Get.find<UserPaymentService>();

  var isLoading = false.obs;
  var error = ''.obs;
  var paymentHistory = <Map<String, dynamic>>[].obs;
  var totalPayments = 0.obs;
  var currentPage = 1.obs;
  final int itemsPerPage = 10;
  String? _currentUserId;

  void nextPage() {
    final totalPages = (paymentHistory.length / itemsPerPage).ceil();
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

  Future<void> fetchPaymentHistory(String userId) async {
    if (_currentUserId == userId &&
        (isLoading.value || paymentHistory.isNotEmpty))
      return;
    _currentUserId = userId;

    isLoading.value = true;

    try {
      final trimmedId = userId.trim();
      debugPrint('Fetching payment history for userId: $trimmedId');
      final response = await _paymentService.getUserPaymentHistory(trimmedId);
      debugPrint('Payment history raw response: $response');

      if (response != null) {
        if (response is Map &&
            response['status'] != null &&
            response['status'] != 200) {
          error.value =
              'API Error: ${response['message'] ?? response['status']}';
          paymentHistory.value = [];
          totalPayments.value = 0;
          return;
        }

        if (response is Map) {
          Map? data;
          if (response.containsKey('data') && response['data'] is Map) {
            data = response['data'] as Map;
          } else if (response.containsKey('segmentsPayment')) {
            // If segmentsPayment is directly in the root, treat the root as 'data'
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
              debugPrint(
                'Successfully loaded ${paymentHistory.length} payments',
              );
            } else {
              error.value = 'Payment list missing in response (Count: $count)';
              debugPrint('Missing segmentsPayment in data: $data');
              paymentHistory.value = [];
              totalPayments.value = 0;
            }
          } else {
            error.value =
                'No payment data found in response (Keys: ${response.keys.join(", ")})';
            debugPrint('Unexpected response structure: $response');
            paymentHistory.value = [];
            totalPayments.value = 0;
          }
        } else {
          error.value =
              'No payment data found in response (Response is not a Map)';
          debugPrint('Unexpected response type: $response');
          paymentHistory.value = [];
          totalPayments.value = 0;
        }
      } else {
        error.value = 'Empty response from server';
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
