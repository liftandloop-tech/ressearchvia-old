import 'package:flutter/material.dart';
import 'payment_method_card.dart';

class PaymentIcon extends StatelessWidget {
  final PaymentMethodData paymentMethod;

  const PaymentIcon({super.key, required this.paymentMethod});

  @override
  Widget build(BuildContext context) {
    if (paymentMethod.type == PaymentMethodType.upi) {
      return Container(
        width: 48,
        height: 32,
        decoration: BoxDecoration(
          color: paymentMethod.brandColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Center(
          child: Icon(
            Icons.account_balance_wallet,
            color: Colors.white,
            size: 20,
          ),
        ),
      );
    }

    if (paymentMethod.type == PaymentMethodType.netbanking) {
      return Container(
        width: 48,
        height: 32,
        decoration: BoxDecoration(
          color: paymentMethod.brandColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Center(
          child: Icon(Icons.account_balance, color: Colors.white, size: 20),
        ),
      );
    }

    return Container(
      width: 48,
      height: 32,
      decoration: BoxDecoration(
        color: paymentMethod.brandColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          paymentMethod.displayName,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: paymentMethod.type == PaymentMethodType.mastercard
                ? 8
                : 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
