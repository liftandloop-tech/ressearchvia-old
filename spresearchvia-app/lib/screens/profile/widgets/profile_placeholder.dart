import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ProfilePlaceholder extends StatelessWidget {
  final double size;

  const ProfilePlaceholder({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundLightBlue,
      child: Icon(Icons.person, size: size * 0.5, color: AppTheme.primaryBlue),
    );
  }
}
