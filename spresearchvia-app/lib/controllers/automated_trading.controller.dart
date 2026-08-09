import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../core/config/app.config.dart';
import '../services/secure_storage.service.dart';
import '../services/snackbar.service.dart';
import 'segment_plan.controller.dart';

class AutomatedTradingController extends GetxController {
  final SecureStorageService _storage = SecureStorageService();
  late final dio.Dio _dioClient;
  Timer? _statusPollTimer;

  // Connection & Consent States
  final isInitializing = false.obs;
  final consentsStatus = 'NOT_GRANTED'.obs; // ACTIVE, REVOKED, NOT_GRANTED
  final consentsDate = ''.obs;
  
  final linkedBrokers = <dynamic>[].obs;
  final isBrokerLoading = false.obs;

  // Live Portfolio & Books States
  final livePositions = <dynamic>[].obs;
  final liveHoldings = <dynamic>[].obs;
  final liveOrders = <dynamic>[].obs;
  final liveTrades = <dynamic>[].obs;
  final isLivePortfolioLoading = false.obs;

  // Segment Settings
  final userSegments = <dynamic>[].obs;
  final masterSegments = <dynamic>[].obs;
  final isSegmentsLoading = false.obs;
  
  // Trade Summary & History
  final pnlSummary = Rxn<Map<String, dynamic>>();
  final tradeHistory = <dynamic>[].obs;
  final isTradesLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _dioClient = dio.Dio(
      dio.BaseOptions(
        baseUrl: AppConfig.automatedApiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _setupInterceptors();
    refreshData();
    _startStatusPolling();
  }

  @override
  void onClose() {
    _statusPollTimer?.cancel();
    super.onClose();
  }

  void _startStatusPolling() {
    _statusPollTimer?.cancel();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (linkedBrokers.isNotEmpty) {
        fetchBrokerStatus();
      }
    });
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
        onError: (error, handler) {
          debugPrint('Automated API Error: ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  Future<void> refreshData() async {
    isInitializing.value = true;
    try {
      if (!Get.isRegistered<SegmentPlanController>()) {
        Get.put(SegmentPlanController());
      }
      await Future.wait([
        fetchConsentStatus(),
        fetchBrokerStatus(),
        fetchTradeSummary(),
        fetchTradeHistory(),
        fetchSegments(),
        Get.find<SegmentPlanController>().fetchActiveSegment(force: true),
      ]);
      await fetchLivePortfolioAndBooks();
    } catch (e) {
      debugPrint('Error refreshing automated trading data: $e');
    } finally {
      isInitializing.value = false;
    }
  }

  // --- Consents Flow ---
  Future<void> fetchConsentStatus() async {
    try {
      final response = await _dioClient.get('/consents/status');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['status'] != null) {
          consentsStatus.value = data['status'];
        } else {
          consentsStatus.value = (data['active'] == true) ? 'ACTIVE' : 'NOT_GRANTED';
        }
        consentsDate.value = data['consentDate'] ?? '';
      } else {
        consentsStatus.value = 'NOT_GRANTED';
      }
    } catch (e) {
      consentsStatus.value = 'NOT_GRANTED';
    }
  }

  // --- Segments / Lot Allocations Flow ---
  Future<void> fetchSegments() async {
    isSegmentsLoading.value = true;
    try {
      final responses = await Future.wait([
        _dioClient.get('/segments'),
        _dioClient.get('/segments/active'),
      ]);
      if (responses[0].statusCode == 200 && responses[0].data is List) {
        masterSegments.assignAll(responses[0].data);
      }
      if (responses[1].statusCode == 200 && responses[1].data is List) {
        userSegments.assignAll(responses[1].data);
      }
    } catch (e) {
      debugPrint('Failed fetching segments data: $e');
    } finally {
      isSegmentsLoading.value = false;
    }
  }

  Future<bool> activateSegment({
    required String segmentId,
    required double capital,
    required double backupCapital,
    required int baseLot,
    required int maxMultiplier,
    required double dailyLossLimit,
  }) async {
    try {
      final response = await _dioClient.post('/segments/activate', data: {
        'segmentId': segmentId,
        'capital': capital,
        'backupCapital': backupCapital,
        'baseLot': baseLot,
        'maxMultiplier': maxMultiplier,
        'dailyLossLimit': dailyLossLimit,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        SnackbarService.showSuccess('Segment configured and activated successfully.');
        await fetchSegments();
        return true;
      }
      return false;
    } catch (e) {
      SnackbarService.showError('Failed to configure segment.');
      return false;
    }
  }

  Future<bool> pauseSegment(String segmentId) async {
    try {
      final response = await _dioClient.post('/segments/pause', data: {
        'segmentId': segmentId,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        SnackbarService.showSuccess('Trading segment paused.');
        await fetchSegments();
        return true;
      }
      return false;
    } catch (e) {
      SnackbarService.showError('Failed to pause segment.');
      return false;
    }
  }

  Future<bool> grantConsent(String brokerId) async {
    try {
      final response = await _dioClient.post('/consents', data: {'brokerId': brokerId});
      if (response.statusCode == 200) {
        consentsStatus.value = response.data['status'] ?? 'ACTIVE';
        consentsDate.value = response.data['consentDate'] ?? '';
        SnackbarService.showSuccess('Daily trading consent granted successfully.');
        return true;
      }
      return false;
    } catch (e) {
      SnackbarService.showError('Failed to grant consent. Please try again.');
      return false;
    }
  }

  Future<bool> revokeConsent() async {
    try {
      final response = await _dioClient.delete('/consents/today');
      if (response.statusCode == 200) {
        consentsStatus.value = 'REVOKED';
        SnackbarService.showSuccess('Daily trading consent revoked.');
        return true;
      }
      return false;
    } catch (e) {
      SnackbarService.showError('Failed to revoke consent.');
      return false;
    }
  }

  // --- Broker Status & Auth ---
  Future<void> fetchBrokerStatus() async {
    isBrokerLoading.value = true;
    try {
      final response = await _dioClient.get('/brokers/status');
      if (response.statusCode == 200 && response.data is List) {
        linkedBrokers.assignAll(response.data);
      }
    } catch (e) {
      debugPrint('Failed fetching broker status: $e');
    } finally {
      isBrokerLoading.value = false;
    }
  }

  Future<String?> getAuthUrl(String brokerCode) async {
    try {
      final response = await _dioClient.get('/brokers/$brokerCode/auth-url');
      if (response.statusCode == 200 && response.data != null) {
        return response.data['authUrl'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get auth URL: $e');
      SnackbarService.showError('Failed to connect to broker portal.');
      return null;
    }
  }

  Future<bool> linkBroker(String brokerCode, String clientId, {String? apiKey, String? vendorCode}) async {
    try {
      final response = await _dioClient.post('/brokers/link', data: {
        'brokerCode': brokerCode,
        'brokerClientId': clientId,
        if (apiKey != null) 'apiKey': apiKey,
        if (vendorCode != null) 'vendorCode': vendorCode,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchBrokerStatus();
        SnackbarService.showSuccess('Broker details linked successfully.');
        return true;
      }
      return false;
    } catch (e) {
      SnackbarService.showError('Failed to link broker account.');
      return false;
    }
  }

  Future<bool> authorizeBroker(String brokerCode, String mpin, String totpKey) async {
    try {
      final response = await _dioClient.post('/brokers/authorize', data: {
        'brokerCode': brokerCode,
        'mpin': mpin,
        'totpKey': totpKey,
      });
      if (response.statusCode == 200) {
        await fetchBrokerStatus();
        await fetchLivePortfolioAndBooks();
        SnackbarService.showSuccess('Broker authorized for today\'s session.');
        return true;
      }
      return false;
    } catch (e) {
      SnackbarService.showError('Broker authorization failed. Please check credentials/TOTP.');
      return false;
    }
  }

  // --- Trades & PNL ---
  Future<void> fetchTradeSummary() async {
    try {
      final response = await _dioClient.get('/trades/summary');
      if (response.statusCode == 200) {
        pnlSummary.value = response.data;
      }
    } catch (e) {
      debugPrint('Failed fetching trades summary: $e');
    }
  }

  Future<void> fetchTradeHistory() async {
    isTradesLoading.value = true;
    try {
      final response = await _dioClient.get('/trades/history', queryParameters: {'limit': 20});
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          tradeHistory.assignAll(data);
        } else if (data['trades'] is List) {
          tradeHistory.assignAll(data['trades']);
        }
      }
    } catch (e) {
      debugPrint('Failed fetching trade history: $e');
    } finally {
      isTradesLoading.value = false;
    }
  }

  Future<bool> unlinkBroker(String brokerCode) async {
    try {
      final response = await _dioClient.delete('/brokers/unlink', data: {
        'brokerCode': brokerCode,
      });
      if (response.statusCode == 200) {
        await fetchBrokerStatus();
        consentsStatus.value = 'NOT_GRANTED';
        consentsDate.value = '';
        SnackbarService.showSuccess('Broker disconnected successfully.');
        return true;
      }
      return false;
    } catch (e) {
      SnackbarService.showError('Failed to disconnect broker account.');
      return false;
    }
  }

  DateTime? _lastLiveFetchTime;

  Future<void> fetchLivePortfolioAndBooks({bool force = false}) async {
    // Only fetch if session is active
    final hasActiveSession = linkedBrokers.any((b) => b['isSessionActive'] == true);
    if (!hasActiveSession) {
      livePositions.clear();
      liveHoldings.clear();
      liveOrders.clear();
      liveTrades.clear();
      return;
    }

    // Throttle guard: avoid duplicate calls within 2 seconds unless forced
    if (!force && _lastLiveFetchTime != null) {
      if (DateTime.now().difference(_lastLiveFetchTime!) < const Duration(seconds: 2)) {
        return;
      }
    }
    _lastLiveFetchTime = DateTime.now();

    isLivePortfolioLoading.value = true;
    try {
      final results = await Future.wait([
        _dioClient.get('/brokers/live/positions'),
        _dioClient.get('/brokers/live/holdings'),
        _dioClient.get('/brokers/live/orders'),
        _dioClient.get('/brokers/live/trades'),
      ]);

      if (results[0].statusCode == 200 && results[0].data is List) {
        livePositions.assignAll(results[0].data);
      }
      if (results[1].statusCode == 200 && results[1].data is List) {
        liveHoldings.assignAll(results[1].data);
      }
      if (results[2].statusCode == 200 && results[2].data is List) {
        liveOrders.assignAll(results[2].data);
      }
      if (results[3].statusCode == 200 && results[3].data is List) {
        liveTrades.assignAll(results[3].data);
      }
    } catch (e) {
      debugPrint('Failed to fetch live portfolio/books: $e');
    } finally {
      isLivePortfolioLoading.value = false;
    }
  }
}
