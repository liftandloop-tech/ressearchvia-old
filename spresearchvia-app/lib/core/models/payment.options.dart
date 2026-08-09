import 'package:flutter/material.dart';

enum PaymentMethod { razorpay, bankTransfer, adminEntitlement }

class PaymentOption {
  final PaymentMethod method;
  final String title;
  final IconData icon;

  const PaymentOption({
    required this.method,
    required this.title,
    required this.icon,
  });

  static const List<PaymentOption> options = [
    PaymentOption(
      method: PaymentMethod.razorpay,
      title: 'Pay Online (Razorpay)',
      icon: Icons.payment,
    ),
    PaymentOption(
      method: PaymentMethod.bankTransfer,
      title: 'Bank Transfer (Upload Screenshot)',
      icon: Icons.account_balance,
    ),
  ];
}
