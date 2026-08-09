import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class SegmentHeaderCell extends StatelessWidget {
  final String text;

  const SegmentHeaderCell(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
