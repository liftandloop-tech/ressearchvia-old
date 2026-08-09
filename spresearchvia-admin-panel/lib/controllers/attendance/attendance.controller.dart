import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/attendance.service.dart';
import '../../models/attendance.model.dart';
import '../../services/staff.service.dart';
import '../../models/staff.model.dart';

class AttendanceController extends GetxController {
  final AttendanceService _attendanceService = Get.put(AttendanceService());
  final StaffService _staffService = Get.put(StaffService());

  var isLoading = false.obs;
  var attendanceRecords = <AttendanceModel>[].obs;
  var performanceOverview = <Map<String, dynamic>>[].obs;
  var staffList = <StaffModel>[].obs;

  // Filters
  var selectedStaffId = ''.obs;
  var startDate = Rxn<DateTime>();
  var endDate = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    fetchAttendance();
    fetchPerformance();
    loadStaff();
  }

  Future<void> fetchAttendance() async {
    isLoading.value = true;
    try {
      final sDate = startDate.value != null ? startDate.value!.toIso8601String().substring(0, 10) : null;
      final eDate = endDate.value != null ? endDate.value!.toIso8601String().substring(0, 10) : null;
      
      final res = await _attendanceService.getAttendanceReport(
        startDate: sDate,
        endDate: eDate,
        staffId: selectedStaffId.value.isEmpty ? null : selectedStaffId.value,
      );

      if (res.error == null) {
        attendanceRecords.assignAll(res.records);
      } else {
        Get.snackbar('Error', res.error!, backgroundColor: Colors.red.withOpacity(0.1));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPerformance() async {
    try {
      final res = await _attendanceService.getPerformanceOverview();
      if (res.error == null) {
        performanceOverview.assignAll(res.performance);
      }
    } catch (e) {
      debugPrint('Error getting performance overview: $e');
    }
  }

  Future<void> loadStaff() async {
    try {
      final list = await _staffService.getStaffList();
      staffList.assignAll(list);
    } catch (e) {
      debugPrint('Error loading staff list: $e');
    }
  }

  void updateFilters({String? staffId, DateTime? start, DateTime? end}) {
    if (staffId != null) selectedStaffId.value = staffId;
    if (start != null) startDate.value = start;
    if (end != null) endDate.value = end;
    fetchAttendance();
  }

  void resetFilters() {
    selectedStaffId.value = '';
    startDate.value = null;
    endDate.value = null;
    fetchAttendance();
  }
}
