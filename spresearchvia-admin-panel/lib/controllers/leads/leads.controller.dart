import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/lead.service.dart';
import '../../models/lead.model.dart';
import '../../models/lead_pool.model.dart';
import '../../services/staff.service.dart';
import '../../models/staff.model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app.config.dart';
import '../../ui/screens/leads/widgets/import_wizard.widget.dart';

class LeadsController extends GetxController {
  final LeadService _leadService = Get.find<LeadService>();
  LeadService get leadService => _leadService;
  final StaffService _staffService = Get.put(StaffService());

  var isLoading = false.obs;
  var leadsList = <LeadModel>[].obs;
  var totalLeads = 0.obs;

  // Filter values
  var currentPage = 1.obs;
  final int itemsPerPage = 50;
  var searchQuery = ''.obs;
  var selectedStage = ''.obs;
  var selectedRMId = ''.obs;
  var selectedFilterPoolId = ''.obs;

  // Pools state
  var leadPoolsList = <LeadPoolModel>[].obs;
  var isPoolsLoading = false.obs;
  var selectedPullPoolId = ''.obs;

  // Pull stats
  var freshAvailable = 0.obs;
  var myFresh = 0.obs;
  var freshMax = 100.obs;
  var myUnread = 0.obs;
  var unreadMax = 50.obs;
  var isPulling = false.obs;
  var pullMessage = ''.obs;

  // Staff dropdown list
  var staffList = <StaffModel>[].obs;

  // Selected lead IDs for bulk actions
  var selectedLeadIds = <String>[].obs;

  // Add/Edit Form controllers
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final assignRMId = ''.obs;
  final assignLeadPoolId = ''.obs;
  final leadStage = 'New'.obs;

  // Follow-up Form controllers
  final followUpNotesController = TextEditingController();
  var followUpDate = DateTime.now().add(const Duration(days: 1)).obs;
  var followUpType = 'Call'.obs;
  var followUpStatus = 'Pending'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLeadPools();
    fetchLeads();
    fetchStaffDropdown();
    fetchPullStats();
  }

  Future<void> fetchLeadPools() async {
    isPoolsLoading.value = true;
    try {
      final res = await _leadService.getLeadPools();
      if (!res.status.hasError && res.body != null) {
        final list = (res.body['data'] as List<dynamic>?) ?? [];
        final parsed = list.map((item) => LeadPoolModel.fromJson(item as Map<String, dynamic>)).toList();
        leadPoolsList.assignAll(parsed);
        if (leadPoolsList.isNotEmpty) {
          if (selectedPullPoolId.value.isEmpty || !leadPoolsList.any((p) => p.id == selectedPullPoolId.value)) {
            selectedPullPoolId.value = leadPoolsList.first.id;
          }
        } else {
          selectedPullPoolId.value = '';
        }
        if (selectedFilterPoolId.value.isNotEmpty && !leadPoolsList.any((p) => p.id == selectedFilterPoolId.value)) {
          selectedFilterPoolId.value = '';
        }
      }
    } catch (e) {
      debugPrint('Error loading lead pools: $e');
    } finally {
      isPoolsLoading.value = false;
    }
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
        leadPoolId: selectedFilterPoolId.value.isNotEmpty ? selectedFilterPoolId.value : null,
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

  void updateFilters({String? search, String? stage, String? rmId, String? poolId}) {
    if (search != null) searchQuery.value = search;
    if (stage != null) selectedStage.value = stage;
    if (rmId != null) selectedRMId.value = rmId;
    if (poolId != null) selectedFilterPoolId.value = poolId;
    currentPage.value = 1;
    fetchLeads();
  }

  void resetFilters() {
    searchQuery.value = '';
    selectedStage.value = '';
    selectedRMId.value = '';
    selectedFilterPoolId.value = '';
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
    assignLeadPoolId.value = '';
    leadStage.value = 'New';
  }

  Future<void> saveLead({String? existingId}) async {
    if (phoneController.text.trim().isEmpty) {
      Get.snackbar('Validation Alert', 'Phone Number is required', backgroundColor: Colors.orange.withOpacity(0.1));
      return;
    }

    isLoading.value = true;
    try {
      final data = {
        'fullName': nameController.text.trim(),
        'mobileNumber': phoneController.text.trim(),
        'emailAddress': emailController.text.trim().isEmpty ? null : emailController.text.trim(),
        'assignedRM': assignRMId.value.isEmpty ? null : assignRMId.value,
        if (assignLeadPoolId.value.isNotEmpty) 'leadPoolId': assignLeadPoolId.value,
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
        fetchLeadPools();
        fetchPullStats();
        Get.snackbar('Success', existingId != null ? 'Lead updated successfully' : 'Lead created successfully', backgroundColor: Colors.green.withOpacity(0.1));
      } else {
        Get.snackbar('Error', 'Failed to save lead', backgroundColor: Colors.red.withOpacity(0.1));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateLeadStage(String leadId, String newStage) async {
    isLoading.value = true;
    try {
      final success = await _leadService.updateLead(leadId, {'stage': newStage});
      if (success) {
        fetchLeads();
        Get.snackbar('Success', 'Lead stage updated successfully', backgroundColor: Colors.green.withOpacity(0.1));
      } else {
        Get.snackbar('Error', 'Failed to update lead stage', backgroundColor: Colors.red.withOpacity(0.1));
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
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
      final success = await _leadService.addFollowUp(
        leadId,
        followUpNotesController.text.trim(),
        DateTime.now(),
        followUpType: followUpType.value,
        status: followUpStatus.value,
        nextFollowUpDate: followUpDate.value,
      );
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
        if (!res.status.hasError && res.body != null) {
          final bodyData = res.body['data'];
          Get.dialog(
            ImportWizard(
              importId: bodyData['importId'].toString(),
              sheetNames: List<String>.from(bodyData['sheetNames'] ?? []),
              columnPreview: List<dynamic>.from(bodyData['columnPreview'] ?? []),
              previewRows: List<dynamic>.from(bodyData['previewRows'] ?? []),
              suggestedMapping: Map<String, dynamic>.from(bodyData['suggestedMapping'] ?? {}),
            ),
            barrierDismissible: false,
          );
        } else {
          final msg = res.body?['message'] ?? 'An error occurred during file upload';
          Get.snackbar('Import Failed', msg, backgroundColor: Colors.red.withOpacity(0.1));
        }
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Error', 'Failed to read file: $e', backgroundColor: Colors.red.withOpacity(0.1));
    }
  }

  Future<void> fetchPullStats() async {
    try {
      final poolId = selectedPullPoolId.value.isNotEmpty ? selectedPullPoolId.value : null;
      final res = await _leadService.getPullStats(poolId: poolId);
      if (!res.status.hasError && res.body != null) {
        final data = res.body['data'] as Map<String, dynamic>;
        freshAvailable.value = data['freshAvailable'] as int? ?? 0;
        myFresh.value = data['myFresh'] as int? ?? 0;
        freshMax.value = data['freshMax'] as int? ?? 100;
        myUnread.value = data['myUnread'] as int? ?? 0;
        unreadMax.value = data['unreadMax'] as int? ?? 50;

        if (data['pools'] != null && data['pools'] is List) {
          final poolsList = (data['pools'] as List<dynamic>)
              .map((item) => LeadPoolModel.fromJson(item as Map<String, dynamic>))
              .toList();
          leadPoolsList.assignAll(poolsList);
          if (leadPoolsList.isNotEmpty) {
            if (selectedPullPoolId.value.isEmpty || !leadPoolsList.any((p) => p.id == selectedPullPoolId.value)) {
              selectedPullPoolId.value = leadPoolsList.first.id;
            }
          } else {
            selectedPullPoolId.value = '';
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching pull stats: $e');
    }
  }

  Future<void> pullLeadsFromSelectedPool({String? poolId}) async {
    if (isPulling.value) return;
    isPulling.value = true;
    pullMessage.value = '';
    try {
      final targetPoolId = poolId ?? (selectedPullPoolId.value.isNotEmpty ? selectedPullPoolId.value : null);
      final res = await _leadService.pullLeads('fresh', poolId: targetPoolId);
      if (!res.status.hasError && res.body != null) {
        final data = res.body['data'] as Map<String, dynamic>? ?? {};
        final pulled = data['pulled'] as int? ?? 0;
        final poolName = data['poolName']?.toString() ?? 'Lead Pool';
        final msg = res.body['message']?.toString() ?? (pulled > 0 ? '$pulled lead(s) pulled successfully from $poolName!' : 'No leads pulled.');
        pullMessage.value = msg;
        await fetchPullStats();
        await fetchLeadPools();
        if (pulled > 0) {
          await fetchLeads();
          Get.snackbar(
            'Lead Pool Success',
            msg,
            backgroundColor: const Color(0xFFDCFCE7),
            colorText: const Color(0xFF166534),
            icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.all(16),
            borderRadius: 8,
          );
        } else {
          Get.snackbar(
            'Lead Pool Notice',
            msg,
            backgroundColor: const Color(0xFFFEF3C7),
            colorText: const Color(0xFF92400E),
            icon: const Icon(Icons.info_rounded, color: Color(0xFFD97706)),
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.all(16),
            borderRadius: 8,
          );
        }
      } else {
        final errMsg = res.body?['message']?.toString() ?? 'Failed to pull leads from pool';
        pullMessage.value = errMsg;
        Get.snackbar(
          'Lead Pool Error',
          errMsg,
          backgroundColor: const Color(0xFFFEE2E2),
          colorText: const Color(0xFF991B1B),
          icon: const Icon(Icons.error_rounded, color: Color(0xFFDC2626)),
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        );
      }
    } catch (e) {
      final errorStr = 'Error pulling leads: $e';
      pullMessage.value = errorStr;
      Get.snackbar(
        'Lead Pool Error',
        errorStr,
        backgroundColor: const Color(0xFFFEE2E2),
        colorText: const Color(0xFF991B1B),
        icon: const Icon(Icons.error_rounded, color: Color(0xFFDC2626)),
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    } finally {
      isPulling.value = false;
    }
  }

  Future<void> pullFreshLeads() => pullLeadsFromSelectedPool();

  Future<bool> createCustomLeadPool(
    String name,
    String? description, {
    int pullSize = 20,
    int maxPerStaff = 100,
  }) async {
    try {
      final res = await _leadService.createLeadPool(
        name,
        description,
        pullSize: pullSize,
        maxPerStaff: maxPerStaff,
      );
      if (!res.status.hasError && res.body != null) {
        await fetchLeadPools();
        await fetchPullStats();
        Get.snackbar(
          'Success',
          'Lead pool "$name" created successfully',
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green.shade800,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          res.body?['message'] ?? 'Failed to create lead pool',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to create lead pool: $e', backgroundColor: Colors.red.withOpacity(0.1));
      return false;
    }
  }

  Future<bool> updateCustomLeadPool(String id, Map<String, dynamic> data) async {
    try {
      final res = await _leadService.updateLeadPool(id, data);
      if (!res.status.hasError) {
        await fetchLeadPools();
        await fetchPullStats();
        Get.snackbar(
          'Success',
          'Lead pool updated successfully',
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green.shade800,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          res.body?['message'] ?? 'Failed to update lead pool',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update lead pool: $e', backgroundColor: Colors.red.withOpacity(0.1));
      return false;
    }
  }

  Future<bool> deleteCustomLeadPool(String id) async {
    try {
      final res = await _leadService.deleteLeadPool(id);
      if (!res.status.hasError) {
        if (selectedFilterPoolId.value == id) {
          selectedFilterPoolId.value = '';
        }
        if (selectedPullPoolId.value == id) {
          selectedPullPoolId.value = '';
        }
        await fetchLeadPools();
        await fetchPullStats();
        Get.snackbar(
          'Success',
          'Lead pool deleted successfully',
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green.shade800,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          res.body?['message'] ?? 'Failed to delete lead pool',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete lead pool: $e', backgroundColor: Colors.red.withOpacity(0.1));
      return false;
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

  void toggleLeadSelection(String leadId) {
    if (selectedLeadIds.contains(leadId)) {
      selectedLeadIds.remove(leadId);
    } else {
      selectedLeadIds.add(leadId);
    }
  }

  void toggleAllLeads(List<LeadModel> visibleLeads) {
    final allSelected = visibleLeads.every((l) => selectedLeadIds.contains(l.id));
    if (allSelected) {
      for (var l in visibleLeads) {
        selectedLeadIds.remove(l.id);
      }
    } else {
      for (var l in visibleLeads) {
        if (!selectedLeadIds.contains(l.id)) {
          selectedLeadIds.add(l.id);
        }
      }
    }
  }

  Future<void> bulkAssignRM(String? staffId) async {
    if (selectedLeadIds.isEmpty) return;
    isLoading.value = true;
    try {
      final res = await _leadService.bulkAssignLeads(selectedLeadIds.toList(), staffId);
      if (!res.status.hasError) {
        Get.snackbar('Success', 'Leads assigned successfully',
            backgroundColor: Colors.green.withOpacity(0.1), colorText: Colors.green.shade800);
        selectedLeadIds.clear();
        fetchLeads();
      } else {
        Get.snackbar('Error', res.body?['message'] ?? 'Failed to assign leads',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to assign leads: $e', backgroundColor: Colors.red.withOpacity(0.1));
    } finally {
      isLoading.value = false;
    }
  }
}
