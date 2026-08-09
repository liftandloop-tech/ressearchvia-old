import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SummaryTile extends StatelessWidget {
  const SummaryTile({super.key, required this.title, required this.amount});
  final String title;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$title:',
            style: const TextStyle(fontSize: 14, color: AppTheme.textGrey),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '₹$amount',
          style: const TextStyle(fontSize: 14, color: Colors.black),
        ),
      ],
    );
  }
}
