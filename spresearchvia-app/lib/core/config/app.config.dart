enum AppMode { development, production }

enum FeatureFlag { paymentMockEnabled, debugLogsEnabled, crashReportingEnabled }

class AppConfig {
  static const AppMode _mode = AppMode.production;
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
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    switch (_mode) {
      case AppMode.development:
        return 'https://api.researchvia.in/api';
      case AppMode.production:
        return 'https://api.researchvia.in/api';
    }
  }

  static String get automatedApiBaseUrl {
    const envUrl = String.fromEnvironment('AUTOMATED_API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    switch (_mode) {
      case AppMode.development:
        return 'https://tradetest.researchvia.in';
      case AppMode.production:
        return 'https://tradetest.researchvia.in';
    }
  }

  static bool get useSecureStorage => isProduction;
  static Duration get tokenRefreshThreshold => const Duration(minutes: 5);

  static int get maxRetryAttempts => 3;
  static Duration get networkTimeout => const Duration(seconds: 30);

  static int get otpSize => 4;
  static const String appVersion = '2.7.1';
}
