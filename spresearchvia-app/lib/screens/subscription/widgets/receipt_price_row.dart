import 'package:flutter/material.dart';

class ReceiptPriceRow extends StatelessWidget {
  final String label;
  final String amount;

  const ReceiptPriceRow({super.key, required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Color(0xff6B7280),
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xff163174),
          ),
        ),
      ],
    );
  }
}
