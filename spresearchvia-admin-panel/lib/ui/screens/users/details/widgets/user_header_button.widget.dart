import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class UserHeaderButton extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback? onPressed;

  const UserHeaderButton({
    super.key,
    required this.title,
    required this.color,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: AppTheme.iconSizeSmall),
      label: Text(title, style: AppTheme.buttonTextStyle),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppTheme.white,
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing8 + 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        ),
        elevation: 0,
      ),
    );
  }
}
