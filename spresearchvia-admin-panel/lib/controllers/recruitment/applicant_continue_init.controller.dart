import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/applicant.service.dart';

class ApplicantContinueInitController extends GetxController {
  final ApplicantService _applicantService = Get.put(ApplicantService());

  final identifierController = TextEditingController();
  final otpController = TextEditingController();

  var isLoading = false.obs;
  var isOtpSent = false.obs;
  var otpType = ''.obs; // 'email' or 'mobile'

  Future<void> sendOtp() async {
    final identifier = identifierController.text.trim();

    if (identifier.isEmpty) {
      Get.snackbar('Alert', 'Please enter your registered mobile number or email address', backgroundColor: Colors.orange.withOpacity(0.1));
      return;
    }

    isLoading.value = true;
    try {
      final res = await _applicantService.initiateContinueApplication(identifier);
      if (res.success && res.otpType != null) {
        otpType.value = res.otpType!;
        isOtpSent.value = true;
        Get.snackbar(
          'Verification Code Sent',
          'An OTP has been sent to your registered ${otpType.value == 'email' ? 'email address' : 'mobile number'}',
          backgroundColor: Colors.green.withOpacity(0.1),
        );
      } else {
        Get.snackbar('Error', res.error ?? 'Failed to send verification code', backgroundColor: Colors.red.withOpacity(0.1));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtpAndContinue() async {
    final identifier = identifierController.text.trim();
    final otp = otpController.text.trim();

    if (otp.isEmpty) {
      Get.snackbar('Alert', 'Please enter the verification OTP', backgroundColor: Colors.orange.withOpacity(0.1));
      return;
    }

    isLoading.value = true;
    try {
      final res = await _applicantService.verifyContinueApplication(identifier, otp, otpType.value);
      if (res.error == null && res.applicantId != null) {
        Get.offNamed('/apply/continue/${res.applicantId}');
        Get.snackbar('Success', 'Verification successful. Welcome to your onboarding page.', backgroundColor: Colors.green.withOpacity(0.1));
      } else {
        Get.snackbar('Verification Failed', res.error ?? 'OTP is incorrect', backgroundColor: Colors.red.withOpacity(0.1));
      }
    } finally {
      isLoading.value = false;
    }
  }
}
