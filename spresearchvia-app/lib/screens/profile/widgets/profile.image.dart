import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'profile_image_content.dart';

class ProfileImageAvatar extends StatelessWidget {
  const ProfileImageAvatar({
    super.key,
    required this.imagePath,
    this.size = 120,
    this.isNetworkImage = false,
  });

  final String imagePath;
  final double size;
  final bool isNetworkImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(width: 3, color: AppTheme.backgroundWhite),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowMedium,
            offset: const Offset(0, 10),
            blurRadius: 15,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppTheme.shadowLight,
            offset: const Offset(0, 4),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipOval(
        child: ProfileImageContent(imagePath: imagePath, size: size),
      ),
    );
  }
}
