import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/services/user_details.service.dart';
import 'package:spresearch_web/services/user_payment.service.dart';
import 'package:spresearch_web/services/api.service.dart';
import 'package:intl/intl.dart';

class ActivityLogController extends GetxController {
  final UserDetailsService _userDetailsService = Get.find<UserDetailsService>();
  final UserPaymentService _paymentService = Get.find<UserPaymentService>();

  var currentPage = 1.obs;
  final int itemsPerPage = 10;
  var selectedType = 'All Types'.obs;
  var selectedTimeRange = 'All Time'.obs;
  var selectedSeverity = 'All Severity'.obs;
  var isLoading = false.obs;
  var allActivities = <Map<String, dynamic>>[].obs;
  String? _currentUserId;

  final List<String> activityTypes = [
    'All Types',
    'Account',
    'Payment',
    'Profile',
    'Session',
    'Manager',
    'Call',
  ];

  final List<String> severityLevels = [
    'All Severity',
    'INFO',
    'WARNING',
    'SECURITY',
    'CRITICAL',
  ];

  final List<String> timeRanges = [
    'All Time',
    'Today',
    'This Week',
    'This Month',
    'This Year',
  ];

  Future<void> fetchActivities(String userId) async {
    if (_currentUserId == userId &&
        (isLoading.value || allActivities.isNotEmpty))
      return;
    _currentUserId = userId;

    isLoading.value = true;
    allActivities.clear();
    try {
      // 1. User account entry (from profile API)
      final userResponse = await _userDetailsService.getUserDetails(userId);
      if (userResponse != null) {
        if (userResponse.createdAt.isNotEmpty) {
          allActivities.add(
            _makeEntry(
              dateStr: userResponse.createdAt,
              type: 'Account',
              icon: Icons.person_add,
              description: 'User account created',
              source: 'System',
              status: 'Completed',
              color: AppTheme.successGreen,
              severity: 'INFO',
            ),
          );
        }
        if (userResponse.updatedAt.isNotEmpty &&
            userResponse.updatedAt != userResponse.createdAt) {
          allActivities.add(
            _makeEntry(
              dateStr: userResponse.updatedAt,
              type: 'Profile',
              icon: Icons.edit,
              description: 'Profile updated',
              source: 'System',
              status: 'Updated',
              color: AppTheme.primaryBlue,
              severity: 'INFO',
            ),
          );
        }
      }

      // 2. Payments
      final paymentResponse = await _paymentService.getUserPaymentHistory(
        userId,
      );
      if (paymentResponse['status'] == 200) {
        final payments =
            paymentResponse['data']['segmentsPayment'] as List<dynamic>? ?? [];
        for (var payment in payments) {
          final amt = (payment['amount'] ?? 0) / 100;
          allActivities.add(
            _makeEntry(
              dateStr: payment['createdAt'],
              type: 'Payment',
              icon: Icons.payment,
              description: 'Payment of ₹$amt',
              source: 'Razorpay',
              status:
                  (payment['paymentStatus'] ?? 'Unknown')
                      .toString()
                      .capitalizeFirst ??
                  'Unknown',
              color: _getStatusColor(payment['paymentStatus']),
              severity: 'INFO',
            ),
          );
        }
      }

      // 3. Compliance logs from backend (login, session, admin actions, etc.)
      await _fetchComplianceLogs(userId);

      allActivities.sort((a, b) => b['rawDate'].compareTo(a['rawDate']));
    } catch (e) {
      debugPrint('Error fetching activities: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Pulls compliance logs from the backend activity-log API
  Future<void> _fetchComplianceLogs(String userId) async {
    try {
      final service = ApiService();
      final response = await service.get('/activity-log/user/$userId');

      if (response.status.hasError || response.body == null) return;
      final body = response.body;
      if (body['status'] != 200) return;

      final logs = body['data']['logs'] as List<dynamic>? ?? [];
      for (var log in logs) {
        final rawDate =
            DateTime.tryParse(
              log['eventTimestamp'] ?? log['createdAt'] ?? '',
            ) ??
            DateTime(2000);
        final eventType = log['eventType'] as String? ?? '';
        final description = log['description'] as String? ?? '';
        final ip = log['ipAddress'] as String? ?? 'N/A';
        final severity = log['severity'] as String? ?? 'INFO';
        final performedBy = log['performedBy'] as Map<String, dynamic>? ?? {};

        allActivities.add({
          'dateTime': _formatDatePrecise(rawDate),
          'rawDate': rawDate,
          'type': _mapEventTypeToCategory(eventType),
          'icon': _getEventIcon(eventType),
          'description': description,
          'source': ip,
          'status': _getEventStatus(eventType),
          'color': _getEventColor(eventType),
          'severity': severity,
          'severityColor': _getSeverityColor(severity),
          'performedBy': performedBy['name'] ?? '',
        });
      }
    } catch (e) {
      debugPrint('Error fetching compliance logs: $e');
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _makeEntry({
    required String? dateStr,
    required String type,
    required IconData icon,
    required String description,
    required String source,
    required String status,
    required Color color,
    required String severity,
  }) {
    final rawDate = dateStr != null
        ? (DateTime.tryParse(dateStr) ?? DateTime(2000))
        : DateTime(2000);
    return {
      'dateTime': _formatDatePrecise(rawDate),
      'rawDate': rawDate,
      'type': type,
      'icon': icon,
      'description': description,
      'source': source,
      'status': status,
      'color': color,
      'severity': severity,
      'severityColor': _getSeverityColor(severity),
      'performedBy': '',
    };
  }

  String _mapEventTypeToCategory(String eventType) {
    switch (eventType) {
      case 'USER_LOGIN':
      case 'NEW_DEVICE_LOGIN':
      case 'APP_SESSION_START':
      case 'USER_LOGOUT':
        return 'Session';
      case 'MANAGER_ASSIGNED':
      case 'MANAGER_REMOVED':
        return 'Manager';
      case 'ADMIN_PROFILE_EDIT':
      case 'PROFILE_UPDATED':
        return 'Profile';
      case 'KYC_STATUS_CHANGED':
      case 'ACCOUNT_CREATED':
      case 'ACCOUNT_SUSPENDED':
      case 'ACCOUNT_ACTIVATED':
        return 'Account';
      case 'CALL_ASSIGNED':
      case 'TRADING_CALL_OPENED':
        return 'Call';
      case 'PAYMENT_APPROVED':
      case 'PAYMENT_REJECTED':
      case 'SUBSCRIPTION_EXTENDED':
      case 'SUBSCRIPTION_REVOKED':
      case 'SUBSCRIPTION_SUSPENDED':
      case 'SUBSCRIPTION_ACTIVATED':
      case 'PLAN_CREATED':
      case 'PLAN_TOPUP':
        return 'Payment';
      default:
        return 'Account';
    }
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'USER_LOGIN':
        return Icons.login;
      case 'NEW_DEVICE_LOGIN':
        return Icons.phonelink_setup;
      case 'APP_SESSION_START':
        return Icons.phone_android;
      case 'USER_LOGOUT':
        return Icons.logout;
      case 'MANAGER_ASSIGNED':
        return Icons.supervisor_account;
      case 'MANAGER_REMOVED':
        return Icons.person_remove;
      case 'ADMIN_PROFILE_EDIT':
        return Icons.manage_accounts;
      case 'KYC_STATUS_CHANGED':
        return Icons.verified_user;
      case 'CALL_ASSIGNED':
        return Icons.trending_up;
      case 'TRADING_CALL_OPENED':
        return Icons.show_chart;
      case 'PAYMENT_APPROVED':
        return Icons.check_circle;
      case 'PAYMENT_REJECTED':
        return Icons.cancel;
      case 'SUBSCRIPTION_EXTENDED':
        return Icons.event_available;
      case 'SUBSCRIPTION_REVOKED':
        return Icons.block;
      case 'SUBSCRIPTION_SUSPENDED':
        return Icons.pause_circle;
      case 'SUBSCRIPTION_ACTIVATED':
        return Icons.play_circle;
      case 'PLAN_CREATED':
        return Icons.add_card;
      case 'PLAN_TOPUP':
        return Icons.price_check;
      case 'ACCOUNT_SUSPENDED':
        return Icons.lock;
      default:
        return Icons.event_note;
    }
  }

  String _getEventStatus(String eventType) {
    switch (eventType) {
      case 'USER_LOGIN':
      case 'NEW_DEVICE_LOGIN':
      case 'APP_SESSION_START':
        return 'Success';
      case 'USER_LOGOUT':
        return 'Logged Out';
      case 'MANAGER_ASSIGNED':
        return 'Assigned';
      case 'MANAGER_REMOVED':
        return 'Removed';
      case 'ADMIN_PROFILE_EDIT':
        return 'Edited';
      case 'KYC_STATUS_CHANGED':
        return 'Changed';
      case 'CALL_ASSIGNED':
        return 'Published';
      case 'PAYMENT_APPROVED':
        return 'Approved';
      case 'PAYMENT_REJECTED':
        return 'Rejected';
      case 'SUBSCRIPTION_EXTENDED':
        return 'Extended';
      case 'SUBSCRIPTION_REVOKED':
        return 'Revoked';
      case 'SUBSCRIPTION_SUSPENDED':
        return 'Suspended';
      case 'SUBSCRIPTION_ACTIVATED':
        return 'Activated';
      case 'PLAN_CREATED':
        return 'Created';
      case 'PLAN_TOPUP':
        return 'Topped Up';
      case 'ACCOUNT_SUSPENDED':
        return 'Suspended';
      default:
        return 'Recorded';
    }
  }

  Color _getEventColor(String eventType) {
    switch (eventType) {
      case 'USER_LOGIN':
      case 'APP_SESSION_START':
      case 'SUBSCRIPTION_ACTIVATED':
      case 'PAYMENT_APPROVED':
      case 'PLAN_CREATED':
        return AppTheme.successGreen;
      case 'NEW_DEVICE_LOGIN':
      case 'SUBSCRIPTION_EXTENDED':
      case 'PLAN_TOPUP':
      case 'ADMIN_PROFILE_EDIT':
        return AppTheme.warningOrange;
      case 'USER_LOGOUT':
        return AppTheme.textSecondary;
      case 'MANAGER_ASSIGNED':
      case 'CALL_ASSIGNED':
        return AppTheme.primaryBlue;
      case 'PAYMENT_REJECTED':
      case 'SUBSCRIPTION_REVOKED':
      case 'SUBSCRIPTION_SUSPENDED':
      case 'ACCOUNT_SUSPENDED':
      case 'MANAGER_REMOVED':
        return AppTheme.errorRed;
      default:
        return AppTheme.textSecondary;
    }
  }

  // ─── Severity ──────────────────────────────────────────────────────────────

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return const Color(0xFFDC2626); // Red-600
      case 'SECURITY':
        return const Color(0xFFD97706); // Amber-600
      case 'WARNING':
        return const Color(0xFF0284C7); // Sky-600
      case 'INFO':
      default:
        return const Color(0xFF16A34A); // Green-600
    }
  }

  Color getSeverityBgColor(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return const Color(0xFFFEE2E2);
      case 'SECURITY':
        return const Color(0xFFFEF3C7);
      case 'WARNING':
        return const Color(0xFFE0F2FE);
      case 'INFO':
      default:
        return const Color(0xFFDCFCE7);
    }
  }

  // ─── Formatting ────────────────────────────────────────────────────────────

  String _formatDatePrecise(DateTime date) {
    final ist = date.toLocal();
    return DateFormat('dd MMM yyyy, hh:mm:ss a').format(ist);
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'captured':
      case 'paid':
      case 'success':
        return AppTheme.successGreen;
      case 'failed':
        return AppTheme.errorRed;
      case 'pending':
        return AppTheme.warningOrange;
      default:
        return AppTheme.textSecondary;
    }
  }

  // ─── Filter helpers ─────────────────────────────────────────────────────────

  void updateType(String type) {
    selectedType.value = type;
    currentPage.value = 1;
  }

  void updateTimeRange(String range) {
    selectedTimeRange.value = range;
    currentPage.value = 1;
  }

  void updateSeverity(String severity) {
    selectedSeverity.value = severity;
    currentPage.value = 1;
  }

  void clearFilters() {
    selectedType.value = 'All Types';
    selectedTimeRange.value = 'All Time';
    selectedSeverity.value = 'All Severity';
    currentPage.value = 1;
  }

  void nextPage() {
    final totalPages = (filteredActivities.length / itemsPerPage).ceil();
    if (currentPage.value < totalPages) currentPage.value++;
  }

  void previousPage() {
    if (currentPage.value > 1) currentPage.value--;
  }

  void goToPage(int page) => currentPage.value = page;

  List<Map<String, dynamic>> get filteredActivities {
    var filtered = allActivities.toList();

    // Type filter
    if (selectedType.value != 'All Types') {
      filtered = filtered
          .where((a) => a['type'] == selectedType.value)
          .toList();
    }

    // Severity filter
    if (selectedSeverity.value != 'All Severity') {
      filtered = filtered
          .where((a) => a['severity'] == selectedSeverity.value)
          .toList();
    }

    // Time range filter
    final now = DateTime.now();
    switch (selectedTimeRange.value) {
      case 'Today':
        final startOfDay = DateTime(now.year, now.month, now.day);
        filtered = filtered
            .where((a) => (a['rawDate'] as DateTime).isAfter(startOfDay))
            .toList();
        break;
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        filtered = filtered
            .where((a) => (a['rawDate'] as DateTime).isAfter(startOfWeek))
            .toList();
        break;
      case 'This Month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        filtered = filtered
            .where((a) => (a['rawDate'] as DateTime).isAfter(startOfMonth))
            .toList();
        break;
      case 'This Year':
        final startOfYear = DateTime(now.year, 1, 1);
        filtered = filtered
            .where((a) => (a['rawDate'] as DateTime).isAfter(startOfYear))
            .toList();
        break;
    }

    return filtered;
  }
}
