import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth.controller.dart';
import '../../core/routes/app_routes.dart';
import '../../services/snackbar.service.dart';
import '../../services/secure_storage.service.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/button.dart'; // Import Button widget
import 'widgets/pin_input_boxes.dart';

class SetMpinScreen extends StatefulWidget {
  final String? phone;
  final String? flow;
  const SetMpinScreen({super.key, this.phone, this.flow});

  @override
  State<SetMpinScreen> createState() => _SetMpinScreenState();
}

class _SetMpinScreenState extends State<SetMpinScreen> {
  final AuthController authController = Get.find<AuthController>();
  final SecureStorageService storage = SecureStorageService();

  String _mpin = '';
  String _confirmMpin = '';

  Future<void> _submitMpin() async {
    if (_mpin.length != 4) {
      SnackbarService.showError('Please enter a valid 4-digit MPIN');
      return;
    }

    if (_confirmMpin.length != 4) {
      SnackbarService.showError('Please confirm your 4-digit MPIN');
      return;
    }

    if (_mpin != _confirmMpin) {
      SnackbarService.showError('MPINs do not match. Please try again.');
      return;
    }

    String? userPhone = widget.phone;
    if (userPhone == null) {
      final userData = await storage.getUserData();
      userPhone = userData?['phone']?.toString() ??
          userData?['userObject']?['APP_MOB_NO']?.toString();
    }

    if (userPhone == null) {
      SnackbarService.showError('Phone number not found');
      return;
    }

    final nextStep = await authController.setMpin(userPhone, _mpin);
    if (nextStep != null) {
      final flow = widget.flow ?? Get.arguments?['flow'];
      if (flow == 'signup') {
        Get.offAllNamed(AppRoutes.kycIntro);
      } else if (flow == 'profile' || flow == 'forgot_mpin') {
        // Log out and redirect to login for security after MPIN change/reset
        await authController.logout(redirectTo: AppRoutes.login);
      } else {
        // Handle backend-authoritative navigation (e.g. redirecting to KYC_DETAILS for admin-provisioned users)
        await authController.handlePostLoginNavigation(nextStep);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(
          () => Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const AppLogo(),
                      const SizedBox(height: 40),
                      const Text(
                        'Set Your MPIN',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff0B3A70),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Create a 4-digit PIN for quick and secure login.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Color(0xff6B7280)),
                      ),
                      const SizedBox(height: 30),
                      
                      // Enter MPIN
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Enter New MPIN',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff374151),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      PinInputBoxes(
                        length: 4,
                        onCompleted: (val) {
                          _mpin = val;
                        },
                        obscureText: true,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Confirm MPIN
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Confirm New MPIN',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff374151),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      PinInputBoxes(
                        length: 4,
                        onCompleted: (val) {
                          _confirmMpin = val;
                        },
                        obscureText: true,
                      ),

                      const SizedBox(height: 40),

                      Button(
                        title: 'Set MPIN',
                        buttonType: ButtonType.blue,
                        onTap: authController.isLoading.value ? null : _submitMpin,
                        showLoading: authController.isLoading.value,
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Use this PIN for future logins. Do not share it with\nanyone.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Color(0xff9CA3AF)),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (authController.isLoading.value)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xff0B3A70),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
