import 'dart:io';
import 'package:flutter/foundation.dart';

enum AppMode { development, production }

enum FeatureFlag { paymentMockEnabled, debugLogsEnabled, crashReportingEnabled }

class AppConfig {
  static const AppMode _mode = kReleaseMode ? AppMode.production : AppMode.development;
  static final policyURL = Uri.parse('https://researchvia.in/privacy-policy/');
  static final deleteURL = Uri.parse('https://researchvia.in/delete-account/');
  static const int storageVersion = 2; // Increment this to clear stale local storage flags

  static const Map<FeatureFlag, bool> _defaultFlags = {
    FeatureFlag.paymentMockEnabled: false,
    FeatureFlag.debugLogsEnabled: false,
    FeatureFlag.crashReportingEnabled: true,
  };

  static const Map<FeatureFlag, bool> _developmentOverrides = {
    FeatureFlag.paymentMockEnabled: false,
    FeatureFlag.debugLogsEnabled: true,
    FeatureFlag.crashReportingEnabled: false,
  };

  static AppMode get mode => _mode;
  static bool get isDevelopment => _mode == AppMode.development;
  static bool get isProduction => _mode == AppMode.production;

  static bool isFeatureEnabled(FeatureFlag flag) {
    if (isDevelopment && _developmentOverrides.containsKey(flag)) {
      return _developmentOverrides[flag]!;
    }
    return _defaultFlags[flag] ?? false;
  }

  static String get baseUrl {
    switch (_mode) {
      case AppMode.development:
        if (Platform.isAndroid) {
          // Use 10.0.2.2 for Android Emulator (Host Loopback)
          return 'http://10.0.2.2:8080/api';
        }
        // For iOS Physical Device: Use LAN IP (WiFi or USB Hotspot)
        // For iOS Simulator: Use localhost
        // 
        // IMPORTANT: Make sure your iPhone and Mac are on the same WiFi network
        // Current Mac IP: 192.168.29.35
        return 'http://192.168.29.35:8080/api';
        // For Simulator only: Use localhost
        // return 'http://localhost:8080/api';
      case AppMode.production:
        return 'https://api.researchvia.in/api';
        //return 'http://10.0.2.2:8080/api';
    }
  }

  static String get automatedApiBaseUrl {
    switch (_mode) {
      case AppMode.development:
        if (Platform.isAndroid) {
          return 'http://10.0.2.2:3000';
        }
        return 'http://192.168.29.35:3000';
      case AppMode.production:
        return 'https://api.researchvia.in/automated';
    }
  }

  static bool get useSecureStorage => isProduction;
  static Duration get tokenRefreshThreshold => const Duration(minutes: 5);

  static int get maxRetryAttempts => 3;
  static Duration get networkTimeout => const Duration(seconds: 30);

  static int get otpSize => 4;
}
