import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/services/user_details.service.dart';
import 'package:spresearch_web/controllers/users/users_navigation.controller.dart';
import 'package:spresearch_web/controllers/users/user_details.controller.dart';

class EditProfileController extends GetxController {
  final UserDetailsService _service = Get.put(UserDetailsService());
  final formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final fatherNameController = TextEditingController();
  final dobController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final pincodeController = TextEditingController();

  final selectedGender = 'Male'.obs;
  final selectedState = 'California'.obs;
  final isLoadingDetails = false.obs;
  final isSaving = false.obs;
  final fullNameDisplay = 'U'.obs;
  String? _currentUserId;

  Future<void> fetchUserDetails(String userId) async {
    if (_currentUserId == userId &&
        (isLoadingDetails.value || fullNameController.text.isNotEmpty)) return;
    _currentUserId = userId;

    try {
      isLoadingDetails.value = true;

      final details = await _service.getUserDetails(userId);

      if (details != null) {
        // Populate form with user data
        fullNameController.text = details.displayName;
        fullNameDisplay.value = details.displayName.isNotEmpty
            ? details.displayName[0].toUpperCase()
            : 'U';
        fatherNameController.text = details.userObject?.appFName ?? '';
        dobController.text = details.userObject?.appDobDt ?? '';

        // Set gender
        if (details.userObject?.appGen == 'M') {
          selectedGender.value = 'Male';
        } else if (details.userObject?.appGen == 'F') {
          selectedGender.value = 'Female';
        } else {
          selectedGender.value = 'Male';
        }

        // Format and set mobile
        String phoneStr = details.phone;
        if (phoneStr.startsWith('91') && phoneStr.length > 10) {
          phoneStr = phoneStr.substring(2);
        }
        mobileController.text = phoneStr;

        emailController.text = details.userObject?.appEmail ?? '';
        addressController.text = details.userObject?.appCorAdd1 ?? '';
        pincodeController.text = details.userObject?.appCorPincd ?? '';

        // Set state safely
        const validStates = [
          'Andhra Pradesh',
          'Arunachal Pradesh',
          'Assam',
          'Bihar',
          'Chhattisgarh',
          'Goa',
          'Gujarat',
          'Haryana',
          'Himachal Pradesh',
          'Jharkhand',
          'Karnataka',
          'Kerala',
          'Madhya Pradesh',
          'Maharashtra',
          'Manipur',
          'Meghalaya',
          'Mizoram',
          'Nagaland',
          'Odisha',
          'Punjab',
          'Rajasthan',
          'Sikkim',
          'Tamil Nadu',
          'Telangana',
          'Tripura',
          'Uttar Pradesh',
          'Uttarakhand',
          'West Bengal',
        ];

        final userState = details.userObject?.appCorState ?? '';
        if (validStates.contains(userState)) {
          selectedState.value = userState;
        } else {
          selectedState.value =
              'Madhya Pradesh'; // Default to a relevant state if not found
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load user details: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingDetails.value = false;
    }
  }

  Future<void> saveProfile(String userId) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      isSaving.value = true;

      // Call update API
      final response = await _service.updateUser(
        userId,
        fullName: fullNameController.text,
        phone: mobileController.text.replaceAll(RegExp(r'[^\d]'), ''),
        email: emailController.text,
        fatherName: fatherNameController.text,
        dob: dobController.text,
        gender: selectedGender.value,
        address: addressController.text,
        pincode: pincodeController.text,
        state: selectedState.value,
      );

      if (response) {
        Get.snackbar(
          'Success',
          'Profile updated successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Refresh UserDetails if controller is active (assuming it exists in this version too)
        // Note: The UserDetailsController is usually what shows the info on the details page.
        // We'll try to find it and refresh.
        // Refresh UserDetails if controller is active (Real-time update)
        if (Get.isRegistered<UserDetailsController>()) {
          Get.find<UserDetailsController>().fetchUserDetails(userId, forceRefresh: true);
        }

        // Navigate back
        Future.delayed(const Duration(seconds: 1), () {
          Get.find<UsersNavigationController>().goBack();
        });
      } else {
        Get.snackbar(
          'Error',
          'Failed to update profile. Please check console for details.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Exception in saveProfile: $e');
      debugPrint('Stack trace: $stackTrace');
      Get.snackbar(
        'Error',
        'Error updating profile: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    fullNameController.dispose();
    fatherNameController.dispose();
    dobController.dispose();
    mobileController.dispose();
    emailController.dispose();
    addressController.dispose();
    pincodeController.dispose();
    super.onClose();
  }
}
