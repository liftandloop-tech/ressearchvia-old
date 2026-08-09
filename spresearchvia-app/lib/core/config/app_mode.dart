import 'app.config.dart';

class AppMode {
  static const String mode = 'production';
  static bool get isDevelopment => AppConfig.isDevelopment;
  static bool get isProduction => AppConfig.isProduction;
}
