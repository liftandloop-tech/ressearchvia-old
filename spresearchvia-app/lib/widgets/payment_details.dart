import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'payment_method_card.dart';

class PaymentDetails extends StatelessWidget {
  final PaymentMethodData paymentMethod;

  const PaymentDetails({super.key, required this.paymentMethod});

  @override
  Widget build(BuildContext context) {
    if (paymentMethod.type == PaymentMethodType.upi) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            paymentMethod.upiId ?? 'UPI ID',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlueDark,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'UPI Payment',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppTheme.textGrey,
            ),
          ),
        ],
      );
    }

    if (paymentMethod.type == PaymentMethodType.netbanking) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            paymentMethod.bankName ?? 'Bank Account',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlueDark,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Net Banking',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppTheme.textGrey,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '**** **** **** ${paymentMethod.lastFourDigits.padLeft(4, '0')}',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryBlueDark,
          ),
        ),
        if (paymentMethod.expiryDate != null) ...[
          const SizedBox(height: 2),
          Text(
            'Expires ${paymentMethod.expiryDate}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppTheme.textGrey,
            ),
          ),
        ],
      ],
    );
  }
}
