import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditProfileController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController(text: 'John');
  final middleNameController = TextEditingController(text: 'Michael');
  final lastNameController = TextEditingController(text: 'Smith');
  final fatherNameController = TextEditingController(text: 'Robert Smith');
  final dobController = TextEditingController(text: '1990-05-15');
  final mobileController = TextEditingController(text: '+1 234 567 8900');
  final emailController = TextEditingController(text: 'john.smith@example.com');
  final houseNoController = TextEditingController(text: '123');
  final streetController = TextEditingController(text: 'Main Street');
  final areaController = TextEditingController(text: 'Downtown');
  final landmarkController = TextEditingController(text: 'Near City Mall');
  final pincodeController = TextEditingController(text: '12345');

  final selectedGender = 'Male'.obs;
  final selectedState = 'California'.obs;
  final autoRenew = true.obs;

  void updateGender(String? value) {
    if (value != null) selectedGender.value = value;
  }

  void updateState(String? value) {
    if (value != null) selectedState.value = value;
  }

  void toggleAutoRenew() {
    autoRenew.value = !autoRenew.value;
  }

  void saveProfile() {
    if (!formKey.currentState!.validate()) {
      return;
    }
    Get.snackbar('Success', 'Profile updated successfully');
  }

  @override
  void onClose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    fatherNameController.dispose();
    dobController.dispose();
    mobileController.dispose();
    emailController.dispose();
    houseNoController.dispose();
    streetController.dispose();
    areaController.dispose();
    landmarkController.dispose();
    pincodeController.dispose();
    super.onClose();
  }
}
