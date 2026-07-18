import 'package:flutter/foundation.dart';

@immutable
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.demoMode,
  });

  factory AppConfig.fromEnvironment() => const AppConfig(
    apiBaseUrl: String.fromEnvironment(
      'ROAD_DNA_API_URL',
      defaultValue: 'http://10.0.2.2:3000',
    ),
    demoMode: bool.fromEnvironment('ROAD_DNA_DEMO_MODE'),
  );

  final String apiBaseUrl;
  final bool demoMode;
}
