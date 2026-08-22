import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/permission_group.model.dart';
import '../../models/role.model.dart';
import '../../services/role_permission.service.dart';

class RolePermissionController extends GetxController {
  final _service = Get.put(RolePermissionService());

  var isLoading = false.obs;
  var roles = <RoleModel>[].obs;
  var permissionGroups = <PermissionGroupModel>[].obs;
  var activeTab = 0.obs; // 0 = Roles, 1 = Permission Groups

  final List<String> availableFeatures = [
    'Leads',
    'Reports',
    'Users',
    'Staff',
    'KYC',
    'Payments',
    'Notifications',
    'Settings'
  ];

  final List<String> availableActions = [];

  List<String> getFeatureActions(String feature) {
    switch (feature) {
      case 'Leads':
        return [
          'leads.create',
          'leads.create_pool',
          'leads.bulk_upload',
          'leads.view_all',
          'leads.view_assigned',
          'leads.view_pools',
          'leads.view_import_status',
          'leads.update_all',
          'leads.update_assigned',
          'leads.bulk_assign',
          'leads.follow_up_all',
          'leads.follow_up_assigned',
          'leads.pull',
          'leads.view_pull_stats'
        ];
      case 'Reports':
        return [
          'reports.create',
          'reports.view',
          'reports.update',
          'reports.change_public_status',
          'reports.delete'
        ];
      case 'Users':
        return [
          'users.create',
          'users.view',
          'users.view_assigned',
          'users.update',
          'users.suspend_activate',
          'users.generate_temp_pin',
          'users.delete'
        ];
      case 'Staff':
        return [
          'staff.create',
          'staff.view',
          'staff.update',
          'staff.reset',
          'staff.assignment',
          'staff.delete',
          'staff.upload_video',
          'staff.upload_document',
          'staff.view_applicants',
          'staff.approve_applicant'
        ];
      case 'KYC':
        return [
          'kyc.view',
          'kyc.download_document',
          'kyc.change_status',
          'kyc.update_gate_status',
          'kyc.update_file'
        ];
      case 'Payments':
        return [
          'payments.view_pending',
          'payments.bypass'
        ];
      case 'Notifications':
        return [
          'notifications.view',
          'notifications.send',
          'notifications.send_bulk_email',
          'notifications.preview',
          'notifications.view_scheduled',
          'notifications.cancel_scheduled'
        ];
      case 'Settings':
        return [
          'settings.view',
          'settings.update',
          'settings.upload_payment_qr'
        ];
      default:
        return [];
    }
  }

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  Future<void> refreshAll() async {
    isLoading.value = true;
    try {
      await Future.wait([
        fetchRoles(),
        fetchPermissionGroups(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchRoles() async {
    final response = await _service.getRoles();
    if (!response.status.hasError && response.body != null) {
      final list = (response.body['data'] as List? ?? [])
          .map((item) => RoleModel.fromJson(item))
          .toList();
      roles.assignAll(list);
    }
  }

  Future<void> fetchPermissionGroups() async {
    final response = await _service.getPermissionGroups();
    if (!response.status.hasError && response.body != null) {
      final list = (response.body['data'] as List? ?? [])
          .map((item) => PermissionGroupModel.fromJson(item))
          .toList();
      permissionGroups.assignAll(list);
    }
  }

  // CREATE / UPDATE Role
  Future<bool> saveRole({
    String? id,
    required String name,
    String? description,
    required List<String> groupIds,
  }) async {
    isLoading.value = true;
    try {
      final data = {
        'name': name,
        'description': description,
        'permissionGroups': groupIds,
      };

      final Response response;
      if (id == null) {
        response = await _service.createRole(data);
      } else {
        response = await _service.updateRole(id, data);
      }

      if (response.status.hasError) {
        final msg = response.body?['message'] ?? 'Error saving role';
        Get.snackbar('Error', msg, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.withOpacity(0.1));
        return false;
      }

      Get.snackbar('Success', 'Role saved successfully', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.withOpacity(0.1));
      await fetchRoles();
      return true;
    } finally {
      isLoading.value = false;
    }
  }

  // DELETE Role
  Future<void> deleteRole(String id) async {
    isLoading.value = true;
    try {
      final response = await _service.deleteRole(id);
      if (response.status.hasError) {
        final msg = response.body?['message'] ?? 'Error deleting role';
        Get.snackbar('Error', msg, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.withOpacity(0.1));
      } else {
        Get.snackbar('Success', 'Role deleted successfully', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.withOpacity(0.1));
        await fetchRoles();
      }
    } finally {
      isLoading.value = false;
    }
  }

  // CREATE / UPDATE Permission Group
  Future<bool> savePermissionGroup({
    String? id,
    required String name,
    String? description,
    required List<PermissionItem> permissions,
  }) async {
    isLoading.value = true;
    try {
      final data = {
        'name': name,
        'description': description,
        'permissions': permissions.map((p) => p.toJson()).toList(),
      };

      final Response response;
      if (id == null) {
        response = await _service.createPermissionGroup(data);
      } else {
        response = await _service.updatePermissionGroup(id, data);
      }

      if (response.status.hasError) {
        final msg = response.body?['message'] ?? 'Error saving permission group';
        Get.snackbar('Error', msg, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.withOpacity(0.1));
        return false;
      }

      Get.snackbar('Success', 'Permission group saved successfully', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.withOpacity(0.1));
      await fetchPermissionGroups();
      return true;
    } finally {
      isLoading.value = false;
    }
  }

  // DELETE Permission Group
  Future<void> deletePermissionGroup(String id) async {
    isLoading.value = true;
    try {
      final response = await _service.deletePermissionGroup(id);
      if (response.status.hasError) {
        final msg = response.body?['message'] ?? 'Error deleting group';
        Get.snackbar('Error', msg, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.withOpacity(0.1));
      } else {
        Get.snackbar('Success', 'Permission group deleted successfully', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.withOpacity(0.1));
        await fetchPermissionGroups();
      }
    } finally {
      isLoading.value = false;
    }
  }
}
