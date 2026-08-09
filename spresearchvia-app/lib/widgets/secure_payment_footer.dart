import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class SecurePaymentFooter extends StatelessWidget {
  const SecurePaymentFooter({super.key, this.provider = 'Stripe'});

  final String provider;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock, color: AppTheme.textGrey, size: 16),
        const SizedBox(width: 6),
        Text(
          'Secure payment powered by $provider',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: AppTheme.textGrey,
          ),
        ),
      ],
    );
  }
}
