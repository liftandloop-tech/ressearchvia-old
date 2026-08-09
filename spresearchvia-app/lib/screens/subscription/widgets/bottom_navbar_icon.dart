import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class BottomNavbarIcon extends StatelessWidget {
  const BottomNavbarIcon({
    super.key,
    required this.iconPath,
    required this.isSelected,
  });

  final String iconPath;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        isSelected ? AppTheme.primaryGreen : AppTheme.iconGrey,
        BlendMode.srcIn,
      ),
      child: Image.asset(iconPath, width: 24, height: 24),
    );
  }
}
