import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../services/snackbar.service.dart';
import '../services/api_client.service.dart';
import '../services/api_exception.service.dart';
import '../services/secure_storage.service.dart';
import '../core/config/api.config.dart';

class SegmentPlan {
  final String id;
  final String category;
  final String name;
  final String description;
  final String amount;
  final String perDay;
  final List<String> benefits;
  final String? badge;
  final bool isPopular;
  final String categoryId;
  final bool isHni;

  SegmentPlan({
    required this.id,
    required this.category,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.amount,
    required this.perDay,
    required this.benefits,
    this.badge,
    this.isPopular = false,
    this.isHni = false,
  });

  factory SegmentPlan.fromJson(Map<String, dynamic> json) {
    var rawBenefits = json['planFeatures'];
    List<String> parsedBenefits = [];
    if (rawBenefits is String) {
      var cleaned = rawBenefits.replaceAll(RegExp(r"[\[\]']"), "");
      if (cleaned.isNotEmpty) {
        parsedBenefits = cleaned.split(',').map((e) => e.trim()).toList();
      }
    } else if (rawBenefits is List) {
      parsedBenefits = rawBenefits.map((e) => e.toString()).toList();
    }

    return SegmentPlan(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      categoryId: json['segmentsId']?.toString() ?? '',
      category:
          json['segmentsName']?.toString() ??
          json['category']?.toString() ??
          '',
      name:
          '${json['segmentsName']?.toString() ?? json['category']?.toString() ?? ''} ${json['planName']?.toString() ?? json['name']?.toString() ?? 'Unnamed Plan'}'
              .trim(),
      description:
          json['discription']?.toString() ??
          json['description']?.toString() ??
          '',
      amount: json['price']?.toString() ?? json['amount']?.toString() ?? '0',
      perDay: (json['perDayCharge'] != null)
          ? 'Starts from ₹${json['perDayCharge']}/day'
          : (json['perDay']?.toString() ?? ''),
      benefits: parsedBenefits.isNotEmpty
          ? parsedBenefits
          : ((json['benefits'] as List?)?.map((e) => e.toString()).toList() ??
                []),
      badge: json['badge']?.toString(),
      isPopular: json['isPopular'] ?? json['popular'] ?? false,
      isHni: json['isHni'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'category': category,
      'name': name,
      'description': description,
      'amount': amount,
      'perDay': perDay,
      'benefits': benefits,
      'badge': badge,
      'isPopular': isPopular,
      'isHni': isHni,
    };
  }
}

class SegmentPlanController extends GetxController {
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storage = SecureStorageService();

  final isLoading = false.obs;
  final availablePlans = <SegmentPlan>[].obs;
  final selectedPlanId = Rxn<String>();
  final error = Rxn<String>();
  final selectedSegment = 'SPARK'.obs;
  final selectedSegmentId = RxnString();
  final activeSegments = <Map<String, dynamic>>[].obs;
  final activePartialInfo = Rxn<Map<String, dynamic>>();
  final hasActiveSegment = false.obs;
  final isLoadingSegment = false.obs;
  
  DateTime? _lastActiveSegmentFetch;
  static const Duration _fetchThreshold = Duration(seconds: 60);

  Future<String?> get userId => _storage.getUserId();

  @override
  void onInit() {
    super.onInit();
    // Auto-fetch plans for default segment (SPARK) on creation
    fetchPlans();
  }

  Future<void> fetchData() async {
    fetchPlans();
    fetchActiveSegment();
    fetchActivePartialInfo();
  }

  Future<void> fetchActivePartialInfo() async {
    try {
      final response = await _apiClient.get('/acquisition/active-partial-info');
      if (response.statusCode == 200) {
        activePartialInfo.value = response.data['data'];
      } else {
        activePartialInfo.value = null;
      }
    } catch (e) {
      activePartialInfo.value = null;
    }
  }

  /// Returns true if user is ACTIVE but still has an unpaid REGISTRATION balance.
  /// Used by NavBar, Dashboard cards, and Plans screen to gate access universally.
  bool get hasRegistrationPendingBalance {
    final info = activePartialInfo.value;
    if (info == null) return false;
    final type = info['purchaseType'] ?? info['purchase_type'];
    final hasBal = info['has_registration_balance'];
    return type == 'REGISTRATION' && hasBal == true;
  }

  Future<void> fetchActiveSegment({bool force = false}) async {
    final now = DateTime.now();
    if (!force && _lastActiveSegmentFetch != null && 
        now.difference(_lastActiveSegmentFetch!) < _fetchThreshold && 
        activeSegments.isNotEmpty) {
      debugPrint('SegmentPlanController: Skipping active segment fetch, data fresh.');
      return;
    }
    
    try {
      isLoadingSegment.value = true;
      _lastActiveSegmentFetch = now;
      fetchActivePartialInfo(); // Parallel fetch
      final uid = await userId;
      if (uid == null) {
        hasActiveSegment.value = false;
        activeSegments.clear();
        return;
      }

      final url = ApiConfig.getUserActiveSegment(uid);
      final response = await _apiClient.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['data'] != null && data['data'] is List) {
          activeSegments.value = List<Map<String, dynamic>>.from(data['data']);
          hasActiveSegment.value = activeSegments.isNotEmpty;
        } else {
          activeSegments.clear();
          hasActiveSegment.value = false;
        }
      } else {
        activeSegments.clear();
        hasActiveSegment.value = false;
      }
    } catch (e) {
      activeSegments.clear();
      hasActiveSegment.value = false;
    } finally {
      isLoadingSegment.value = false;
    }
  }

  Future<void> fetchPlans({String? category}) async {
    try {
      isLoading.value = true;
      error.value = null;

      // Reset selected plan when changing category to avoid stale ID
      selectedPlanId.value = null;

      final url = ApiConfig.listSegments; // No more category filter here
      final response = await _apiClient.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> plansData = data['data']['data'] ?? [];
        availablePlans.value = plansData
            .map((json) => SegmentPlan.fromJson(json))
            .toList();

        // Auto-select first or popular plan
        if (availablePlans.isNotEmpty) {
          final popularPlan = availablePlans.firstWhereOrNull(
            (p) => p.isPopular,
          );
          selectedPlanId.value = popularPlan?.id ?? availablePlans.first.id;
        }
      } else {
        throw Exception('Failed to load plans');
      }
    } catch (e) {
      final apiError = ApiErrorHandler.handleError(e);
      error.value = apiError.message;
      SnackbarService.showError('Failed to load plans: ${apiError.message}');
    } finally {
      isLoading.value = false;
    }
  }

  void selectPlan(String planId) {
    selectedPlanId.value = planId;
  }

  SegmentPlan? get selectedPlan => availablePlans.firstWhereOrNull(
    (plan) => plan.id == selectedPlanId.value,
  );

  bool isPlanSelected(String planId) => selectedPlanId.value == planId;

  Future<void> retry() async => fetchPlans();

  void filterBySegment(String segment, {String? segmentId}) {
    selectedSegment.value = segment;
    if (segmentId != null) {
      selectedSegmentId.value = segmentId;
    }
    // No more fetchPlans here, plans are universal
  }

  Future<void> refreshActiveSegment() async {
    await fetchActiveSegment();
  }

  Future<void> requestHniPlan({
    required String categoryId,
    required String planId,
  }) async {
    try {
      isLoading.value = true;
      final uid = await userId;
      if (uid == null) throw Exception('User not logged in');

      final response = await _apiClient.post(
        ApiConfig.requestHniPlan,
        data: {'userId': uid, 'segmentId': categoryId, 'segmentPlanId': planId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final message =
            response.data['message'] ??
            'HNI Custom Plan requested successfully. Our team will contact you shortly.';
        SnackbarService.showSuccess(message);
        Get.back(); // Go back to previous screen
      } else {
        throw Exception('Failed to submit request');
      }
    } catch (e) {
      final error = ApiErrorHandler.handleError(e);
      SnackbarService.showError(error.message);
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> purchaseSegment({
    required String categoryId,
    required String planId,
    String? paymentMode,
    bool isPartial = false,
  }) async {
    try {
      isLoading.value = true;
      final uid = await userId;
      if (uid == null) throw Exception('User not logged in');

      final response = await _apiClient.post(
        ApiConfig.acquisitionPlanOrder,
        data: {
          'planId': planId,
          'segmentId': categoryId, // Now required as plans are universal
          if (paymentMode != null) 'paymentMode': paymentMode,
          'isPartial': isPartial,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];

        return {
          'segmentsPayment': {
            '_id': data['paymentIntentId'],
            'razorpayOrderId': data['orderId'],
            'amount': data['amount'],
            'message': data['message'],
          },
        };
      }
      throw Exception('Server returned status code: ${response.statusCode}');
    } catch (e) {
      final error = ApiErrorHandler.handleError(e);
      SnackbarService.showError(error.message);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> verifySegmentPayment({
    required String segmentId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      isLoading.value = true;
      final response = await _apiClient.post(
        ApiConfig.acquisitionVerifyPayment,
        data: {
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final success = data['data']?['success'] ?? data['success'] ?? false;

        if (success) {
          SnackbarService.showSuccess('Payment verified successfully!');
          await fetchActiveSegment();
          return true;
        }
      }
      throw Exception('Payment verification failed');
    } catch (e) {
      final error = ApiErrorHandler.handleError(e);
      SnackbarService.showError(error.message);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> uploadPaymentProof({
    required String paymentId,
    required List<File> files,
    double? amountPaid,
    String? utrNumber,
  }) async {
    try {
      isLoading.value = true;

      List<dio.MultipartFile> multipartFiles = [];
      for (var file in files) {
        String fileName = file.path.split('/').last;
        multipartFiles.add(
          await dio.MultipartFile.fromFile(file.path, filename: fileName),
        );
      }

      dio.FormData formData = dio.FormData.fromMap({
        'paymentIntentId': paymentId,
        'file': multipartFiles,
        if (amountPaid != null) 'amountPaid': amountPaid,
        if (utrNumber != null) 'utrNumber': utrNumber,
      });

      final response = await _apiClient.post(
        ApiConfig.acquisitionUploadProof,
        data: formData,
      );

      return response.statusCode == 200;
    } catch (e) {
      final error = ApiErrorHandler.handleError(e);
      SnackbarService.showError(error.message);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
