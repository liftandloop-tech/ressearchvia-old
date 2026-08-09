import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spresearch_web/services/api.service.dart';

class DashboardService extends ApiService {
  // onInit handled by ApiService

  dynamic _parseBody(dynamic body) {
    if (body is String) {
      try {
        return jsonDecode(body);
      } catch (e) {
        debugPrint('Error parsing body: $e');
        return null;
      }
    }
    return body;
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null || dateStr.toString().isEmpty) {
      return '-';
    }
    try {
      final dateTime = DateTime.parse(dateStr.toString()).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    } catch (e) {
      debugPrint('Error parsing date: $dateStr - $e');
      return dateStr.toString();
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await get('/user/dashboard-count');
      debugPrint('Dashboard API Response Status: ${response.statusCode}');

      if (response.status.hasError) {
        debugPrint('Dashboard API Error: ${response.statusText}');
        return {
          'totalUsers': '0',
          'activeSubscriptions': '0',
          'pendingKyc': '0',
        };
      }

      final body = _parseBody(response.body);
      if (body == null || body['data'] == null) {
        debugPrint('Dashboard API: Body or Data is null');
        return {
          'totalUsers': '0',
          'activeSubscriptions': '0',
          'pendingKyc': '0',
        };
      }

      final data = body['data'];
      return {
        'totalUsers': (data['userCount'] ?? 0).toString(),
        'activeSubscriptions': (data['activeSubcription'] ?? 0).toString(),
        'pendingKyc': (data['pandingKyc'] ?? 0).toString(),
      };
    } catch (e) {
      debugPrint('Dashboard API Exception: $e');
      return {'totalUsers': '0', 'activeSubscriptions': '0', 'pendingKyc': '0'};
    }
  }

  Future<List<Map<String, dynamic>>> getRenewalsList() async {
    try {
      final response = await get('/user/user-list');

      if (response.status.hasError) {
        debugPrint('Error fetching renewals list: ${response.statusText}');
        return [];
      }

      final body = _parseBody(response.body);
      if (body == null || body['data'] == null) {
        return [];
      }

      final data = body['data']['userData'];
      if (data == null || data is! List) {
        return [];
      }

      return data.map<Map<String, dynamic>>((item) {
        final userDetails = item['userDetails'] ?? {};
        final name = userDetails['APP_NAME'] ?? item['fullName'] ?? 'Unknown';

        String? endDateStr = item['packageEndDate'];
        DateTime? endDate;
        if (endDateStr != null) {
          endDate = DateTime.tryParse(endDateStr);
        }

        String daysLeft = '-';
        String status = item['packagestatus'] ?? 'Inactive';

        if (endDate != null) {
          final diff = endDate.difference(DateTime.now()).inDays;

          if (diff >= 365) {
            status = 'Renewed';
            daysLeft = '+${diff}d';
          } else if (diff >= 5 && diff <= 10) {
            status = 'Expiring Soon';
            daysLeft = '$diff Days';
          } else if (diff < 5) {
            status = 'Not Renewed';
            // If expired (negative diff), show 0 Days or keep negative?
            // User image shows "3 Days" for Not Renewed.
            // Assuming we show remaining days if positive, else 0 or Expired.
            // But user said "only show days of active plan".
            // If "Not Renewed" means expired, maybe we shouldn't show days?
            // However, the image shows "3 Days" in Red for "Not Renewed".
            // This implies "Not Renewed" can mean "Very close to expiry" (< 5 days).
            // If it is actually expired (diff < 0), let's show "Expired".
            if (diff < 0) {
              daysLeft = 'Expired';
            } else {
              daysLeft = '$diff Days';
            }
          } else {
            // Between 10 and 365
            // Keep original status or map to Active?
            // If original status is 'active', keep it.
            if (status.toLowerCase() == 'active') {
              daysLeft = '$diff Days';
            } else {
              // If inactive but has future date?
              daysLeft = '$diff Days';
            }
          }
        }

        String expiryDate = '-';
        if (endDateStr != null && endDateStr.length >= 10) {
          expiryDate = endDateStr.substring(0, 10);
        }

        return {
          'id': item['_id'] ?? '',
          'name': userDetails['APP_NAME'] ?? item['fullName'] ?? 'Unknown',
          'email': userDetails['APP_EMAIL'] ?? item['email'] ?? 'No Email',
          'phone': userDetails['APP_MOB_NO']?.toString() ?? item['phone'] ?? '',
          'kycStatus': item['kycStatus'] ?? 'Pending',
          'createdAt': _formatDate(item['createdAt']),
          'rawCreatedAt': item['createdAt'],
          'plan': item['packageName'] ?? 'No Plan',
          'expiryDate': expiryDate,
          'renewalDate': '-',
          'status': status,
          'daysLeft': daysLeft,
          'manager': item['Manager'] ?? item['managerName'] ?? 'Unassigned',
          'managerId': item['ManagerId'] ?? item['managerId'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching renewals list: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecentPayments() async {
    try {
      final response = await get('/user/purchase/recent-plan-payment-list');

      if (response.status.hasError) {
        return Future.error(response.statusText ?? 'Error fetching data');
      }

      final body = _parseBody(response.body);
      if (body == null || body['data'] == null) {
        return [];
      }

      final List<dynamic> data = body['data']['recentPaymentList'] ?? [];

      return data.map((item) {
        String status = item['packagestatus'] ?? 'Unknown';
        // Capitalize status
        if (status.isNotEmpty) {
          status = status[0].toUpperCase() + status.substring(1);
        }

        // Format date (simple YYYY-MM-DD)
        String date = item['createdAt'] ?? '';
        if (date.length >= 10) {
          date = date.substring(0, 10);
        }

        final userDetails = item['userDetails'] ?? {};
        final name = userDetails['APP_NAME'] ?? item['fullName'] ?? 'Unknown';

        return {
          'id': item['_id'] ?? '',
          'user': name,
          'plan': item['packageName'] ?? 'Unknown Plan',
          'amount': item['packageAmount']?.toString() ?? '-',
          'date': date,
          'status': status,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching recent payments: $e');
      return [];
    }
  }
}
