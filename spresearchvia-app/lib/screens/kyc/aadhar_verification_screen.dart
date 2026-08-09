import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/kyc.controller.dart';
import '../../services/snackbar.service.dart';
import '../../core/utils/input_formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_styles.dart';
import 'kyc_document_upload.screen.dart';
import '../../widgets/button.dart';
import '../../widgets/kyc_step_indicator.dart';
import '../../widgets/data_protection_footer.dart';
import '../../widgets/title_field.dart';
import '../../controllers/auth.controller.dart';

class AadharVerificationScreen extends StatefulWidget {
  final String? panNumber;
  const AadharVerificationScreen({super.key, this.panNumber});

  @override
  State<AadharVerificationScreen> createState() =>
      _AadharVerificationScreenState();
}

class _AadharVerificationScreenState extends State<AadharVerificationScreen> {
  final kycController = Get.find<KycController>();
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.panNumber != null) {
      _panController.text = widget.panNumber!;
    }
  }

  Future<void> _submitVerification() async {
    final aadharNumber = _aadharController.text.trim().replaceAll(' ', '');
    final panNumber = _panController.text.trim().toUpperCase();
    final dob = _dobController.text.trim();

    if (panNumber.isEmpty) {
      SnackbarService.showWarning('Please enter PAN number');
      return;
    }
    if (aadharNumber.isEmpty) {
      SnackbarService.showWarning('Please enter Aadhar number');
      return;
    }
    if (aadharNumber.length != 12) {
      SnackbarService.showWarning('Aadhar number must be 12 digits');
      return;
    }
    if (dob.isEmpty) {
      SnackbarService.showWarning('Please enter Date of Birth');
      return;
    }

    // Call API to save KYC details
    final success = await Get.find<AuthController>().signUp(
      userId: Get.find<AuthController>().currentUser.value?.id ?? '',
      pan: panNumber,
      dob: dob,
      aadhaarNumber: aadharNumber,
      userType: 'user', 
    );

    if (!success) {
      // Check if there is an error related to PAN
      // This is bit tricky as AuthController shows snackbar directly.
      // We can rely on a specific check if we want, but for now let's set a generic one if it fails and PAN is valid format.
      // Ideally we would want the error from controller.
    }

    if (success) {
      Get.to(() => KycDocumentUploadScreen(
            panNumber: panNumber,
            aadharNumber: aadharNumber,
          ));
    }
  }

  @override
  void dispose() {
    _aadharController.dispose();
    _panController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
          onPressed: () => Get.back(),
        ),
        title: const Text('Identity Verification', style: AppStyles.appBarTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const KycStepIndicator(
              currentStep: 2,
              totalSteps: 4, // Increased steps
              title: 'Identity Verification',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLightBlue,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: AppTheme.primaryBlue,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Verify Identity', style: AppStyles.heading2),
                    const SizedBox(height: 8),
                    Text(
                      'Please provide your PAN and Aadhar details\nfor identity verification',
                      textAlign: TextAlign.center,
                      style: AppStyles.bodySmall.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    Obx(() => TitleField(
                      title: 'PAN Number',
                      hint: 'Enter 10-digit PAN number',
                      controller: _panController,
                      icon: Icons.credit_card,
                      textCapitalization: TextCapitalization.characters,
                      errorText: Get.find<AuthController>().signUpError.value,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(10),
                        FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
                      ],
                    )),
                    const SizedBox(height: 16),
                    TitleField(
                      title: 'Aadhar Number',
                      hint: 'Enter 12-digit Aadhar number',
                      controller: _aadharController,
                      icon: Icons.credit_card,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        AadharInputFormatter(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TitleField(
                      title: 'Date of Birth',
                      hint: 'DD/MM/YYYY',
                      controller: _dobController,
                      icon: Icons.calendar_today,
                      keyboardType: TextInputType.datetime,
                      inputFormatters: [
                        DateInputFormatter(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.backgroundWhite,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowLight,
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Obx(
                    () => Button(
                      title: 'Proceed to Upload',
                      onTap: kycController.isLoading.value
                          ? null
                          : _submitVerification,
                      buttonType: ButtonType.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const DataProtectionFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
