import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class ReportCell extends StatelessWidget {
  final String text;
  final Color? color;
  final FontWeight? fontWeight;

  const ReportCell({
    super.key,
    required this.text,
    this.color,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          color: color ?? AppTheme.textPrimary,
          fontWeight: fontWeight ?? FontWeight.w400,
          height: 1.2,
        ),
      ),
    );
  }
}
