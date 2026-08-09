import 'package:flutter/material.dart';

class SecurePaymentFooter extends StatelessWidget {
  const SecurePaymentFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 16, color: Color(0xff9CA3AF)),
        SizedBox(width: 6),
        Text(
          'Secure payment powered by Stripe',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xff9CA3AF),
          ),
        ),
      ],
    );
  }
}
