import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'SPResearchVia Admin Panel';
  static const String version = '1.0.0';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  static String get automatedApiBaseUrl {
    const fromEnv = String.fromEnvironment('AUTOMATED_API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kReleaseMode) {
      return 'https://api.researchvia.in/automated';
    }
    return 'http://localhost:3000';
  }

  static const String digioSession = 'SIDYBZCWUUGTRIJQRDVXCWQBLDFCTLSB';
  static const String digioDownloadUrl =
      'https://api.digio.in/v2/client/document/download';
  static const String copyrightText =
      '© 2025 Research Via. All rights reserved.';

  static String buildImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      debugPrint('AppConfig.buildImageUrl EMPTY OR NULL PATH');
      return '';
    }
    if (path.startsWith('http')) {
      debugPrint('AppConfig.buildImageUrl ALREADY HTTP: $path');
      return path;
    }

    // Use apiBaseUrl as starting point for root
    String rootUrl = apiBaseUrl;
    if (rootUrl.endsWith('/api')) {
      rootUrl = rootUrl.substring(0, rootUrl.length - 4);
    } else if (rootUrl.endsWith('/api/')) {
      rootUrl = rootUrl.substring(0, rootUrl.length - 5);
    }

    String cleanPath = path;
    // Normalize path (ensure no leading slash)
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    // Handle legacy or incorrect paths containing /api/
    if (cleanPath.startsWith('api/')) {
      cleanPath = cleanPath.substring(4);
    }

    // Handle legacy paths starting with app/uploads/
    if (cleanPath.startsWith('app/uploads/')) {
      cleanPath = cleanPath.substring(4); // Remove 'app/'
    }

    // Handle raw filenames that don't specify subdirectories
    if (!cleanPath.contains('/')) {
      final ext = cleanPath.split('.').last.toLowerCase();
      if (['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'].contains(ext)) {
        cleanPath = 'uploads/kycvid/$cleanPath';
      } else {
        cleanPath = 'uploads/kycimg/$cleanPath';
      }
    } else {
      // Ensure it starts with uploads/
      if (!cleanPath.startsWith('uploads/')) {
        cleanPath = 'uploads/$cleanPath';
      }
    }

    // Final URL assembly
    final finalUrl = rootUrl.endsWith('/')
        ? '$rootUrl$cleanPath'
        : '$rootUrl/$cleanPath';
    debugPrint(
      'AppConfig.buildImageUrl RETURN: $finalUrl (from original: $path)',
    );
    return finalUrl;
  }
}
