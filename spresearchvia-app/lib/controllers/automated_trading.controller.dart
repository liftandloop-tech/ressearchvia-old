import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart' as dio;
import '../core/config/app.config.dart';
import '../services/secure_storage.service.dart';
import '../services/snackbar.service.dart';
import 'segment_plan.controller.dart';

class AutomatedTradingController extends GetxController {
  final SecureStorageService _storage = SecureStorageService();
  final GetStorage _box = GetStorage();
  late final dio.Dio _dioClient;
  Timer? _statusPollTimer;

  // Master Service Activation Agreement
  final hasSignedAgreement = false.obs;
  final isSigningAgreement = false.obs;

  // Static IP Proxy States
  final proxyInfo = Rxn<Map<String, dynamic>>();
  final isProxyLoading = false.obs;

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

  // Trading Strategy States
  final selectedStrategy = 'FIXED_1X'.obs; // FIXED_1X or LOSS_MULTIPLIER_2X
  final isAgreementAccepted = true.obs;
  final currentStrategyData = Rxn<Map<String, dynamic>>();
  final strategyHistory = <dynamic>[].obs;
  final isStrategyLoading = false.obs;

  // Computed Service Status Helpers
  bool get hasActiveProxy => proxyInfo.value?['hasProxy'] == true && proxyInfo.value?['status'] != 'expired';
  String get staticIpAddress => proxyInfo.value?['ip']?.toString() ?? '';
  bool get isBrokerConfigured => linkedBrokers.isNotEmpty;
  bool get isBrokerSessionActive => isBrokerConfigured && linkedBrokers.first['isSessionActive'] == true;
  bool get isLotConfigured => userSegments.isNotEmpty && (userSegments.first['baseLot'] ?? 0) > 0;
  bool get isStrategyConfigured => currentStrategyData.value?['strategy'] != null;
  bool get isDailyConsentActive => consentsStatus.value == 'ACTIVE';

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
        checkAgreementStatus(),
        fetchProxyInfo(),
        fetchConsentStatus(),
        fetchBrokerStatus(),
        fetchUserStrategy(),
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

  // --- Master Service Agreement Flow ---
  Future<void> checkAgreementStatus() async {
    try {
      final userId = await _storage.getUserId() ?? 'user';
      final signed = _box.read('is_automated_agreement_signed_$userId') == true;
      hasSignedAgreement.value = signed || (consentsStatus.value == 'ACTIVE') || linkedBrokers.isNotEmpty;
    } catch (e) {
      hasSignedAgreement.value = (consentsStatus.value == 'ACTIVE') || linkedBrokers.isNotEmpty;
    }
  }

  Future<bool> signServiceAgreement() async {
    isSigningAgreement.value = true;
    try {
      final userId = await _storage.getUserId() ?? 'user';
      await _box.write('is_automated_agreement_signed_$userId', true);
      hasSignedAgreement.value = true;
      SnackbarService.showSuccess('Automated Trading Service Agreement signed.');
      return true;
    } catch (e) {
      SnackbarService.showError('Failed to record signature. Please try again.');
      return false;
    } finally {
      isSigningAgreement.value = false;
    }
  }

  // --- Proxy / Static IP Flow ---
  Future<void> fetchProxyInfo() async {
    isProxyLoading.value = true;
    try {
      final token = await _storage.getAuthToken();
      final llDio = dio.Dio(dio.BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer ${token.replaceFirst("Bearer ", "")}',
        },
      ));
      final response = await llDio.get('/user/proxy/info');
      if (response.data != null && response.data['status'] == 'success') {
        proxyInfo.value = response.data['data'];
        if (hasActiveProxy) {
          hasSignedAgreement.value = true;
        }
      }
    } catch (e) {
      debugPrint('Failed fetching proxy info: $e');
    } finally {
      isProxyLoading.value = false;
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

  Future<bool> grantConsent(String brokerId, {String? strategy}) async {
    try {
      final chosenStrategy = strategy ?? selectedStrategy.value;
      final response = await _dioClient.post('/consents', data: {
        'brokerId': brokerId,
        'strategy': chosenStrategy,
        'baseMultiplier': 1,
        'consentAccepted': true,
        'agreementVersion': 'v1.0',
      });
      if (response.statusCode == 200) {
        consentsStatus.value = response.data['status'] ?? 'ACTIVE';
        consentsDate.value = response.data['consentDate'] ?? '';
        await fetchUserStrategy();
        SnackbarService.showSuccess('Daily trading consent granted with $chosenStrategy.');
        return true;
      }
      return false;
    } catch (e) {
      SnackbarService.showError('Failed to grant consent. Please try again.');
      return false;
    }
  }

  Future<void> fetchUserStrategy() async {
    isStrategyLoading.value = true;
    try {
      final response = await _dioClient.get('/consents/strategy');
      if (response.statusCode == 200 && response.data != null) {
        currentStrategyData.value = response.data;
        final strat = response.data['strategy'];
        if (strat != null && strat['strategyType'] != null) {
          selectedStrategy.value = strat['strategyType'];
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch user strategy: $e');
    } finally {
      isStrategyLoading.value = false;
    }
  }

  Future<bool> changeStrategy(String newStrategy) async {
    try {
      final response = await _dioClient.post('/consents/strategy/change', data: {
        'strategy': newStrategy,
        'agreementVersion': 'v1.0',
      });
      if (response.statusCode == 200) {
        selectedStrategy.value = newStrategy;
        consentsStatus.value = 'NOT_GRANTED';
        await fetchUserStrategy();
        SnackbarService.showSuccess('Strategy updated to $newStrategy. Multiplier reset to 1x. Please grant daily consent.');
        return true;
      }
      return false;
    } catch (e) {
      SnackbarService.showError('Failed to change strategy.');
      return false;
    }
  }

  Future<void> fetchStrategyHistory() async {
    try {
      final response = await _dioClient.get('/consents/strategy/history');
      if (response.statusCode == 200 && response.data != null) {
        strategyHistory.assignAll(response.data['history'] ?? []);
      }
    } catch (e) {
      debugPrint('Failed to fetch strategy history: $e');
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

  Future<bool> linkBroker(
    String brokerCode,
    String clientId, {
    String? apiKey,
    String? apiSecret,
    String? vendorCode,
  }) async {
    try {
      final response = await _dioClient.post('/brokers/link', data: {
        'brokerCode': brokerCode,
        'brokerClientId': clientId,
        if (apiKey != null) 'apiKey': apiKey,
        if (apiSecret != null) 'apiSecret': apiSecret,
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
      final response = await _dioClient.delete('/brokers/$brokerCode/unlink');
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
