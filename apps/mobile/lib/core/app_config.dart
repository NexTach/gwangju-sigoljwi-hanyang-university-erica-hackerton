import 'package:flutter/foundation.dart';

@immutable
class AppConfig {
  const AppConfig({required this.apiBaseUrl, required this.demoMode});

  factory AppConfig.fromEnvironment() => const AppConfig(
    apiBaseUrl: String.fromEnvironment(
      'ROAD_DNA_API_URL',
      defaultValue: 'https://kimtaeeun.site/road-dna',
    ),
    // The built-in Yongbong scenario is the mobile app's single default
    // experience. It is no longer selected through a separate build mode.
    demoMode: true,
  );

  final String apiBaseUrl;
  final bool demoMode;
}
