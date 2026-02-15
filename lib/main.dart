import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/revenue_cat_service.dart';
import 'core/services/paywall_config_service.dart';
import 'version_a/main_a.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  // Note: Needs GoogleService-Info.plist in ios/Runner/
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init failed (missing plist?): $e");
  }

  // Initialize RevenueCat
  await RevenueCatService.init();

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
