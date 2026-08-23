import 'dart:async';
import 'package:support_chat/support_chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'core/services/revenue_cat_service.dart';
import 'core/services/paywall_config_service.dart';
import 'core/services/analytics_service.dart';
import 'version_a/main_a.dart';

void main() {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize PostHog FIRST so we can capture early errors / lifecycle.
    await AnalyticsService.init();

    // Initialize RevenueCat
    await RevenueCatService.init();

    // Fetch paywall config when app opens (fire and forget)
    PaywallConfigService.fetch();

    // Catch any framework errors that slipped past PostHog autocapture.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      AnalyticsService.exceptionCaptured(details.exception, details.stack);
    };

    // In-app support: an AI answers from this app's knowledge pack in
    // seconds, and anything it escalates reaches a human in the same thread.
    // Light palette, because this app is light-themed.
    SupportConfig.configure(const SupportConfig(
      baseUrl: 'https://rfsupport.odtdoceditor.com',
      appSecret: 'compressor_f8ceda254604e65cf30932bc',
      palette: SupportPalette(
        accent: Color(0xFF2196F3),
        onAccent: Color(0xFFFFFFFF),
        background: Color(0xFFF5F7FA),
        surface: Color(0xFFFFFFFF),
        textPrimary: Color(0xFF212121),
        textMuted: Color(0xFF6B7280),
      ),
    ));
    runApp(const MyApp());
  }, (error, stack) {
    if (kDebugMode) {
      debugPrint('Uncaught zone error: $error\n$stack');
    }
    AnalyticsService.exceptionCaptured(error, stack);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const VersionAApp();
  }
}
