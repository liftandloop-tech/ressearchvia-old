import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class ReportsNavigationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const ReportsNavigationButton({
    super.key,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 20,
        color: onPressed != null ? AppTheme.textPrimary : AppTheme.gray300,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}
