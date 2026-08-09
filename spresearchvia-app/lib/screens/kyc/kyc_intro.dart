import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../auth/login.screen.dart';
import 'digio_connect_screen.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/button.dart';
import '../../widgets/kyc_verification_card.dart';
import '../../widgets/data_protection_footer.dart';

class KycIntroScreen extends StatelessWidget {
  const KycIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const SizedBox(
                  height: 100,
                  width: double.maxFinite,
                  child: AppLogo(),
                ),
                const SizedBox(height: 10),

                Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                    color: Color(0xffEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset('assets/images/kyclogo.png'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Verify Your Identity',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff11416B),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Complete your KYC to access premium\nresearch and insights as per SEBI regulations',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Color(0xff6B7280),
                  ),
                ),
                const SizedBox(height: 15),
                const KycVerificationCard(
                  icon: Icons.credit_card_outlined,
                  title: 'PAN Verification via KRA',
                ),
                const KycVerificationCard(
                  icon: Icons.draw_outlined,
                  title: 'Aadhar eSign via Digio',
                ),
                const KycVerificationCard(
                  icon: Icons.videocam_outlined,
                  title: 'Video Verification',
                ),
                
                const SizedBox(height: 20),
                Button(
                  title: 'Start KYC Verification Process',
                  iconRight: Icons.arrow_forward,
                  buttonType: ButtonType.green,
                  onTap: () {
                    Get.toNamed(AppRoutes.signup);
                  },
                ),
                
                const SizedBox(height: 16),
                const DataProtectionFooter(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
