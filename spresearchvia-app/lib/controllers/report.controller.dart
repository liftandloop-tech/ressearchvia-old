import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../core/config/api.config.dart';
import '../core/models/research_report.dart';
import '../services/api_client.service.dart';
import '../services/api_exception.service.dart';
import '../services/snackbar.service.dart';
import '../services/secure_storage.service.dart';

class ReportController extends GetxController {
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _secureStorage = SecureStorageService();

  // Reports State
  final isReportsLoading = false.obs;
  final isReportsLoadingMore = false.obs;
  final reports = <ResearchReport>[].obs;
  final reportsPage = 1.obs;
  final reportsHasMore = true.obs;

  // Trading Calls State
  final isTradingCallsLoading = false.obs;
  final isTradingCallsLoadingMore = false.obs;
  final tradingCalls = <ResearchReport>[].obs;
  final tradingCallsPage = 1.obs;
  final tradingCallsHasMore = true.obs;

  // Trading Accuracy State (Target Achieved, Partially Booked, Stoploss Hit)
  final tradingAccuracyStats = Rx<TradingAccuracyStats>(const TradingAccuracyStats());
  final thisMonthAccuracyStats = Rx<TradingAccuracyStats>(const TradingAccuracyStats());
  final selectedOutcomeFilter = Rxn<TradingCallOutcome>();

  String? _getOutcomeQueryParam(TradingCallOutcome? outcome) {
    if (outcome == null) return null;
    switch (outcome) {
      case TradingCallOutcome.targetAchieved:
        return 'target_achieved';
      case TradingCallOutcome.partiallyBooked:
        return 'partial_profit';
      case TradingCallOutcome.stoplossHit:
        return 'stoploss_hit';
      case TradingCallOutcome.active:
        return 'active';
    }
  }

  List<ResearchReport> get filteredTradingCalls => tradingCalls;

  TradingAccuracyStats get effectiveAccuracy =>
      tradingAccuracyStats.value.totalCalls > 0
          ? tradingAccuracyStats.value
          : TradingAccuracyStats.fromReports(tradingCalls);

  TradingAccuracyStats get effectiveDashboardAccuracy {
    if (thisMonthAccuracyStats.value.totalCalls > 0) {
      return thisMonthAccuracyStats.value;
    }
    return effectiveAccuracy;
  }

  // Plan Subscription Status
  final hasActiveSubscription = true.obs;

  final selectedTabIndex = 0.obs;

  // Filters
  final searchQuery = ''.obs;
  final startDate = RxnString();
  final endDate = RxnString();

  static const int _firstPageSize = 20;
  static const int _pageSize = 10;
  
  DateTime? _lastRefreshTime;
  static const Duration _refreshThreshold = Duration(seconds: 3);

  // This Month Statistics (1st of every month to current day)
  final isMonthlyCountsLoading = false.obs;
  final thisMonthTradingCallsCount = 0.obs;
  final thisMonthReportsCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchThisMonthCounts();
    ever(selectedOutcomeFilter, (_) {
      fetchTradingCalls(refresh: true);
    });
  }

  Future<void> fetchThisMonthCounts() async {
    try {
      isMonthlyCountsLoading.value = true;
      final userId = await _secureStorage.getUserId();
      if (userId == null || userId.isEmpty) return;

      final now = DateTime.now();
      // From 1st of every month at 00:00:00 to current day of the month (23:59:59.999)
      final startOfMonth = DateTime(now.year, now.month, 1, 0, 0, 0);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

      final startIso = startOfMonth.toUtc().toIso8601String();
      final endIso = endOfDay.toUtc().toIso8601String();

      final callsFuture = _apiClient.get(
        ApiConfig.userReportList(
          userId,
          reportType: 'Trading calls',
          page: 1,
          pageSize: 1,
          startDate: startIso,
          endDate: endIso,
        ),
      );

      final reportsFuture = _apiClient.get(
        ApiConfig.userReportList(
          userId,
          reportType: 'Detailed Reports',
          page: 1,
          pageSize: 1,
          startDate: startIso,
          endDate: endIso,
        ),
      );

      final results = await Future.wait([callsFuture, reportsFuture]);
      final callsResponse = results[0];
      final reportsResponse = results[1];

      if (callsResponse.statusCode == 200) {
        final innerData = callsResponse.data?['data'];
        final count = innerData?['totalReports'] ?? 0;
        thisMonthTradingCallsCount.value =
            (count is int) ? count : int.tryParse(count.toString()) ?? 0;
        if (innerData != null && innerData['accuracyStats'] is Map) {
          thisMonthAccuracyStats.value = TradingAccuracyStats.fromJson(
            Map<String, dynamic>.from(innerData['accuracyStats']),
          );
        }
      }

      if (reportsResponse.statusCode == 200) {
        final innerData = reportsResponse.data?['data'];
        final count = innerData?['totalReports'] ?? 0;
        thisMonthReportsCount.value =
            (count is int) ? count : int.tryParse(count.toString()) ?? 0;
      }
    } catch (e) {
      debugPrint('ReportController: Error fetching this month counts: $e');
    } finally {
      isMonthlyCountsLoading.value = false;
    }
  }

  Future<void> refreshData({bool force = false}) async {
    final now = DateTime.now();
    if (!force && _lastRefreshTime != null && 
        now.difference(_lastRefreshTime!) < _refreshThreshold) {
      debugPrint('ReportController: Skipping refresh, data is fresh.');
      return;
    }
    
    _lastRefreshTime = now;
    await Future.wait([
      fetchTradingCalls(refresh: true),
      fetchReportList(refresh: true),
      fetchThisMonthCounts(),
    ]);
  }

  // --- Research Reports Logic ---

  Future<void> fetchReportList({bool refresh = false}) async {
    if (!refresh && (isReportsLoading.value || isReportsLoadingMore.value || !reportsHasMore.value)) {
      return;
    }

    final targetPage = refresh ? 1 : reportsPage.value;

    try {
      if (targetPage == 1) {
        isReportsLoading.value = true;
      } else {
        isReportsLoadingMore.value = true;
      }

      final userId = await _secureStorage.getUserId();
      if (userId == null || userId.isEmpty) return;

      final response = await _apiClient.get(
        ApiConfig.userReportList(
          userId,
          reportType: 'Detailed Reports',
          page: targetPage,
          pageSize: targetPage == 1 ? _firstPageSize : _pageSize,
          search: searchQuery.value,
          startDate: startDate.value,
          endDate: endDate.value,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final innerData = data['data'];

        if (innerData is Map && innerData.containsKey('hasActiveSubscription')) {
          hasActiveSubscription.value = innerData['hasActiveSubscription'] == true;
        }

        final reportList = innerData?['reports'] ?? 
                           innerData?['report'] ?? 
                           innerData?['reportData'] ?? 
                           [];

        if (reportList is List) {
          final newReports = reportList
              .map<ResearchReport>((json) => ResearchReport.fromJson(json))
              .toList();

          final expectedSize = targetPage == 1 ? _firstPageSize : _pageSize;

          if (innerData is Map && innerData.containsKey('hasMore')) {
            reportsHasMore.value = innerData['hasMore'] == true;
          } else {
            reportsHasMore.value = newReports.length >= expectedSize;
          }

          if (refresh) {
            reports.assignAll(newReports);
            reportsPage.value = 2;
          } else {
            final existingIds = reports.map((r) => r.id).toSet();
            final uniqueReports = newReports.where((r) => !existingIds.contains(r.id)).toList();
            reports.addAll(uniqueReports);
            if (newReports.isNotEmpty) {
              reportsPage.value++;
            }
          }
        }
      }
    } catch (e) {
      final error = ApiErrorHandler.handleError(e);
      if (error.data is Map && error.data['errorCode'] == 'NO_ACTIVE_PLAN') {
        hasActiveSubscription.value = false;
        reports.clear();
      } else {
        SnackbarService.showError(error.message);
      }
    } finally {
      isReportsLoading.value = false;
      isReportsLoadingMore.value = false;
    }
  }

  Future<void> loadMoreReports() async {
    if (!isReportsLoading.value &&
        !isReportsLoadingMore.value &&
        reportsHasMore.value) {
      await fetchReportList();
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    fetchTradingCalls(refresh: true);
    fetchReportList(refresh: true);
  }

  void onDateFilterChanged(String? start, String? end) {
    startDate.value = start;
    endDate.value = end;
    fetchTradingCalls(refresh: true);
    fetchReportList(refresh: true);
  }

  // --- Trading Calls Logic ---

  Future<void> fetchTradingCalls({bool refresh = false}) async {
    if (!refresh && (isTradingCallsLoading.value || isTradingCallsLoadingMore.value || !tradingCallsHasMore.value)) {
      return;
    }

    final targetPage = refresh ? 1 : tradingCallsPage.value;

    try {
      final userId = await _secureStorage.getUserId();
      if (userId == null || userId.isEmpty) return;

      if (targetPage == 1) {
        isTradingCallsLoading.value = true;
      } else {
        isTradingCallsLoadingMore.value = true;
      }

      final response = await _apiClient.get(
        ApiConfig.userReportList(
          userId,
          reportType: 'Trading calls',
          page: targetPage,
          pageSize: targetPage == 1 ? _firstPageSize : _pageSize,
          search: searchQuery.value,
          startDate: startDate.value,
          endDate: endDate.value,
          outcome: _getOutcomeQueryParam(selectedOutcomeFilter.value),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final innerData = data['data'];

        if (innerData is Map && innerData.containsKey('hasActiveSubscription')) {
          hasActiveSubscription.value = innerData['hasActiveSubscription'] == true;
        }
        
        final reportList = innerData?['reports'] ?? 
                           innerData?['report'] ?? 
                           innerData?['reportData'] ?? 
                           [];

        if (reportList is List) {
          final newReports = reportList
              .map<ResearchReport>((json) => ResearchReport.fromJson(json))
              .toList();

          final expectedSize = targetPage == 1 ? _firstPageSize : _pageSize;

          if (innerData is Map && innerData.containsKey('hasMore')) {
            tradingCallsHasMore.value = innerData['hasMore'] == true;
          } else {
            tradingCallsHasMore.value = newReports.length >= expectedSize;
          }

          if (refresh) {
            tradingCalls.assignAll(newReports);
            tradingCallsPage.value = 2;
          } else {
            final existingIds = tradingCalls.map((r) => r.id).toSet();
            final uniqueReports = newReports.where((r) => !existingIds.contains(r.id)).toList();
            tradingCalls.addAll(uniqueReports);
            if (newReports.isNotEmpty) {
              tradingCallsPage.value++;
            }
          }

          if (innerData != null && innerData['accuracyStats'] is Map) {
            tradingAccuracyStats.value = TradingAccuracyStats.fromJson(
              Map<String, dynamic>.from(innerData['accuracyStats']),
            );
          } else {
            tradingAccuracyStats.value = TradingAccuracyStats.fromReports(tradingCalls);
          }
        }
      }
    } catch (e) {
      final error = ApiErrorHandler.handleError(e);
      if (error.data is Map && error.data['errorCode'] == 'NO_ACTIVE_PLAN') {
        hasActiveSubscription.value = false;
        tradingCalls.clear();
      } else {
        SnackbarService.showError(error.message);
      }
    } finally {
      isTradingCallsLoading.value = false;
      isTradingCallsLoadingMore.value = false;
    }
  }

  Future<void> loadMoreTradingCalls() async {
    if (!isTradingCallsLoading.value &&
        !isTradingCallsLoadingMore.value &&
        tradingCallsHasMore.value) {
      await fetchTradingCalls();
    }
  }
}
