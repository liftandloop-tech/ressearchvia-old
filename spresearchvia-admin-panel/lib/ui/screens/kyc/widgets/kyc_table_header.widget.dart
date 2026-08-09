import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class KycTableHeader extends StatelessWidget {
  final String text;

  const KycTableHeader({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(text, style: AppTheme.tableHeaderStyle),
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_upward,
            size: 12,
            color: AppTheme.subtitleTextColor,
          ),
        ],
      ),
    );
  }
}
