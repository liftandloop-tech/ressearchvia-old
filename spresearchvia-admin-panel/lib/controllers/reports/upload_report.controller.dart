import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:spresearch_web/services/report.service.dart';
import 'package:spresearch_web/services/segment.service.dart';
import 'package:spresearch_web/controllers/reports/reports_navigation.controller.dart';
import 'package:spresearch_web/models/report.model.dart';
import 'package:spresearch_web/controllers/reports/report.controller.dart';

import 'package:spresearch_web/config/app.config.dart';
import 'package:spresearch_web/ui/widgets/file_preview_dialog.widget.dart';

class UploadReportController extends GetxController {
  final ReportService _reportService = Get.find<ReportService>();
  final SegmentService _segmentService = Get.find<SegmentService>();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final newUpdateController = TextEditingController();
  final youtubeUrlController = TextEditingController();

  var segments = <Map<String, dynamic>>[].obs;
  var selectedSegmentIds = <String>[].obs; // Changed to List

  var allPlans = <Map<String, dynamic>>[].obs; // All plans from all segments
  var filteredPlans = <Map<String, dynamic>>[].obs; // Filtered based on segment
  var selectedPlanIds = <String>[].obs; // Changed to List

  var selectedReportType = 'Trading calls'.obs;
  var uploadedFileName = ''.obs;
  var uploadedFileBytes = Rxn<Uint8List>();
  var isUploading = false.obs;
  var isLoading = false.obs;
  var isLoadingSegments = true.obs; // Add loading state for segments
  var isLoadingPlans = false.obs; // Add loading state for plans

  var isEditMode = false.obs;
  var isFileRemoved =
      false.obs; // Track if user explicitly removed the existing file
  var existingUpdates = <Map<String, String>>[].obs;
  String? reportId;

  @override
  void onInit() {
    super.onInit();
    fetchSegments();
  }

  void loadReportData(ReportModel report) async {
    isEditMode.value = true;
    reportId = report.id;
    titleController.text = report.title;
    descriptionController.text = report.description;
    newUpdateController.clear();
    youtubeUrlController.text = report.youtubeUrl ?? "";
    selectedReportType.value = report.reportType;
    existingUpdates.assignAll(report.updates);

    debugPrint('=== Loading Report Data for Edit ===');
    debugPrint('Report ID: ${report.id}');
    debugPrint('Report Segment IDs: ${report.segmentIds}');

    // Wait for segments AND plans to load
    if ((segments.isEmpty && isLoadingSegments.value) ||
        (allPlans.isEmpty && isLoadingPlans.value)) {
      debugPrint('Waiting for segments/plans to load...');
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 200));
        return isLoadingSegments.value || isLoadingPlans.value;
      });
      debugPrint('Segments/Plans load check complete.');
    }

    // Set selected segments
    if (report.segmentIds.isNotEmpty) {
      // Filter only those that exist in our loaded segments list to be safe
      final validIds = report.segmentIds
          .where((id) => segments.any((s) => s['_id'] == id))
          .toList();
      selectedSegmentIds.assignAll(validIds);
    } else if (report.segmentId.isNotEmpty) {
      // Fallback for older data
      final validIds = report.segmentId
          .split(',')
          .where((id) => segments.any((s) => s['_id'] == id))
          .toList();
      if (validIds.isNotEmpty) selectedSegmentIds.assignAll(validIds);
    }

    if (selectedSegmentIds.isEmpty && report.category.isNotEmpty) {
      // Attempt fallback by name match (e.g. legacy data)
      debugPrint('IDs not found. Attempting name match: ${report.category}');
      final names = report.category
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .toList();
      final matchingSegments = segments
          .where((s) {
            final sName = (s['segmentName'] ?? '').toString().toLowerCase();
            return names.contains(sName);
          })
          .map((s) => s['_id'].toString())
          .toList();

      if (matchingSegments.isNotEmpty) {
        selectedSegmentIds.assignAll(matchingSegments);
      }
    }

    filterPlansBySegment();

    debugPrint('Filtered plans count: ${filteredPlans.length}');

    if (report.planArray.isNotEmpty) {
      // Filter plans that actually exist in filteredPlans
      final validPlans = report.planArray
          .where((id) => filteredPlans.any((p) => p['id'] == id))
          .toList();
      selectedPlanIds.assignAll(validPlans);
    } else {
      selectedPlanIds.clear();
    }

    if (report.reportOriginalName != null &&
        report.reportOriginalName!.isNotEmpty) {
      uploadedFileName.value = report.reportOriginalName!;
    } else {
      uploadedFileName.value = '';
    }
    uploadedFileBytes.value = null;
    isFileRemoved.value = false;
  }

  void removeFile() {
    uploadedFileName.value = '';
    uploadedFileBytes.value = null;
    isFileRemoved.value = true;
  }

  void previewFile() {
    if (uploadedFileName.value.isEmpty || isFileRemoved.value) return;

    if (uploadedFileBytes.value != null) {
      // Preview locally picked file
      Get.dialog(
        FilePreviewDialog(
          fileName: uploadedFileName.value,
          fileBytes: uploadedFileBytes.value,
        ),
      );
    } else if (isEditMode.value && reportId != null) {
      // Preview existing file
      // We use the direct "original" URL to bypass middleware for previews in the admin panel
      final report = Get.find<ReportController>().reports.firstWhereOrNull(
        (r) => r.id == reportId,
      );
      final reportName = report?.reportName ?? uploadedFileName.value;

      final url = AppConfig.buildImageUrl('reports/$reportName');

      Get.dialog(
        FilePreviewDialog(fileName: uploadedFileName.value, fileUrl: url),
      );
    }
  }

  void resetForm() {
    isEditMode.value = false;
    reportId = null;
    titleController.clear();
    descriptionController.clear();
    newUpdateController.clear();
    youtubeUrlController.clear();

    selectedSegmentIds.clear();
    selectedPlanIds.clear();
    filteredPlans.clear();
    selectedReportType.value = 'Trading calls';
    existingUpdates.clear();
    uploadedFileName.value = '';
    uploadedFileBytes.value = null;
    isFileRemoved.value = false;
  }

  Future<void> fetchSegments() async {
    try {
      isLoadingSegments.value = true;
      debugPrint('=== Starting fetchSegments ===');

      // Fetch segments from API
      final segmentsList = await _segmentService.getSegmentDropdownList();
      debugPrint('Fetched ${segmentsList.length} segments from API');

      if (segmentsList.isEmpty) {
        debugPrint('⚠️ Warning: No segments returned from API');
        Get.snackbar(
          'Warning',
          'No segments available. Please contact administrator.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[900],
        );
        segments.value = [];
        isLoadingSegments.value = false;
        return;
      }

      // Sort segments by user count descending, then alphabetically by name
      segmentsList.sort((a, b) {
        final countA = int.tryParse(a['userCount']?.toString() ?? '0') ?? 0;
        final countB = int.tryParse(b['userCount']?.toString() ?? '0') ?? 0;

        if (countB != countA) {
          return countB.compareTo(countA);
        }

        final nameA = (a['segmentName'] ?? '').toString().toLowerCase();
        final nameB = (b['segmentName'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });

      segments.value = segmentsList;
      debugPrint('Segments loaded: ${segments.length}');

      // Fetch plans for all segments upfront for better UX
      await _fetchAllPlans();
    } catch (e) {
      debugPrint('❌ Error fetching segments: $e');
      Get.snackbar(
        'Error',
        'Failed to load segments. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      segments.value = [];
    } finally {
      isLoadingSegments.value = false;
    }
  }

  Future<void> _fetchAllPlans() async {
    try {
      isLoadingPlans.value = true;
      allPlans.clear();

      for (var segment in segments) {
        final segmentId = segment['_id'];
        final segmentName = segment['segmentName'] ?? 'Unknown';

        try {
          final plans = await _segmentService.getPlansBySegment(segmentId);

          for (var plan in plans) {
            allPlans.add({
              'id': plan['_id'] ?? plan['id'],
              'name': plan['planName'] ?? 'Unknown Plan',
              'segmentId': segmentId,
              'segmentName': segmentName,
            });
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching plans for $segmentName: $e');
        }
      }

      debugPrint('Total plans loaded: ${allPlans.length}');

      // Sort all plans alphabetically
      allPlans.sort((a, b) {
        final nameA = (a['name'] ?? '').toString().toLowerCase();
        final nameB = (b['name'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });
    } catch (e) {
      debugPrint('❌ Error fetching plans: $e');
    } finally {
      isLoadingPlans.value = false;
    }
  }

  void toggleSegment(String segmentId) {
    if (selectedSegmentIds.contains(segmentId)) {
      selectedSegmentIds.remove(segmentId);
    } else {
      selectedSegmentIds.add(segmentId);
    }

    filterPlansBySegment();

    // Remove plans that are no longer valid
    selectedPlanIds.removeWhere(
      (id) => !filteredPlans.any((p) => p['id'] == id),
    );
  }

  void filterPlansBySegment() {
    if (selectedSegmentIds.isEmpty) {
      filteredPlans.value = [];
    } else {
      // Show plans that belong to ANY of the selected segments
      final matchingPlans = allPlans
          .where((plan) => selectedSegmentIds.contains(plan['segmentId']))
          .toList();

      // Deduplicate plans (Universal plans appear under multiple segments)
      final uniquePlans = <String, Map<String, dynamic>>{};
      for (var plan in matchingPlans) {
        final id = plan['id'] as String;
        if (!uniquePlans.containsKey(id)) {
          uniquePlans[id] = plan;
        }
      }

      filteredPlans.value = uniquePlans.values.toList();
    }

    // Sort filtered plans alphabetically by name
    filteredPlans.sort((a, b) {
      final nameA = (a['name'] ?? '').toString().toLowerCase();
      final nameB = (b['name'] ?? '').toString().toLowerCase();
      return nameA.compareTo(nameB);
    });
  }

  void togglePlan(String planId) {
    if (selectedPlanIds.contains(planId)) {
      selectedPlanIds.remove(planId);
    } else {
      selectedPlanIds.add(planId);
    }
  }

  void toggleAllSegments(bool selected) {
    if (selected) {
      selectedSegmentIds.assignAll(
        segments.map((s) => s['_id'] as String).toList(),
      );
    } else {
      selectedSegmentIds.clear();
    }
    filterPlansBySegment();
    selectedPlanIds.removeWhere(
      (id) => !filteredPlans.any((p) => p['id'] == id),
    );
  }

  void toggleAllPlans(bool selected) {
    if (selected) {
      selectedPlanIds.assignAll(
        filteredPlans.map((p) => p['id'] as String).toList(),
      );
    } else {
      selectedPlanIds.clear();
    }
  }

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'gif', 'webp'],
        withData: true, // Important for web
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        uploadedFileName.value = file.name;
        uploadedFileBytes.value = file.bytes;
        isFileRemoved.value = false; // Reset if new file is picked
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      Get.snackbar('Error', 'Failed to pick file');
    }
  }

  Future<void> submit() async {
    // Validation with clear error messages
    if (titleController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please enter a report title',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }

    if (selectedSegmentIds.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please select at least one segment',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }

    bool isDetailedReport = selectedReportType.value == 'Detailed Reports';
    if (isDetailedReport &&
        uploadedFileBytes.value == null &&
        !isEditMode.value) {
      Get.snackbar(
        'Validation Error',
        'Please upload a file for Detailed Reports',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }

    // Handle Plan Array
    List<String> planArray = selectedPlanIds.toList();

    // Check coverage
    if (filteredPlans.isNotEmpty && planArray.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please select at least one plan',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }

    isLoading.value = true;

    // JSON Encode the list of segment IDs
    final segmentPayload = jsonEncode(selectedSegmentIds);

    bool success;
    if (isEditMode.value) {
      success = await _reportService.updateReport(
        id: reportId!,
        title: titleController.text,
        categoryId: segmentPayload,
        planIds: planArray,
        reportType: selectedReportType.value,
        description: descriptionController.text,
        newUpdate: newUpdateController.text.trim(),
        youtubeUrl: youtubeUrlController.text.trim(),
        fileBytes: uploadedFileBytes.value, // Can be null
        fileName:
            (uploadedFileName.value.isNotEmpty &&
                !isFileRemoved.value &&
                uploadedFileBytes.value != null)
            ? uploadedFileName.value
            : null,
        removeFile: isFileRemoved.value,
      );
    } else {
      success = await _reportService.createReport(
        title: titleController.text,
        categoryId: segmentPayload, // Sending JSON string
        planIds: planArray,
        reportType: selectedReportType.value,
        description: descriptionController.text,
        youtubeUrl: youtubeUrlController.text.trim(),
        fileBytes: uploadedFileBytes.value,
        fileName: uploadedFileName.value,
      );
    }

    isLoading.value = false;

    if (success) {
      if (Get.isRegistered<ReportController>()) {
        Get.find<ReportController>().fetchReports();
      }

      if (Get.isRegistered<ReportsNavigationController>()) {
        Get.find<ReportsNavigationController>().goBack();
      } else {
        Get.back();
      }
      Get.snackbar(
        'Success',
        isEditMode.value
            ? 'Report updated successfully'
            : 'Report uploaded successfully',
      );
    } else {
      Get.snackbar(
        'Error',
        isEditMode.value
            ? 'Failed to update report'
            : 'Failed to upload report',
      );
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    newUpdateController.dispose();
    youtubeUrlController.dispose();
    super.onClose();
  }
}
