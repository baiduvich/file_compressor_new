import 'dart:async';
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
