import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'kyc_management.controller.dart';

class KycManagerController extends GetxController {
  final KycManagementController _kycManagementController =
      Get.find<KycManagementController>();

  final selectedStatus = 'All Status'.obs;
  final selectedDocumentType = 'All Types'.obs;
  final fromDateController = TextEditingController();
  final toDateController = TextEditingController();
  final selectAll = false.obs;
  final selectedItems = <bool>[].obs;

  bool get isLoading => _kycManagementController.isLoading.value;

  @override
  void onInit() {
    super.onInit();
    selectedItems.value = List.filled(10, false);
  }

  void updateStatus(String value) {
    selectedStatus.value = value;
    applyFilters();
  }

  void updateDocumentType(String value) {
    selectedDocumentType.value = value;
    applyFilters();
  }

  void toggleSelectAll() {
    selectAll.value = !selectAll.value;
    selectedItems.value = List.filled(selectedItems.length, selectAll.value);
  }

  void toggleItem(int index) {
    selectedItems[index] = !selectedItems[index];
    selectAll.value = selectedItems.every((item) => item);
  }

  void applyFilters() {}

  void resetFilters() {
    selectedStatus.value = 'All Status';
    selectedDocumentType.value = 'All Types';
    fromDateController.clear();
    toDateController.clear();
  }

  Future<void> approveSelected() async {
    // Implement logic to get selected IDs
    // await _kycManagementController.approveKyc(id);
  }

  Future<void> rejectSelected() async {
    // Implement logic to get selected IDs
    // await _kycManagementController.rejectKyc(id);
  }

  @override
  void onClose() {
    fromDateController.dispose();
    toDateController.dispose();
    super.onClose();
  }
}
