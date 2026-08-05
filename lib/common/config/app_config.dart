import 'package:flutter/material.dart';

class AppBrand {
  final String id;
  final String appName;
  final Color seedColor;
  final Color primary;

  /// Optional asset override for white-label (e.g. `assets/images/logo.png`).
  final String? logoAsset;

  const AppBrand({
    required this.id,
    required this.appName,
    required this.seedColor,
    required this.primary,
    this.logoAsset,
  });
}

class AppConfig {
  final AppBrand brand;

  /// When true, all backend/API calls are replaced by local mocks.
  final bool mockBackend;

  /// Base URL for the REST API (e.g. `https://api.servana.com`).
  final String baseUrl;

  const AppConfig({
    required this.brand,
    required this.mockBackend,
    required this.baseUrl,
  });

  factory AppConfig.fromEnv() {
    const brandId = String.fromEnvironment('BRAND', defaultValue: 'servana');
    const mockBackend =
        bool.fromEnvironment('MOCK_BACKEND', defaultValue: false);
    const baseUrl = String.fromEnvironment('API_BASE_URL',
        defaultValue: 'https://api.servana.com.ph');

    const brands = <String, AppBrand>{
      'servana': AppBrand(
        id: 'servana',
        appName: 'Servana',
        // Accent color (used in chips/highlights) - logo orange (#F89040)
        seedColor: Color(0xFFF89040),
        // Primary brand color (used in app bars/buttons) - logo blue (#3058C8)
        primary: Color(0xFF3058C8),
        logoAsset: 'assets/images/Default.webp',
      ),
      'default': AppBrand(
        id: 'default',
        appName: 'App',
        seedColor: Color(0xFFF89040),
        primary: Color(0xFF3058C8),
        logoAsset: 'assets/images/Default.webp',
      ),
    };

    return AppConfig(
      brand: brands[brandId] ?? brands['default']!,
      mockBackend: mockBackend,
      baseUrl: baseUrl,
    );
  }
}
