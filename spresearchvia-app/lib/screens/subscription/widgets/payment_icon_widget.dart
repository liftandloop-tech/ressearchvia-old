import 'package:flutter/material.dart';

class PaymentIconWidget extends StatelessWidget {
  final String assetPath;

  const PaymentIconWidget({super.key, required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Icon(Icons.payment, size: 12, color: Colors.grey[600]),
      ),
    );
  }
}
