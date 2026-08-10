import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../../core/config/app.config.dart';
import '../../services/secure_storage.service.dart';
import '../../services/snackbar.service.dart';

class ProxyController extends GetxController {
  final SecureStorageService _storage = SecureStorageService();
  late final dio.Dio _dioClient;

  final isLoading = false.obs;
  final proxyData = Rxn<Map<String, dynamic>>();
  final pricingData = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    _dioClient = dio.Dio(
      dio.BaseOptions(
        baseUrl: AppConfig.apiBaseUrl, // Point to l-l-backend base URL
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
      final response = await _dioClient.get('/api/user/proxy/info');
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
      final response = await _dioClient.get('/api/user/proxy/pricing');
      if (response.data != null && response.data['status'] == 'success') {
        pricingData.value = response.data['brokers'];
      }
    } catch (e) {
      debugPrint('Error fetching pricing: $e');
    }
  }

  Future<void> issueProxy(int validityMonths) async {
    isLoading.value = true;
    try {
      final response = await _dioClient.post(
        '/api/user/proxy/issue',
        data: {'validity': validityMonths},
      );
      if (response.data != null && response.data['status'] == 'success') {
        SnackbarService.showSuccess(
          title: 'Success',
          message: 'Proxy IP issued successfully!',
        );
        fetchProxyInfo();
      } else {
        SnackbarService.showError(
          title: 'Error',
          message: response.data['remark'] ?? 'Failed to issue Proxy.',
        );
      }
    } catch (e) {
      SnackbarService.showError(
        title: 'Error',
        message: 'Something went wrong. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> renewProxy(int validityMonths) async {
    isLoading.value = true;
    try {
      final response = await _dioClient.post(
        '/api/user/proxy/renew',
        data: {'validity': validityMonths},
      );
      if (response.data != null && response.data['status'] == 'success') {
        SnackbarService.showSuccess(
          title: 'Success',
          message: 'Proxy IP renewed successfully!',
        );
        fetchProxyInfo();
      } else {
        SnackbarService.showError(
          title: 'Error',
          message: response.data['remark'] ?? 'Failed to renew Proxy.',
        );
      }
    } catch (e) {
      SnackbarService.showError(
        title: 'Error',
        message: 'Something went wrong. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }
}
