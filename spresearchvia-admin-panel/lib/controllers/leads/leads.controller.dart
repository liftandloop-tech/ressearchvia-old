import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/lead.service.dart';
import '../../models/lead.model.dart';
import '../../services/staff.service.dart';
import '../../models/staff.model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app.config.dart';

class LeadsController extends GetxController {
  final LeadService _leadService = Get.put(LeadService());
  final StaffService _staffService = Get.put(StaffService());

  var isLoading = false.obs;
  var leadsList = <LeadModel>[].obs;
  var totalLeads = 0.obs;

  // Filter values
  var currentPage = 1.obs;
  final int itemsPerPage = 10;
  var searchQuery = ''.obs;
  var selectedStage = ''.obs;
  var selectedRMId = ''.obs;

  // Staff dropdown list
  var staffList = <StaffModel>[].obs;

  // Add/Edit Form controllers
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final assignRMId = ''.obs;
  final leadStage = 'New'.obs;

  // Follow-up Form controllers
  final followUpNotesController = TextEditingController();
  var followUpDate = DateTime.now().add(const Duration(days: 1)).obs;

  @override
  void onInit() {
    super.onInit();
    fetchLeads();
    fetchStaffDropdown();
  }

  Future<void> fetchLeads() async {
    isLoading.value = true;
    try {
      final res = await _leadService.getLeads(
        page: currentPage.value,
        limit: itemsPerPage,
        search: searchQuery.value,
        stage: selectedStage.value,
        assignedRM: selectedRMId.value,
      );
      if (res.error == null) {
        leadsList.assignAll(res.leads);
        totalLeads.value = res.total;
      } else {
        Get.snackbar('Error', res.error!, backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchStaffDropdown() async {
    try {
      final list = await _staffService.getStaffList();
      staffList.assignAll(list);
    } catch (e) {
      debugPrint('Error loading staff dropdown: $e');
    }
  }

  void updateFilters({String? search, String? stage, String? rmId}) {
    if (search != null) searchQuery.value = search;
    if (stage != null) selectedStage.value = stage;
    if (rmId != null) selectedRMId.value = rmId;
    currentPage.value = 1;
    fetchLeads();
  }

  void resetFilters() {
    searchQuery.value = '';
    selectedStage.value = '';
    selectedRMId.value = '';
    currentPage.value = 1;
    fetchLeads();
  }

  void resetForm() {
    nameController.clear();
    phoneController.clear();
    emailController.clear();
    cityController.clear();
    stateController.clear();
    assignRMId.value = '';
    leadStage.value = 'New';
  }

  Future<void> saveLead({String? existingId}) async {
    if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
      Get.snackbar('Validation Alert', 'Full Name and Phone Number are required', backgroundColor: Colors.orange.withOpacity(0.1));
      return;
    }

    isLoading.value = true;
    try {
      final data = {
        'fullName': nameController.text.trim(),
        'mobileNumber': phoneController.text.trim(),
        'emailAddress': emailController.text.trim().isEmpty ? null : emailController.text.trim(),
        'assignedRM': assignRMId.value.isEmpty ? null : assignRMId.value,
        'stage': leadStage.value,
        'personalDetails': {
          'city': cityController.text.trim().isEmpty ? null : cityController.text.trim(),
          'state': stateController.text.trim().isEmpty ? null : stateController.text.trim(),
        }
      };

      bool success;
      if (existingId != null) {
        success = await _leadService.updateLead(existingId, data);
      } else {
        success = await _leadService.createLead(data);
      }

      if (success) {
        Get.back();
        fetchLeads();
        Get.snackbar('Success', existingId != null ? 'Lead updated successfully' : 'Lead created successfully', backgroundColor: Colors.green.withOpacity(0.1));
      } else {
        Get.snackbar('Error', 'Failed to save lead', backgroundColor: Colors.red.withOpacity(0.1));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addFollowUpLog(String leadId) async {
    if (followUpNotesController.text.trim().isEmpty) {
      Get.snackbar('Validation Alert', 'Follow-up notes cannot be empty', backgroundColor: Colors.orange.withOpacity(0.1));
      return;
    }

    try {
      final success = await _leadService.addFollowUp(leadId, followUpNotesController.text.trim(), followUpDate.value);
      if (success) {
        Get.back();
        followUpNotesController.clear();
        fetchLeads();
        Get.snackbar('Success', 'Follow-up log recorded', backgroundColor: Colors.green.withOpacity(0.1));
      } else {
        Get.snackbar('Error', 'Failed to add follow-up', backgroundColor: Colors.red.withOpacity(0.1));
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> pickAndUploadBulkLeads() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );

      if (result != null && result.files.single.bytes != null) {
        isLoading.value = true;
        final res = await _leadService.uploadBulkLeads(
          result.files.single.bytes!,
          result.files.single.name,
        );

        isLoading.value = false;
        if (res.success) {
          fetchLeads();
          Get.snackbar('Import Complete', res.message ?? 'Leads imported successfully', backgroundColor: Colors.green.withOpacity(0.1));
        } else {
          Get.snackbar('Import Failed', res.message ?? 'An error occurred during import', backgroundColor: Colors.red.withOpacity(0.1));
        }
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Error', 'Failed to read file: $e', backgroundColor: Colors.red.withOpacity(0.1));
    }
  }

  Future<void> downloadTemplate() async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/leads/template');
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        Get.snackbar('Error', 'Could not download template', backgroundColor: Colors.red.withOpacity(0.1));
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to start download: $e', backgroundColor: Colors.red.withOpacity(0.1));
    }
  }
}
