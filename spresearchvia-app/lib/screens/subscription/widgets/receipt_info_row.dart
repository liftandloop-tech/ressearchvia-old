import 'package:flutter/material.dart';

class ReceiptInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final double labelWidth;

  const ReceiptInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Color(0xff6B7280),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xff163174),
            ),
          ),
        ),
      ],
    );
  }
}
