import 'dart:typed_data';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web/web.dart' as web;
import 'package:spresearch_web/models/report.model.dart';
import 'package:spresearch_web/services/report.service.dart';
import 'package:spresearch_web/services/segment.service.dart';

class ReportController extends GetxController {
  late final ReportService _reportService;
  late final SegmentService _segmentService;

  var reports = <ReportModel>[].obs;
  var selectedReports = <String>[].obs;
  var isLoading = false.obs;
  var totalCount = 0.obs;

  var categories = <Map<String, dynamic>>[].obs;
  var categoryFilter = 'All Categories'.obs; // Stores ID or 'All Categories'

  var allPlans = <Map<String, dynamic>>[].obs;
  var planFilter = 'All Plans'.obs;

  var reportTypeFilter = 'All Types'.obs;
  final fromDateController = TextEditingController();
  final toDateController = TextEditingController();

  final currentPage = 1.obs;
  final itemsPerPage = 10;

  @override
  void onInit() {
    _reportService = Get.find<ReportService>();
    _segmentService = Get.find<SegmentService>();
    super.onInit();
    fetchCategories();
    fetchReports();
  }

  Future<void> fetchCategories() async {
    try {
      final result = await _segmentService.getSegmentDropdownList();

      // Sort categories by user count descending, then alphabetically by name
      result.sort((a, b) {
        final countA = a['userCount'] ?? 0;
        final countB = b['userCount'] ?? 0;

        if (countB != countA) {
          return countB.compareTo(countA);
        }

        final nameA = (a['segmentName'] ?? '').toString().toLowerCase();
        final nameB = (b['segmentName'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });

      categories.value = result;

      // Fetch all plans in parallel to populate plan dropdown
      final plansMap = <String, Map<String, dynamic>>{};
      final planFutures = result.map((segment) async {
        final segmentId = segment['_id'];
        if (segmentId == null) return;
        try {
          final plans = await _segmentService.getPlansBySegment(segmentId);
          for (var plan in plans) {
            final id = plan['_id'] ?? plan['id'];
            if (id != null && !plansMap.containsKey(id)) {
              plansMap[id] = {
                'id': id,
                'name': plan['planName'] ?? 'Unknown Plan',
              };
            }
          }
        } catch (e) {
          debugPrint('Debug: Error fetching plans for $segmentId: $e');
        }
      });
      await Future.wait(planFutures);
      final sortedPlans = plansMap.values.toList();
      sortedPlans.sort(
        (a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo(
          (b['name'] ?? '').toString().toLowerCase(),
        ),
      );
      allPlans.value = sortedPlans;
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> fetchReports() async {
    isLoading.value = true;
    try {
      String? segmentId;
      if (categoryFilter.value != 'All Categories') {
        segmentId = categoryFilter.value;
      }

      String? start;
      if (fromDateController.text.isNotEmpty &&
          fromDateController.text != 'mm/dd/yyyy') {
        start = fromDateController.text;
      }

      String? end;
      if (toDateController.text.isNotEmpty &&
          toDateController.text != 'mm/dd/yyyy') {
        end = toDateController.text;
      }

      String? type;
      if (reportTypeFilter.value != 'All Types') {
        type = reportTypeFilter.value;
      }

      String? planId;
      if (planFilter.value != 'All Plans') {
        planId = planFilter.value;
      }

      final result = await _reportService.getReports(
        page: currentPage.value,
        pageSize: itemsPerPage,
        segmentId: segmentId,
        planId: planId,
        reportType: type,
        startDate: start,
        endDate: end,
      );

      reports.assignAll(result.reports);
      totalCount.value = result.totalCount;
    } catch (e) {
      debugPrint('Error fetching reports: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilters() {
    currentPage.value = 1; // Reset to first page on filter change
    fetchReports();
  }

  void resetFilters() {
    categoryFilter.value = 'All Categories';
    planFilter.value = 'All Plans';
    reportTypeFilter.value = 'All Types';
    fromDateController.clear();
    toDateController.clear();
    currentPage.value = 1;
    fetchReports();
  }

  void setPage(int page) {
    currentPage.value = page;
    fetchReports();
  }

  int get totalPages => (totalCount.value / itemsPerPage).ceil();

  String getCategoryName(String id) {
    if (categories.isEmpty) return id;
    final category = categories.firstWhere(
      (cat) => cat['_id'] == id,
      orElse: () => {'segmentName': id},
    );
    return category['segmentName'] ?? category['name'] ?? id;
  }

  Future<void> togglePublishStatus(ReportModel report) async {
    isLoading.value = true;
    try {
      final success = await _reportService.publishReportStatus(
        id: report.id,
        currentStatus: report.status.toLowerCase() == 'published'
            ? 'published'
            : 'draft',
      );
      if (success) {
        Get.snackbar('Success', 'Report status updated');
        await fetchReports();
      }
    } catch (e) {
      debugPrint('Error toggling status: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteReport(String id) async {
    isLoading.value = true;
    try {
      final success = await _reportService.deleteReport(id);
      if (success) {
        Get.snackbar('Success', 'Report deleted');
        await fetchReports();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting report: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> downloadReport(ReportModel report) async {
    isLoading.value = true;
    try {
      final bytes = await _reportService.downloadReport(
        report.id,
        reportName: report.reportName,
      );
      if (bytes != null) {
        final blob = web.Blob(
          [bytes.toJS].toJS,
          web.BlobPropertyBag(type: 'application/octet-stream'),
        );
        final url = web.URL.createObjectURL(blob);

        final anchor = web.HTMLAnchorElement()
          ..href = url
          ..download = report.reportOriginalName ?? 'report_${report.id}.pdf';

        web.document.body?.appendChild(anchor);
        anchor.click();
        web.document.body?.removeChild(anchor);
        web.URL.revokeObjectURL(url);
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Failed to download report. Unauthorized or server error.',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error in downloadReport controller: $e');
      Get.snackbar('Error', 'An error occurred during download');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
