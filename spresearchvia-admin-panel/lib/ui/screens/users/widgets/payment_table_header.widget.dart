import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class PaymentTableHeader extends StatelessWidget {
  final String text;

  const PaymentTableHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}
