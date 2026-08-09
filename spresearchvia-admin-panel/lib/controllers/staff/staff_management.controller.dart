import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/services/staff.service.dart';
import 'package:spresearch_web/models/staff.model.dart';

class StaffManagementController extends GetxController {
  late final StaffService _staffService;

  var managers = <StaffModel>[].obs;
  var admins = <StaffModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _staffService = Get.find<StaffService>();
    fetchStaff();
  }

  Future<void> fetchStaff() async {
    isLoading.value = true;
    try {
      final list = await _staffService.getStaffList();
      managers.value = list
          .where((s) => s.department.trim().toLowerCase().contains('manager'))
          .toList();
      admins.value = list
          .where((s) => s.department.trim().toLowerCase().contains('research') || s.department.trim().toLowerCase().contains('admin'))
          .toList();
    } catch (e) {
      debugPrint('Error fetching staff: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
