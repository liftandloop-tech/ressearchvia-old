import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/kyc.controller.dart';
import '../../services/snackbar.service.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/input_formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_styles.dart';
import 'aadhar_verification_screen.dart';
import '../../widgets/button.dart';
import '../../widgets/kyc_step_indicator.dart';
import '../../widgets/data_protection_footer.dart';
import '../../widgets/title_field.dart';
import '../../controllers/auth.controller.dart';

class PanVerificationScreen extends StatefulWidget {
  const PanVerificationScreen({super.key});

  @override
  State<PanVerificationScreen> createState() => _PanVerificationScreenState();
}

class _PanVerificationScreenState extends State<PanVerificationScreen> {
  final kycController = Get.find<KycController>();
  final TextEditingController _panController = TextEditingController();

  Future<void> _submitVerification() async {
    Get.find<AuthController>().signUpError.value = null;
    final panNumber = _panController.text.trim();

    if (panNumber.isEmpty) {
      SnackbarService.showWarning('Please enter PAN number');
      return;
    }

    final panValidation = Validators.validatePAN(panNumber);
    if (panValidation != null) {
      SnackbarService.showWarning(panValidation);
      return;
    }

    Get.to(() => AadharVerificationScreen(panNumber: panNumber));
  }

  @override
  void dispose() {
    _panController.dispose();
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
        title: const Text('KYC Verification', style: AppStyles.appBarTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const KycStepIndicator(
              currentStep: 1,
              totalSteps: 3,
              title: 'KYC Verification',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
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
                        Icons.credit_card_outlined,
                        color: AppTheme.primaryBlue,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('PAN Verification', style: AppStyles.heading2),
                    const SizedBox(height: 8),
                    Text(
                      'Please provide your PAN details for\nidentity verification',
                      textAlign: TextAlign.center,
                      style: AppStyles.bodySmall.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    Obx(() => TitleField(
                      title: 'PAN Number',
                      hint: 'eg: ABCDE1234F',
                      controller: _panController,
                      icon: Icons.credit_card,
                      keyboardType: TextInputType.text,
                      errorText: Get.find<AuthController>().signUpError.value,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                        LengthLimitingTextInputFormatter(10),
                        UpperCaseTextFormatter(),
                      ],
                    )),
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
                      title: 'Submit for Verification',
                      onTap: kycController.isLoading.value
                          ? null
                          : _submitVerification,
                      buttonType: ButtonType.green,
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
