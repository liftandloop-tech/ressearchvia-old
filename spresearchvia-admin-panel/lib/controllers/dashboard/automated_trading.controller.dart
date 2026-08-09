import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app.config.dart';

class AdminAutomatedTradingController extends GetxController {
  late final GetConnect _client;

  // Global SRE States
  var isTradingActive = true.obs;
  var isOperationLoading = false.obs;
  var reconciliationRuns = <dynamic>[].obs;
  var reconciliationIssues = <dynamic>[].obs;
  var dlqMetrics = <String, dynamic>{}.obs;
  var segments = <dynamic>[].obs;
  var isPublishing = false.obs;

  @override
  void onInit() {
    super.onInit();
    _client = GetConnect();
    _client.httpClient.baseUrl = AppConfig.automatedApiBaseUrl;
    _client.httpClient.timeout = const Duration(seconds: 30);
    _initializeModifiers();
    refreshAdminData();
  }

  void _initializeModifiers() {
    _client.httpClient.addRequestModifier<dynamic>((request) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        debugPrint('Error attaching auth token to admin: $e');
      }
      return request;
    });
  }

  Future<void> refreshAdminData() async {
    isOperationLoading.value = true;
    try {
      await Future.wait([
        fetchReconciliationRuns(),
        fetchReconciliationIssues(),
        fetchDlqMetrics(),
        fetchSegments(),
      ]);
    } catch (e) {
      debugPrint('Error fetching SRE admin data: $e');
    } finally {
      isOperationLoading.value = false;
    }
  }

  Future<void> fetchReconciliationRuns() async {
    try {
      final response = await _client.get('/ops/reconciliation/runs');
      if (response.statusCode == 200 && response.body is List) {
        reconciliationRuns.assignAll(response.body);
      }
    } catch (e) {
      debugPrint('Failed to fetch recon runs: $e');
    }
  }

  Future<void> fetchReconciliationIssues() async {
    try {
      final response = await _client.get('/ops/reconciliation/issues');
      if (response.statusCode == 200 && response.body is List) {
        reconciliationIssues.assignAll(response.body);
      }
    } catch (e) {
      debugPrint('Failed to fetch recon issues: $e');
    }
  }

  Future<void> fetchDlqMetrics() async {
    try {
      final response = await _client.get('/ops/dlq');
      if (response.statusCode == 200 && response.body != null) {
        dlqMetrics.value = response.body;
      }
    } catch (e) {
      debugPrint('Failed to fetch DLQ metrics: $e');
    }
  }

  Future<bool> triggerReconciliation() async {
    isOperationLoading.value = true;
    try {
      final response = await _client.post('/ops/reconciliation/run', {});
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Manual reconciliation run queued.');
        await fetchReconciliationRuns();
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar('Error', 'Failed to trigger reconciliation.');
      return false;
    } finally {
      isOperationLoading.value = false;
    }
  }

  Future<bool> toggleGlobalTrading(bool stop, String reason) async {
    isOperationLoading.value = true;
    try {
      final response = stop 
        ? await _client.post('/ops/trading/stop?permanent=true&reason=$reason', {})
        : await _client.post('/ops/trading/start', {});

      if (response.statusCode == 200) {
        isTradingActive.value = !stop;
        Get.snackbar('Success', stop ? 'Trading STOPPED globally.' : 'Trading STARTED globally.');
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar('Error', 'Failed to toggle global trading state.');
      return false;
    } finally {
      isOperationLoading.value = false;
    }
  }

  Future<bool> resolveIssue(String issueId) async {
    try {
      final response = await _client.post('/ops/reconciliation/$issueId/resolve', {});
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Reconciliation issue marked as resolved.');
        await fetchReconciliationIssues();
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar('Error', 'Failed to resolve reconciliation issue.');
      return false;
    }
  }

  Future<bool> escalateIssue(String issueId) async {
    try {
      final response = await _client.post('/ops/reconciliation/$issueId/escalate', {});
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Reconciliation issue escalated.');
        await fetchReconciliationIssues();
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar('Error', 'Failed to escalate issue.');
      return false;
    }
  }

  Future<void> fetchSegments() async {
    try {
      final response = await _client.get('/segments');
      if (response.statusCode == 200 && response.body is List) {
        segments.assignAll(response.body);
      }
    } catch (e) {
      debugPrint('Failed to fetch segments: $e');
    }
  }

  Future<bool> publishSignal({
    required String segmentId,
    required String symbol,
    required String exchange,
    required String segment,
    required String side,
    required String orderType,
    required double entryPrice,
    required double stopLoss,
    required double targetPrice,
  }) async {
    isPublishing.value = true;
    try {
      final response = await _client.post('/signals/publish', {
        'segmentId': segmentId,
        'symbol': symbol,
        'exchange': exchange,
        'segment': segment,
        'side': side,
        'orderType': orderType,
        'entryPrice': entryPrice,
        'stopLoss': stopLoss,
        'targetPrice': targetPrice,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar('Success', 'Trading signal published successfully.');
        return true;
      }
      final msg = response.body?['message'] ?? 'Failed to publish signal.';
      Get.snackbar('Error', msg.toString());
      return false;
    } catch (e) {
      Get.snackbar('Error', 'Failed to publish signal: $e');
      return false;
    } finally {
      isPublishing.value = false;
    }
  }

  Future<List<dynamic>> searchInstruments(String query, String exchange) async {
    try {
      final response = await _client.get('/instruments', query: {
        'search': query,
        'exchange': exchange,
      });
      if (response.statusCode == 200 && response.body is List) {
        return response.body;
      }
    } catch (e) {
      debugPrint('Error searching instruments: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> fetchLtp({
    required String symbol,
    required String exchange,
    String? token,
  }) async {
    try {
      final queryParams = {
        'symbol': symbol,
        'exchange': exchange,
      };
      if (token != null && token.isNotEmpty) {
        queryParams['token'] = token;
      }
      final response = await _client.get('/instruments/ltp', query: queryParams);
      if (response.statusCode == 200 && response.body != null) {
        return Map<String, dynamic>.from(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching LTP: $e');
    }
    return null;
  }

  // User Live Broker Inspection
  var searchUserQuery = ''.obs;
  var inspectedUserBrokerData = Rxn<Map<String, dynamic>>();
  var isUserBrokerLoading = false.obs;

  Future<void> inspectUserBrokerData(String identifier) async {
    if (identifier.trim().isEmpty) return;
    isUserBrokerLoading.value = true;
    try {
      final response = await _client.get('/ops/users/${identifier.trim()}/live-broker-data');
      if (response.statusCode == 200 && response.body != null) {
        inspectedUserBrokerData.value = Map<String, dynamic>.from(response.body);
      } else {
        final msg = response.body?['message'] ?? 'User broker connection not found';
        Get.snackbar('Error', msg.toString());
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch user broker data: $e');
    } finally {
      isUserBrokerLoading.value = false;
    }
  }
}
