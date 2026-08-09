import 'package:flutter/material.dart';
import '../../../core/config/app.config.dart';
import '../../../core/theme/app_theme.dart';
import 'profile_placeholder.dart';

class ProfileImageContent extends StatelessWidget {
  final String imagePath;
  final double size;

  const ProfileImageContent({
    super.key,
    required this.imagePath,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    String finalUrl = imagePath;
    bool isNetwork = false;

    if (imagePath.startsWith('http')) {
      isNetwork = true;
    } else if (imagePath.startsWith('uploads/')) {
      // Construct full URL relative to API Base
      String baseUrl = AppConfig.baseUrl;
      if (baseUrl.endsWith('/api')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 4);
      }
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }
      finalUrl = '$baseUrl/$imagePath';
      isNetwork = true;
    }

    if (isNetwork) {
      return Image.network(
        finalUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return ProfilePlaceholder(size: size);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: AppTheme.primaryBlue,
            ),
          );
        },
      );
    } else {
      try {
        return Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return ProfilePlaceholder(size: size);
          },
        );
      } catch (e) {
        return ProfilePlaceholder(size: size);
      }
    }
  }
}
