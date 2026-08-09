import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth.controller.dart';
import '../../widgets/app_logo.dart';
import '../../core/routes/app_routes.dart';
import 'set_mpin.screen.dart';
import 'widgets/pin_input_boxes.dart';

class OtpVerificationScreen extends StatelessWidget {
  const OtpVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final args = Get.arguments as Map<String, dynamic>?;
    final String phone = (args?['phone'] as String?) ?? '';
    final String flow = (args?['flow'] as String?) ?? 'login';
    String maskedPhone = phone;
    if (phone.startsWith('91') && phone.length >= 12) {
      final local = phone.substring(2);

      maskedPhone = '+91-${local.replaceRange(0, 6, 'XXXXXX')}';
    }

    Future<void> verifyOtp(String otp) async {
      final success = await authController.verifyOtp(otp);
      if (success) {
        Get.off(() => SetMpinScreen(phone: phone, flow: flow));
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const AppLogo(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xffEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.phone_android,
                          size: 40,
                          color: Color(0xff0B3A70),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Verify OTP',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff0B3A70),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Enter the 4-digit code sent to your\nregistered mobile number.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xff6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "We've sent it to $maskedPhone",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xff9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 32),
                      PinInputBoxes(length: 4, onCompleted: verifyOtp),
                      const SizedBox(height: 16),
                      const Text(
                        'Auto-detecting OTP...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'Resend OTP in 26 s',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xff6B7280),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: Color(0xff9CA3AF),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Your information is secure and encrypted',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xff9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ],
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
