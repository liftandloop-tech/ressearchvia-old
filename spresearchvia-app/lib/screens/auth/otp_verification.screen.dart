import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth.controller.dart';
import '../../widgets/app_logo.dart';
import 'set_mpin.screen.dart';
import 'widgets/pin_input_boxes.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  Timer? _timer;
  int _remainingSeconds = 30;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = 30;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendOtp(String phone) async {
    if (_remainingSeconds > 0 || _isResending) return;

    setState(() {
      _isResending = true;
    });

    try {
      final authController = Get.find<AuthController>();
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      final cleanPhone = digits.length >= 10 ? digits.substring(digits.length - 10) : phone;
      final success = await authController.sendOtp(cleanPhone);
      if (success && mounted) {
        _startTimer();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatMaskedPhone(String phone) {
    if (phone.isEmpty) return '';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) {
      final last10 = digits.substring(digits.length - 10);
      return '+91-${last10.replaceRange(0, 6, 'XXXXXX')}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final args = Get.arguments as Map<String, dynamic>?;
    final String phone = (args?['phone'] as String?) ?? '';
    final String flow = (args?['flow'] as String?) ?? 'login';
    final maskedPhone = _formatMaskedPhone(phone);

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
                      const SizedBox(height: 36),
                      // Dynamic OTP Timer & Resend Button
                      if (_remainingSeconds > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: Color(0xff6B7280),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Resend OTP in ${_remainingSeconds}s',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xff6B7280),
                              ),
                            ),
                          ],
                        )
                      else if (_isResending)
                        const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xff0B3A70),
                          ),
                        )
                      else
                        TextButton.icon(
                          onPressed: () => _resendOtp(phone),
                          icon: const Icon(Icons.refresh, size: 16, color: Color(0xff0B3A70)),
                          label: const Text(
                            'Resend OTP Now',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff0B3A70),
                            ),
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
