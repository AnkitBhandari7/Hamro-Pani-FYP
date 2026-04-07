class AppConfig {
  AppConfig._();

  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_URL', defaultValue: '');
    if (override.isNotEmpty) return override;

    return 'https://hamro-pani-fyp-backend.onrender.com';
  }
}

final String kApiBaseUrl = AppConfig.apiBaseUrl;
