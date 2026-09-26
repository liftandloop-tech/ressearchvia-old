import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/department.model.dart';
import '../../models/permission_group.model.dart';
import '../../models/role.model.dart';
import '../../services/role_permission.service.dart';

class RolePermissionController extends GetxController {
  final _service = Get.put(RolePermissionService());

  var isLoading = false.obs;
  var departments = <DepartmentModel>[].obs;
  var availableDepartmentPages = <Map<String, dynamic>>[].obs;
  var roles = <RoleModel>[].obs;
  var permissionGroups = <PermissionGroupModel>[].obs;
  var activeTab = 0.obs; // 0 = Roles, 1 = Permission Groups, 2 = Departments

  final List<String> availableFeatures = [
    'Leads',
    'Users',
    'Subscriptions',
    'Payments',
    'KYC',
    'Reports',
    'Staff',
    'Notifications',
    'Settings',
  ];

  final List<String> availableActions = [];

  List<String> getFeatureActions(String feature) {
    switch (feature) {
      case 'Leads':
        return [
          'leads.view',
          'leads.create',
          'leads.update',
          'leads.follow_up',
          'leads.bulk_upload',
          'leads.bulk_assign',
          'leads.pull',
          'leads.view_pools',
        ];
      case 'Users':
        return [
          'users.view',
          'users.create',
          'users.update',
          'users.suspend_activate',
          'users.generate_temp_pin',
          'users.delete',
        ];
      case 'Subscriptions':
        return [
          'subscriptions.view',
          'subscriptions.activate',
          'subscriptions.suspend',
          'subscriptions.revoke',
          'subscriptions.manage_segments',
          'subscriptions.edit_correction',
          'subscriptions.refund',
        ];
      case 'Payments':
        return [
          'payments.view_pending',
          'payments.approve',
          'payments.reject',
          'payments.export',
        ];
      case 'KYC':
        return [
          'kyc.view',
          'kyc.download_document',
          'kyc.change_status',
          'kyc.update_gate_status',
          'kyc.update_file',
        ];
      case 'Reports':
        return [
          'reports.view',
          'reports.create',
          'reports.update',
          'reports.change_public_status',
          'reports.delete',
          'reports.trading_call_popup',
        ];
      case 'Staff':
        return [
          'staff.view',
          'staff.create',
          'staff.update',
          'staff.reset_mpin',
          'staff.assignment',
          'staff.delete',
          'staff.view_applicants',
          'staff.approve_applicant',
        ];
      case 'Notifications':
        return [
          'notifications.view',
          'notifications.send',
          'notifications.send_bulk_email',
          'notifications.preview',
          'notifications.cancel_scheduled',
        ];
      case 'Settings':
        return [
          'settings.view',
          'settings.update',
          'settings.upload_payment_qr',
        ];
      default:
        return [];
    }
  }

  String formatActionLabel(String action) {
    const labels = {
      // Leads
      'leads.view': 'View Leads',
      'leads.create': 'Create Lead',
      'leads.update': 'Edit Lead',
      'leads.follow_up': 'Log Follow-up',
      'leads.bulk_upload': 'Bulk Upload',
      'leads.bulk_assign': 'Bulk Assign',
      'leads.pull': 'Pull Fresh Leads',
      'leads.view_pools': 'Lead Pools',

      // Users
      'users.view': 'View Clients',
      'users.create': 'Create Client',
      'users.update': 'Edit Client',
      'users.suspend_activate': 'Suspend/Activate',
      'users.generate_temp_pin': 'Temp PIN',
      'users.delete': 'Delete Client',

      // Subscriptions
      'subscriptions.view': 'View Subscriptions',
      'subscriptions.activate': 'Activate / Top-Up',
      'subscriptions.suspend': 'Suspend Subscription',
      'subscriptions.revoke': 'Revoke Subscription',
      'subscriptions.manage_segments': 'Manage Segments',
      'subscriptions.edit_correction': 'Edit Plan/Dates',
      'subscriptions.refund': 'Process Refund',

      // Payments
      'payments.view_pending': 'View Payments',
      'payments.approve': 'Approve Payment',
      'payments.reject': 'Reject Payment',
      'payments.export': 'Export Excel',

      // KYC
      'kyc.view': 'View KYC',
      'kyc.download_document': 'Download KYC Doc',
      'kyc.change_status': 'Approve/Reject KYC',
      'kyc.update_gate_status': 'Gate Status',
      'kyc.update_file': 'Update KYC File',

      // Reports
      'reports.view': 'View Reports',
      'reports.create': 'Upload Report',
      'reports.update': 'Edit Report',
      'reports.change_public_status': 'Publish/Unpublish',
      'reports.delete': 'Delete Report',
      'reports.trading_call_popup': 'Trading Call Popup Alert',

      // Staff
      'staff.view': 'View Staff',
      'staff.create': 'Add Staff',
      'staff.update': 'Edit Staff',
      'staff.reset_mpin': 'Reset MPIN',
      'staff.assignment': 'Reassign Clients',
      'staff.delete': 'Delete Staff',
      'staff.view_applicants': 'View Applicants',
      'staff.approve_applicant': 'Approve Applicant',

      // Notifications
      'notifications.view': 'View Notifications',
      'notifications.send': 'Send Notification',
      'notifications.send_bulk_email': 'Send Bulk Email',
      'notifications.preview': 'Preview Email',
      'notifications.cancel_scheduled': 'Cancel Scheduled',

      // Settings
      'settings.view': 'View Settings',
      'settings.update': 'Update Settings',
      'settings.upload_payment_qr': 'Upload Payment QR',
    };

    if (labels.containsKey(action)) return labels[action]!;
    if (action.contains('.')) {
      return action.split('.').last.replaceAll('_', ' ').capitalizeFirst ?? action;
    }
    return action;
  }

  String formatActionDescription(String action) {
    const descriptions = {
      // Leads
      'leads.view': 'Allows staff to list and view sales leads assigned to them.',
      'leads.create': 'Allows staff to manually create and add new sales leads.',
      'leads.update': 'Allows staff to edit lead contact info, requirements, and status.',
      'leads.follow_up': 'Allows staff to record follow-up logs, notes, and call outcomes.',
      'leads.bulk_upload': 'Allows staff to import large lead batches via CSV or Excel.',
      'leads.bulk_assign': 'Allows staff to distribute and reassign leads across team members.',
      'leads.pull': 'Allows staff to pull fresh unassigned leads from the lead pool.',
      'leads.view_pools': 'Allows staff to create and manage lead distribution pools.',

      // Users
      'users.view': 'Allows staff to view registered clients and their profile details.',
      'users.create': 'Allows staff to provision and register new client accounts.',
      'users.update': 'Allows staff to edit client personal details, contact info, and bank records.',
      'users.suspend_activate': 'Allows staff to temporarily suspend or re-activate client accounts.',
      'users.generate_temp_pin': 'Allows staff to generate temporary login PINs for client access.',
      'users.delete': 'Allows staff to permanently delete client accounts from the system.',

      // Subscriptions
      'subscriptions.view': 'Allows staff to view client subscription history and active plans.',
      'subscriptions.activate': 'Allows staff to activate new plans and add top-up amounts.',
      'subscriptions.suspend': 'Allows staff to suspend an active client subscription.',
      'subscriptions.revoke': 'Allows staff to prematurely revoke an active client subscription.',
      'subscriptions.manage_segments': 'Allows staff to allocate or customize segments for client plans.',
      'subscriptions.edit_correction': 'Allows staff to correct plan pricing, start/expiry dates, or details.',
      'subscriptions.refund': 'Allows staff to calculate and issue subscription refunds.',

      // Payments
      'payments.view_pending': 'Allows staff to inspect pending bank transfer receipts and records.',
      'payments.approve': 'Allows staff to verify and approve bank transfer payments.',
      'payments.reject': 'Allows staff to reject invalid or unverified bank transfer payments.',
      'payments.export': 'Allows staff to export payment ledgers and receipts to Excel.',

      // KYC
      'kyc.view': 'Allows staff to review client KYC submission records and details.',
      'kyc.download_document': 'Allows staff to download and inspect client PAN & Aadhaar files.',
      'kyc.change_status': 'Allows staff to approve or reject client KYC verification submissions.',
      'kyc.update_gate_status': 'Allows staff to modify client verification gate requirements.',
      'kyc.update_file': 'Allows staff to replace or re-upload client KYC documents.',

      // Reports
      'reports.view': 'Allows staff to browse all published and draft research reports.',
      'reports.create': 'Allows staff to author and upload new research advisory reports.',
      'reports.update': 'Allows staff to edit existing report content and post live updates.',
      'reports.change_public_status': 'Allows staff to publish or unpublish reports for clients.',
      'reports.delete': 'Allows staff to permanently delete research reports.',
      'reports.trading_call_popup': 'Enables real-time popup alerts on the staff panel whenever a new trading call is published.',

      // Staff
      'staff.view': 'Allows staff to view the employee directory and staff profiles.',
      'staff.create': 'Allows staff to onboard and create new employee records.',
      'staff.update': 'Allows staff to edit employee details, roles, or departments.',
      'staff.reset_mpin': 'Allows staff to reset login credentials/MPIN for employees.',
      'staff.assignment': 'Allows staff to reassign client portfolios between employees.',
      'staff.delete': 'Allows staff to deactivate or remove employee accounts.',
      'staff.view_applicants': 'Allows staff to view onboarding recruitment applicant queues.',
      'staff.approve_applicant': 'Allows staff to approve and transition applicants into employees.',

      // Notifications
      'notifications.view': 'Allows staff to view sent notification history and delivery logs.',
      'notifications.send': 'Allows staff to compose and dispatch mobile push notifications.',
      'notifications.send_bulk_email': 'Allows staff to send bulk email campaigns to clients.',
      'notifications.preview': 'Allows staff to preview HTML email templates before sending.',
      'notifications.cancel_scheduled': 'Allows staff to cancel pending scheduled notification alerts.',

      // Settings
      'settings.view': 'Allows staff to view company settings and system policies.',
      'settings.update': 'Allows staff to modify and save system configurations.',
      'settings.upload_payment_qr': 'Allows staff to upload and crop official company payment QR codes.',
    };

    if (descriptions.containsKey(action)) return descriptions[action]!;
    return 'Enables the ${formatActionLabel(action)} permission for this role.';
  }

  /// Returns only the features available for the selected department.
  /// If no department is selected, returns an empty list to prompt selection.
  /// If the department is Global, returns all features.
  List<String> getFeaturesForDepartment(String? departmentId) {
    if (departmentId == null || departmentId.isEmpty) {
      return [];
    }

    final dept = departments.firstWhereOrNull((d) => d.id == departmentId);
    if (dept == null) return [];

    if (dept.isGlobal) {
      return List<String>.from(availableFeatures);
    }

    // Filter availableFeatures where department.assignedPages contains the feature key
    final assigned = dept.assignedPages.map((p) => p.toLowerCase()).toSet();
    return availableFeatures.where((feat) {
      return assigned.contains(feat.toLowerCase());
    }).toList();
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
        fetchDepartments(),
        fetchDepartmentPages(),
        fetchRoles(),
        fetchPermissionGroups(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchDepartments() async {
    final response = await _service.getDepartments();
    if (!response.status.hasError && response.body != null) {
      final list = (response.body['data'] as List? ?? [])
          .map((item) => DepartmentModel.fromJson(item))
          .toList();
      departments.assignAll(list);
    }
  }

  Future<void> fetchDepartmentPages() async {
    final response = await _service.getDepartmentPages();
    if (!response.status.hasError && response.body != null) {
      final list = (response.body['data'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      availableDepartmentPages.assignAll(list);
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

  // CREATE / UPDATE Department
  Future<bool> saveDepartment({
    String? id,
    required String name,
    String? code,
    String? description,
    required List<String> assignedPages,
    bool isGlobal = false,
  }) async {
    isLoading.value = true;
    try {
      final data = {
        'name': name.trim(),
        if (code != null && code.trim().isNotEmpty) 'code': code.trim().toUpperCase(),
        'description': description?.trim(),
        'assignedPages': assignedPages,
        'isGlobal': isGlobal,
      };

      final Response response;
      if (id == null) {
        response = await _service.createDepartment(data);
      } else {
        response = await _service.updateDepartment(id, data);
      }

      if (response.status.hasError) {
        final msg = response.body?['message'] ?? 'Error saving department';
        Get.snackbar('Error', msg, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.withOpacity(0.1));
        return false;
      }

      Get.snackbar('Success', 'Department saved successfully', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.withOpacity(0.1));
      await fetchDepartments();
      return true;
    } finally {
      isLoading.value = false;
    }
  }

  // DELETE Department
  Future<void> deleteDepartment(String id) async {
    isLoading.value = true;
    try {
      final response = await _service.deleteDepartment(id);
      if (response.status.hasError) {
        final msg = response.body?['message'] ?? 'Error deleting department';
        Get.snackbar('Error', msg, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.withOpacity(0.1));
      } else {
        Get.snackbar('Success', 'Department deleted successfully', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.withOpacity(0.1));
        await fetchDepartments();
      }
    } finally {
      isLoading.value = false;
    }
  }

  // CREATE / UPDATE Role
  Future<bool> saveRole({
    String? id,
    required String name,
    String? code,
    int level = 1,
    String? description,
    String? departmentId,
    required List<String> groupIds,
  }) async {
    isLoading.value = true;
    try {
      final data = {
        'name': name,
        if (code != null && code.trim().isNotEmpty) 'code': code.trim().toUpperCase(),
        'level': level,
        'description': description,
        if (departmentId != null && departmentId.isNotEmpty) 'departmentId': departmentId,
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
    String? departmentId,
    required List<PermissionItem> permissions,
  }) async {
    isLoading.value = true;
    try {
      final data = {
        'name': name,
        'description': description,
        if (departmentId != null && departmentId.isNotEmpty) 'departmentId': departmentId,
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
