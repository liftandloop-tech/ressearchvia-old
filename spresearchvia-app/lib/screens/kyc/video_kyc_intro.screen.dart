import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/button.dart';
import '../../widgets/kyc_permission_dialog.dart';
import '../../controllers/auth.controller.dart';
import '../../core/routes/app_routes.dart';
import '../../services/snackbar.service.dart';

class VideoKycIntroScreen extends StatefulWidget {
  const VideoKycIntroScreen({super.key});

  @override
  State<VideoKycIntroScreen> createState() => _VideoKycIntroScreenState();
}

class _VideoKycIntroScreenState extends State<VideoKycIntroScreen> {
  String _selectedLanguage = 'English';
  bool _isAccepted = false;

  bool _isProcessing = false;

  Future<void> _onContinue() async {
    if (!_isAccepted || _isProcessing) return;

    // Step 1: Check permissions upfront before doing anything
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;

    final bool bothGranted = cameraStatus.isGranted && micStatus.isGranted;

    if (!bothGranted) {
      // Show the permission diagnostic popup.
      // It will call _proceedAfterPermissions() only when both are confirmed.
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => KycPermissionDialog(
            onBothGranted: _proceedAfterPermissions,
          ),
        );
      }
      return;
    }

    // Both already granted — go straight through
    await _proceedAfterPermissions();
  }

  Future<void> _proceedAfterPermissions() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      if (!Get.isRegistered<AuthController>()) {
        Get.put(AuthController());
      }
      final authController = Get.find<AuthController>();

      final success = await authController.acceptTradingDisclaimer('v1');

      if (success) {
        try {
          // Using named route ensures AuthController guard logic can detect the route reliably
          await Get.toNamed(AppRoutes.videoRecorder, arguments: _selectedLanguage);
        } catch (e) {
          SnackbarService.showError('Could not open camera screen: $e');
        }
      } else {
        SnackbarService.showError('Failed to update disclaimer status. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff111827)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Video KYC Verification',
          style: TextStyle(
            color: Color(0xff11416B),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xffE5E7EB)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Important Instructions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildBulletPoint('Ensure your full face is clearly visible'),
                    _buildBulletPoint('Sit in a well-lit and quiet environment'),
                    _buildBulletPoint('Read the on-screen declaration clearly'),
                    _buildBulletPoint('Do not pause, edit, or cover your face during recording'),
                    _buildBulletPoint('Video duration will be approximately 10–15 seconds'),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Select Declaration Language',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1F2937),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xffE5E7EB)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildCustomRadioTile(
                      title: 'English',
                      value: 'English',
                    ),
                    const Divider(height: 1),
                    _buildCustomRadioTile(
                      title: 'Hindi',
                      value: 'Hindi',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xffFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffFFEDD5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Please read this declaration in the video:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff9A3412),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedLanguage == 'Hindi'
                          ? 'मैं इस सेवा को स्वीकार करता हूँ और मुझे बाज़ार में शामिल जोखिमों की पूरी जानकारी है।'
                          : 'I accept the service and i also aware about the Risk involve in the market.',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xffC2410C),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xffF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _isAccepted,
                        onChanged: (val) => setState(() => _isAccepted = val!),
                        activeColor: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'I confirm that I am recording this video voluntarily and agree to the Terms & Conditions and SEBI compliance requirements.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xff4B5563),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Button(
            title: 'Continue',
            onTap: _isAccepted ? _onContinue : null,
            buttonType: _isAccepted ? ButtonType.blue : ButtonType.greyBorder,
            showLoading: _isProcessing,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomRadioTile({required String title, required String value}) {
    final bool isSelected = _selectedLanguage == value;
    return InkWell(
      onTap: () => setState(() => _selectedLanguage = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primaryBlue : const Color(0xff9CA3AF),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xff1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: AppTheme.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xff4B5563),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}