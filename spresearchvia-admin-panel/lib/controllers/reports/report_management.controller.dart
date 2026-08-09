import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/services/report.service.dart';
import 'package:spresearch_web/models/report.model.dart';

class ReportManagementController extends GetxController {
  final ReportService _reportService = Get.find<ReportService>();

  var reports = <ReportModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchReports();
  }

  Future<void> fetchReports() async {
    isLoading.value = true;
    try {
      final result = await _reportService.getReports(
        page: 1,
        pageSize: 100,
      ); // Fetch initial batch or all
      reports.value = result.reports;
    } catch (e) {
      debugPrint('Error fetching reports: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteReport(String id) async {
    try {
      final success = await _reportService.deleteReport(id);
      if (success) {
        reports.removeWhere((report) => report.id == id);
        Get.snackbar('Success', 'Report deleted successfully');
      } else {
        Get.snackbar('Error', 'Failed to delete report');
      }
    } catch (e) {
      debugPrint('Error deleting report: $e');
      Get.snackbar('Error', 'An error occurred while deleting report');
    }
  }
}
