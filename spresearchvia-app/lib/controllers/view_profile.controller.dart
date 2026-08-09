import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/user.controller.dart';
import '../core/models/user.dart';
import '../core/utils/error_message_handler.dart';
import '../services/snackbar.service.dart';
import '../services/secure_storage.service.dart';
import '../core/constants/state_map.dart';

class ViewProfileController extends GetxController {
  final userController = Get.find<UserController>();
  final _storage = SecureStorageService();

  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final fatherNameController = TextEditingController();
  final houseNoController = TextEditingController();
  final streetAddressController = TextEditingController();
  final areaController = TextEditingController();
  final landmarkController = TextEditingController();
  final pincodeController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final panController = TextEditingController();
  final dobController = TextEditingController();
  final aadhaarController = TextEditingController();
  final gstinController = TextEditingController();
  final firmNameController = TextEditingController();

  final Rxn<String> selectedState = Rxn<String>();
  final Rxn<File> selectedImage = Rxn<File>();

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  void loadUserData() async {
    final user = userController.currentUser.value;

    if (user != null) {
      // Get the raw user data to access userObject
      final rawUserData = await _storage.getUserData();
      final userObject = rawUserData?['userObject'] as Map<String, dynamic>?;

      // Load full name
      final fullName = user.fullName ?? '';
      final nameParts = fullName.split(' ');
      firstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
      lastNameController.text = nameParts.length > 1 ? nameParts.last : '';
      if (nameParts.length > 2) {
        middleNameController.text = nameParts
            .sublist(1, nameParts.length - 1)
            .join(' ');
      }

      // Load father's name from userObject
      fatherNameController.text = userObject?['APP_F_NAME']?.toString() ?? '';

      // Load address details from userObject
      final add1 = userObject?['APP_COR_ADD1']?.toString() ?? '';
      final add2 = userObject?['APP_COR_ADD2']?.toString() ?? '';
      final add3 = userObject?['APP_COR_ADD3']?.toString() ?? '';

      houseNoController.text = add1;
      streetAddressController.text = add2;
      areaController.text = add3;
      landmarkController.text = userObject?['APP_COR_CITY']?.toString() ?? '';
      pincodeController.text = userObject?['APP_COR_PINCD']?.toString() ?? '';
      selectedState.value = getStateNameFromCode(userObject?['APP_COR_STATE']?.toString());

      // Load contact details - use phone and email from User model (already parsed from userObject)
      phoneController.text = user.phone ?? '';
      emailController.text = user.email ?? '';

      // Load PAN, DOB, and Aadhaar
      panController.text = user.panNumber ?? '';
      dobController.text = userObject?['APP_DOB_DT']?.toString() ?? '';
      aadhaarController.text =
          user.aadharNumber ?? rawUserData?['aadhaarNumber']?.toString() ?? '';
      gstinController.text = user.gstin ?? '';
      firmNameController.text = user.firmName ?? '';
    }
  }

  Future<void> pickImageFromSource(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        selectedImage.value = File(image.path);
        await userController.changeProfileImage(selectedImage.value!);
      }
    } catch (e) {
      ErrorMessageHandler.logError('Pick Image', e);
      SnackbarService.showErrorFromException(e, title: 'Failed to Pick Image');
    }
  }

  Future<void> saveChanges() async {
    final personalInfo = PersonalInformation(
      firstName: firstNameController.text.trim(),
      middleName: middleNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      fatherName: fatherNameController.text.trim(),
    );

    final addressInfo = AddressDetails(
      houseNo: houseNoController.text.trim(),
      streetAddress: streetAddressController.text.trim(),
      area: areaController.text.trim(),
      landmark: landmarkController.text.trim(),
      pincode: int.tryParse(pincodeController.text.trim()) ?? 0,
      state: selectedState.value ?? '',
    );

    final contactInfo = ContactDetails(
      phone: phoneController.text.trim(),
      email: emailController.text.trim(),
    );

    final gstin = gstinController.text.trim();
    final firmName = firmNameController.text.trim();

    if ((gstin.isNotEmpty && firmName.isEmpty) || (gstin.isEmpty && firmName.isNotEmpty)) {
      SnackbarService.showWarning('Both Firm Name and GSTIN must be filled, or both kept empty.');
      return;
    }

    if (gstin.isNotEmpty) {
      final gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$');
      if (!gstRegex.hasMatch(gstin)) {
        SnackbarService.showWarning('Invalid GSTIN format');
        return;
      }
    }

    try {
      final success = await userController.updateProfile(
        personalInformation: personalInfo,
        addressDetails: addressInfo,
        contactDetails: contactInfo,
        gstin: gstin,
        firmName: firmName,
      );

      if (success) {
        SnackbarService.showSuccess('Profile updated successfully!');
        Get.back();
      } else {
        SnackbarService.showError('Failed to update profile');
      }
    } catch (e) {
      ErrorMessageHandler.logError('Update Profile', e);
      SnackbarService.showErrorFromException(e, title: 'Failed to Save');
    }
  }

  @override
  void onClose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    fatherNameController.dispose();
    houseNoController.dispose();
    streetAddressController.dispose();
    areaController.dispose();
    landmarkController.dispose();
    pincodeController.dispose();
    phoneController.dispose();
    emailController.dispose();
    panController.dispose();
    dobController.dispose();
    aadhaarController.dispose();
    gstinController.dispose();
    firmNameController.dispose();
    super.onClose();
  }
}
