import '../data/dummy.data.dart';
import '../models/user.model.dart';
import '../models/report.model.dart';

class DataService {
  static Future<List<UserModel>> getUsers() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return DummyData.users.map((user) => UserModel.fromJson(user)).toList();
  }

  static Future<List<ReportModel>> getReports() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return DummyData.reports
        .map((report) => ReportModel.fromJson(report))
        .toList();
  }

  static Future<Map<String, dynamic>> getDashboardStats() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return DummyData.dashboardStats;
  }

  static Future<Map<String, dynamic>> getAnalyticsData() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return DummyData.analyticsData;
  }

  static Future<List<Map<String, dynamic>>> getChartData(String type) async {
    await Future.delayed(const Duration(milliseconds: 400));
    switch (type) {
      case 'reportsByCategory':
        return DummyData.reportsByCategoryData;
      case 'reportsOverTime':
        return DummyData.reportsOverTimeData;
      case 'revenueGrowth':
        return DummyData.revenueChartData['data'] ?? [];
      default:
        return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return DummyData.subscriptionPlans;
  }

  static Future<bool> updateUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return true;
  }

  static Future<bool> deleteUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return true;
  }

  static Future<bool> approveKyc(String kycId) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return true;
  }

  static Future<bool> rejectKyc(String kycId) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return true;
  }
}
