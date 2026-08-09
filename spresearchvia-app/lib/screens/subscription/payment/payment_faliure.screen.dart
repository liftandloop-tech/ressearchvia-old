import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/button.dart';

class PaymentFaliureScreen extends StatelessWidget {
  const PaymentFaliureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> errorData = Get.arguments ?? {};
    final String errorMessage =
        errorData['message'] ?? 'Something went wrong, please try again';

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xffFEF2F2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.warning, size: 30, color: Color(0xffEF4444)),
            ),
          ),

          const SizedBox(height: 25),
          const Text(
            'Payment Failed',
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              errorMessage,
              overflow: TextOverflow.clip,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontFamily: 'Poppins'),
            ),
          ),
          const SizedBox(height: 20),
          Button(
            title: 'Retry Payment',
            onTap: () {
              // Replace with actual retry logic or navigate to payment screen
              Get.offAllNamed('/subscription/payment');
            },
            icon: Icons.refresh,
            buttonType: ButtonType.green,
          ),
          const SizedBox(height: 10),
          Button(
            title: 'Back',
            onTap: () {
              // Navigate to registration or segment selection screen
              Get.offAllNamed('/registration');
            },
            icon: Icons.arrow_back,
            buttonType: ButtonType.greyBorder,
          ),

          GestureDetector(
            onTap: () {},
            child: const SizedBox(
              height: 20,
              child: Text(
                'Need help? Contact support',
                style: TextStyle(fontSize: 12, color: Color(0xff163174)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
