import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/staff.model.dart';
import '../../services/staff.service.dart';
import '../auth/auth.controller.dart';

class StaffProfileController extends GetxController {
  final StaffService _service = Get.put(StaffService());

  var isLoading = false.obs;
  var isUpdating = false.obs;
  var isChangingMpin = false.obs;

  var profile = Rxn<StaffModel>();

  // Personal Info Form Controllers
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final localAddressController = TextEditingController();
  final permanentAddressController = TextEditingController();
  final emergencyNameController = TextEditingController();
  final emergencyRelationController = TextEditingController();
  final emergencyPhoneController = TextEditingController();
  final gender = ''.obs;
  final dob = Rxn<DateTime>();

  // MPIN Form Controllers
  final oldMpinController = TextEditingController();
  final newMpinController = TextEditingController();
  final confirmMpinController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    localAddressController.dispose();
    permanentAddressController.dispose();
    emergencyNameController.dispose();
    emergencyRelationController.dispose();
    emergencyPhoneController.dispose();
    oldMpinController.dispose();
    newMpinController.dispose();
    confirmMpinController.dispose();
    super.onClose();
  }

  Future<void> fetchProfile() async {
    isLoading.value = true;
    try {
      final data = await _service.getStaffProfileMe();
      if (data != null) {
        profile.value = data;
        _populateFields(data);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load profile details: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade900,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _populateFields(StaffModel staff) {
    fullNameController.text = staff.name;
    emailController.text = staff.email;
    mobileController.text = staff.mobile;
    localAddressController.text = staff.localAddress ?? '';
    permanentAddressController.text = staff.permanentAddress ?? '';
    gender.value = staff.gender ?? '';
    if (staff.dob != null && staff.dob!.isNotEmpty) {
      dob.value = DateTime.tryParse(staff.dob!);
    }
    if (staff.emergencyContact != null) {
      emergencyNameController.text = staff.emergencyContact!.name;
      emergencyRelationController.text = staff.emergencyContact!.relation;
      emergencyPhoneController.text = staff.emergencyContact!.phone;
    }
  }

  Future<void> saveProfile() async {
    final name = fullNameController.text.trim();
    final email = emailController.text.trim();
    final mobile = mobileController.text.trim();

    if (name.isEmpty) {
      Get.snackbar('Validation', 'Full Name is required', backgroundColor: Colors.amber.shade50);
      return;
    }
    if (email.isEmpty) {
      Get.snackbar('Validation', 'Email Address is required', backgroundColor: Colors.amber.shade50);
      return;
    }
    if (mobile.isEmpty) {
      Get.snackbar('Validation', 'Mobile Number is required', backgroundColor: Colors.amber.shade50);
      return;
    }

    isUpdating.value = true;
    try {
      final payload = {
        'fullName': name,
        'emailAddress': email,
        'mobileNumber': mobile,
        'localAddress': localAddressController.text.trim(),
        'permanentAddress': permanentAddressController.text.trim(),
        'gender': gender.value,
        if (dob.value != null) 'dob': dob.value!.toIso8601String(),
        'emergencyContact': {
          'name': emergencyNameController.text.trim(),
          'relation': emergencyRelationController.text.trim(),
          'phone': emergencyPhoneController.text.trim(),
        },
      };

      final updated = await _service.updateStaffProfileMe(payload);
      if (updated != null) {
        profile.value = updated;
        _populateFields(updated);
        // Refresh AuthController state
        if (Get.isRegistered<AuthController>()) {
          Get.find<AuthController>().checkAuth();
        }
        Get.snackbar(
          'Success',
          'Your profile has been successfully updated!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade900,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Update Failed',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade900,
      );
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> changeMpin() async {
    final oldPin = oldMpinController.text.trim();
    final newPin = newMpinController.text.trim();
    final confirmPin = confirmMpinController.text.trim();

    if (newPin.length < 4 || newPin.length > 6) {
      Get.snackbar('Validation', 'New MPIN must be 4 to 6 digits', backgroundColor: Colors.amber.shade50);
      return;
    }
    if (newPin != confirmPin) {
      Get.snackbar('Validation', 'New MPIN and confirmation do not match', backgroundColor: Colors.amber.shade50);
      return;
    }

    isChangingMpin.value = true;
    try {
      final success = await _service.changeStaffMpinMe(oldPin, newPin);
      if (success) {
        oldMpinController.clear();
        newMpinController.clear();
        confirmMpinController.clear();
        Get.snackbar(
          'MPIN Updated',
          'Your login MPIN has been updated successfully. Use this new MPIN for your next login.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade900,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Change MPIN Failed',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade900,
      );
    } finally {
      isChangingMpin.value = false;
    }
  }
}
