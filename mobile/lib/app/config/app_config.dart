class AppConfig {
  AppConfig._();

  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_URL', defaultValue: '');
    if (override.isNotEmpty) return override;

    return 'http://10.0.2.2:3000';
  }
}

final String kApiBaseUrl = AppConfig.apiBaseUrl;
