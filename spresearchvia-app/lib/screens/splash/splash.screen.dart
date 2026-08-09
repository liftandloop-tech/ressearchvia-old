import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/app_logo.dart';
import 'widgets/animated_loading_dots.dart';
import 'widgets/animated_loading_bar.dart';
import 'widgets/info_item.dart';
import '../../controllers/auth.controller.dart';
import '../../controllers/plan_purchase.controller.dart';
import '../../services/secure_storage.service.dart';
import '../../services/snackbar.service.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _handleStartup();
  }

  Future<void> _handleStartup() async {
    try {
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      AuthController authController;
      if (Get.isRegistered<AuthController>()) {
        authController = Get.find<AuthController>();
      } else {
        authController = Get.put(AuthController());
      }

      // Check for pending payments first
      final paymentVerified = await _checkPendingPayments();
      if (paymentVerified) return; // If verified and navigated, stop here
      
      if (!mounted) return;

      // Check auth status and navigate based on backend response
      await authController.checkAuthStatus();
      
    } catch (e) {
      if (mounted) {
        Get.offAllNamed(AppRoutes.getStarted);
      }
    }
  }

  Future<bool> _checkPendingPayments() async {
    try {
      if (!Get.isRegistered<SecureStorageService>()) return false;
      
      final secureStorage = Get.find<SecureStorageService>();
      final pending = await secureStorage.getPendingPayment();

      if (pending != null) {
        final paymentId = pending['paymentId'];
        final orderId = pending['orderId'];

        // Ensure PlanPurchaseController is available
        final planController = Get.isRegistered<PlanPurchaseController>()
            ? Get.find<PlanPurchaseController>()
            : Get.put(PlanPurchaseController());

        final success = await planController.verifyPayment(
          paymentId: paymentId!,
          razorpayOrderId: orderId!,
          razorpayPaymentId: paymentId,
          razorpaySignature: '',
        );

        if (success) {
          await secureStorage.clearPendingPayment();
          SnackbarService.showSuccess(
            'Previous payment verified successfully!',
          );

          await Future.delayed(const Duration(milliseconds: 1000));
          Get.offAllNamed(AppRoutes.tabs);
          return true;
        }
      }
      return false;
    } catch (e) {
      Get.log('Error checking pending payment: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),
                      const AppLogo(),
                      const SizedBox(height: 16),
                      Container(
                        width: 64,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xff11416B),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Your Trusted Market\nResearch Partner',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff374151),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 48),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InfoItem(
                            icon: Icons.shield_outlined,
                            title: 'Secure',
                          ),
                          SizedBox(width: 32),
                          InfoItem(
                            icon: Icons.flash_on_outlined,
                            title: 'Fast',
                          ),
                          SizedBox(width: 32),
                          InfoItem(
                            icon: Icons.analytics_outlined,
                            title: 'Accurate',
                          ),
                        ],
                      ),
                      const Spacer(flex: 2),
                      AnimatedLoadingDots(controller: _controller),
                      const SizedBox(height: 16),
                      const Text(
                        'Loading your dashboard...',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Version 2.1.0',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedLoadingBar(controller: _controller),
          ),
        ],
      ),
    );
  }
}
