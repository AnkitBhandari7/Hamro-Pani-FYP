// lib/app/config/app_config.dart
class AppConfig {
  AppConfig._();

  // Override at run/build time:
  // flutter run --dart-define=API_URL=http://192.168.1.50:3000
  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_URL', defaultValue: '');
    if (override.isNotEmpty) return override;

    // Android emulator default
    return 'http://10.0.2.2:3000';
  }
}

// Keep the same symbol your code already uses
final String kApiBaseUrl = AppConfig.apiBaseUrl;