import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class UserTableCell extends StatelessWidget {
  final String text;
  final int flex;
  final TextAlign alignment;

  const UserTableCell(
    this.text, {
    super.key,
    required this.flex,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: alignment,
        style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
