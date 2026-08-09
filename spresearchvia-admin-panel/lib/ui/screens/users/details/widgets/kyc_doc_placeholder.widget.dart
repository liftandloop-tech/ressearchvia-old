import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.config.dart';

class KycDocPlaceholder extends StatelessWidget {
  final String label;
  final String? imageUrl;

  const KycDocPlaceholder({super.key, required this.label, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (imageUrl != null) {
          Get.dialog(
            Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: Get.width * 0.8,
                      maxHeight: Get.height * 0.8,
                    ),
                    color: Colors.black,
                    child: Image.network(
                      AppConfig.buildImageUrl(imageUrl),
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text(
                          "Failed to load image",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.black),
                        onPressed: () => Get.back(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          border: Border.all(color: AppTheme.gray200),
        ),
        child: imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      AppConfig.buildImageUrl(imageUrl),
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: AppTheme.iconSizeLarge,
                            color: AppTheme.errorRed,
                          ),
                          SizedBox(height: AppTheme.spacing8),
                          Text(
                            'Failed to load',
                            style: AppTheme.captionStyle.copyWith(
                              color: AppTheme.errorRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Semi-transparent label overlay at the bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          label,
                          style: AppTheme.labelStyle.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Click hint overlay (appears on hover in web)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.zoom_in,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported,
                    size: AppTheme.iconSizeLarge,
                    color: AppTheme.gray400,
                  ),
                  SizedBox(height: AppTheme.spacing8),
                  Text(
                    label,
                    style: AppTheme.labelStyle.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing4),
                  Text(
                    'No image uploaded',
                    style: AppTheme.captionStyle.copyWith(
                      color: AppTheme.gray400,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
