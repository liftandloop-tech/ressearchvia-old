import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../models/staff.model.dart';
import '../../services/staff.service.dart';

class StaffDetailsController extends GetxController {
  final StaffService _staffService = Get.find<StaffService>();

  var isLoading = false.obs;
  var staffId = ''.obs;
  var staff = Rxn<StaffModel>();

  @override
  void onInit() {
    super.onInit();
    staffId.value = Get.parameters['id'] ?? '';
    if (staffId.value.isNotEmpty) {
      fetchStaffDetails();
    }
  }

  Future<void> fetchStaffDetails() async {
    isLoading.value = true;
    try {
      final list = await _staffService.getStaffList();
      final found = list.firstWhereOrNull((s) => s.id == staffId.value || s.staffId == staffId.value);
      if (found != null) {
        staff.value = found;
      }
    } catch (e) {
      debugPrint('Error fetching staff details: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
