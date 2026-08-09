import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:spresearch_web/models/user_details.model.dart';
import 'package:spresearch_web/services/user_details.service.dart';
import 'package:spresearch_web/services/user.service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';

class UserDetailsController extends GetxController {
  late final UserDetailsService _service;
  late final UserService _userService;

  @override
  void onInit() {
    _service = Get.find<UserDetailsService>();
    _userService = Get.find<UserService>();
    super.onInit();
  }

  final Rx<UserDetailsModel?> userDetails = Rx<UserDetailsModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  String? _currentUserId;

  Future<void> fetchUserDetails(String userId, {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _currentUserId == userId &&
        (isLoading.value || userDetails.value != null)) return;
    _currentUserId = userId;

    try {
      isLoading.value = true;
      error.value = '';

      final details = await _service.getUserDetails(userId, forceRefresh: forceRefresh);

      if (details != null) {
        userDetails.value = details;
      } else {
        error.value = 'Failed to load user details';
      }
    } catch (e) {
      error.value = 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // UserService initialized in onInit

  Future<void> updateKycStatus(String status) async {
    if (userDetails.value == null) return;

    try {
      isLoading.value = true;
      final userId = userDetails.value!.id;
      final success = await _userService.updateUser(userId, {
        'kycStatus': status,
      });

      if (success) {
        await fetchUserDetails(userId, forceRefresh: true);
        Get.snackbar('Success', 'KYC Status updated to $status');
      } else {
        Get.snackbar('Error', 'Failed to update KYC Status');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _updateGateStatus(String gate, String status) async {
    if (userDetails.value == null) return;

    String? reason;
    if (status == 'REJECTED') {
      final reasonController = TextEditingController();
      final didConfirm = await Get.defaultDialog<bool>(
        title: 'Reject ${gate.toUpperCase()}',
        content: Column(
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. PAN card is blurry',
              ),
              maxLines: 3,
            ),
          ],
        ),
        textConfirm: 'Reject',
        textCancel: 'Cancel',
        confirmTextColor: Colors.white,
        onConfirm: () {
          if (reasonController.text.trim().isEmpty) {
            Get.snackbar('Error', 'Reason is required to reject.');
            return;
          }
          Get.back(result: true);
        },
      );

      if (didConfirm != true) {
        return; // User cancelled
      }
      reason = reasonController.text.trim();
    }

    try {
      isLoading.value = true;
      final userId = userDetails.value!.id;
      final success = await _service.updateKycGateStatus(
        userId,
        gate,
        status,
        reason: reason,
      );

      if (success) {
        await fetchUserDetails(userId, forceRefresh: true);
        Get.snackbar('Success', 'Gate $gate updated to $status');
      } else {
        Get.snackbar('Error', 'Failed to update $gate status');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateDocumentGateStatus(String status) =>
      _updateGateStatus('documents', status);
  Future<void> updateEsignGateStatus(String status) =>
      _updateGateStatus('esign', status);
  Future<void> updateVideoGateStatus(String status) =>
      _updateGateStatus('video', status);

  // --- Personal Info Editing ---
  final RxBool isEditingPersonal = false.obs;
  final firstNameController = TextEditingController(); // Actually Full Name
  final fatherNameController = TextEditingController();
  final dobController = TextEditingController();
  final genderController = TextEditingController();

  void startEditingPersonal() {
    if (userDetails.value == null) return;
    final u = userDetails.value!;
    firstNameController.text = u.displayName;
    fatherNameController.text = u.userObject?.appFName ?? '';
    dobController.text = u.userObject?.appDobDt ?? '';
    genderController.text = u.userObject?.appGen ?? ''; // Raw value for editing
    isEditingPersonal.value = true;
  }

  void cancelEditingPersonal() {
    isEditingPersonal.value = false;
  }

  Future<void> savePersonalDetails() async {
    if (userDetails.value == null) return;
    try {
      isLoading.value = true;
      final userId = userDetails.value!.id;
      final data = {
        'fullName': firstNameController.text,
        'fatherName': fatherNameController.text,
        'dob': dobController.text,
        'gender': genderController.text,
      };

      final success = await _userService.updateUser(userId, data);

      if (success) {
        await fetchUserDetails(userId, forceRefresh: true);
        isEditingPersonal.value = false;
        Get.snackbar('Success', 'Personal details updated');
      } else {
        Get.snackbar('Error', 'Failed to update personal details');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // --- Contact Info Editing ---
  final RxBool isEditingContact = false.obs;
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController =
      TextEditingController(); // Simplified for now or map to fields
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();
  final gstinController = TextEditingController();
  final firmNameController = TextEditingController();

  void startEditingContact() {
    if (userDetails.value == null) return;
    final u = userDetails.value!;
    phoneController.text = u.phone;
    emailController.text = u.email;

    // Address fields
    addressController.text = u.userObject?.appCorAdd1 ?? '';
    cityController.text = u.userObject?.appCorCity ?? '';
    stateController.text = u.userObject?.appCorState ?? '';
    pincodeController.text = u.userObject?.appCorPincd ?? '';
    gstinController.text = u.gstin ?? '';
    firmNameController.text = u.firmName ?? '';

    isEditingContact.value = true;
  }

  void cancelEditingContact() {
    isEditingContact.value = false;
  }

  Future<void> saveContactDetails() async {
    if (userDetails.value == null) return;
    final gstin = gstinController.text.trim();
    final firmName = firmNameController.text.trim();

    if ((gstin.isNotEmpty && firmName.isEmpty) || (gstin.isEmpty && firmName.isNotEmpty)) {
      Get.snackbar('Error', 'Both Firm Name and GSTIN must be filled, or both kept empty.');
      return;
    }

    if (gstin.isNotEmpty) {
      final gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$');
      if (!gstRegex.hasMatch(gstin)) {
        Get.snackbar('Error', 'Invalid GSTIN format');
        return;
      }
    }

    try {
      isLoading.value = true;
      final userId = userDetails.value!.id;
      final data = {
        'phone': phoneController.text,
        'email': emailController.text,
        'address1': addressController.text,
        'city': cityController.text,
        'state': stateController.text,
        'pincode': pincodeController.text,
        'gstin': gstin,
        'firmName': firmName,
      };

      final success = await _userService.updateUser(userId, data);

      if (success) {
        await fetchUserDetails(userId, forceRefresh: true);
        isEditingContact.value = false;
        Get.snackbar('Success', 'Contact details updated');
      } else {
        Get.snackbar('Error', 'Failed to update contact details');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> suspendUser(String reason) async {
    if (userDetails.value == null) return;
    try {
      isLoading.value = true;
      final userId = userDetails.value!.id;
      final success = await _userService.suspendUser(userId, reason: reason);
      if (success) {
        await fetchUserDetails(userId, forceRefresh: true);
        Get.snackbar('Success', 'User account suspended');
      } else {
        Get.snackbar('Error', 'Failed to suspend user account');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> activateUser() async {
    if (userDetails.value == null) return;
    try {
      isLoading.value = true;
      final userId = userDetails.value!.id;
      final success = await _userService.activateUser(userId);
      if (success) {
        await fetchUserDetails(userId, forceRefresh: true);
        Get.snackbar('Success', 'User account activated');
      } else {
        Get.snackbar('Error', 'Failed to activate user account');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateDocument(String docType) async {
    if (userDetails.value == null) return;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: docType == 'video' ? FileType.video : FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        isLoading.value = true;
        final fileParams = result.files.first;
        final userId = userDetails.value!.id;

        if (fileParams.bytes != null) {
          final success = await _userService.updateKycDocument(
            userId,
            docType,
            fileParams.bytes!,
            fileParams.name,
          );

          if (success) {
            await fetchUserDetails(userId, forceRefresh: true);
            Get.snackbar('Success', 'Document updated successfully');
          } else {
            Get.snackbar('Error', 'Failed to update document');
          }
        } else {
          Get.snackbar('Error', 'Could not read file data. Please try again.');
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> viewServiceAgreement() async {
    final docId = userDetails.value?.digioDocumentId;
    if (docId == null || docId.isEmpty) {
      Get.snackbar('Error', 'Service agreement not available for this user');
      return;
    }

    try {
      isLoading.value = true;
      final bytes = await _service.downloadDigioDocument(docId);

      if (bytes != null) {
        await Printing.layoutPdf(
          onLayout: (format) async => bytes,
          name: 'Service_Agreement_$docId.pdf',
        );
      } else {
        Get.snackbar('Error', 'Failed to download service agreement');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> generateTempPin() async {
    if (userDetails.value == null) return;
    try {
      isLoading.value = true;
      final userId = userDetails.value!.id;
      final pin = await _userService.generateTempPin(userId);

      if (pin != null) {
        Get.dialog(
          AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.security, color: Colors.amber),
                SizedBox(width: 8),
                Text('One-Time Temporary PIN'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Share this PIN with the user. It will allow a one-time login and expire immediately after use.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Text(
                    pin,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Note: This PIN does NOT change the user\'s permanent MPIN.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } else {
        Get.snackbar('Error', 'Failed to generate temporary PIN');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    firstNameController.dispose();
    fatherNameController.dispose();
    dobController.dispose();
    genderController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    gstinController.dispose();
    firmNameController.dispose();
    super.onClose();
  }
} // End of Controller
