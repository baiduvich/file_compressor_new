import 'package:flutter/material.dart';
import 'core/services/revenue_cat_service.dart';
import 'core/services/paywall_config_service.dart';
import 'core/services/analytics_service.dart';
import 'version_a/main_a.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize RevenueCat
  await RevenueCatService.init();

  // Initialize PostHog analytics
  await AnalyticsService.init();

  // Fetch paywall config when app opens (fire and forget)
  PaywallConfigService.fetch();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // For now, always load Version A
    // Later, we'll add RevenueCat A/B testing logic here
    return const VersionAApp();
  }
}
