import 'package:flutter/material.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/revenue_cat_service.dart';
import '../../core/services/history_service.dart';
import '../../core/services/analytics_service.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

class VersionAApp extends StatefulWidget {
  const VersionAApp({super.key});

  @override
  State<VersionAApp> createState() => _VersionAAppState();
}

class _VersionAAppState extends State<VersionAApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      AnalyticsService.appBackgrounded();
    } else if (state == AppLifecycleState.resumed) {
      AnalyticsService.appResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HistoryService(),
      child: MaterialApp(
        title: 'File Compressor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        navigatorObservers: [PosthogObserver()],
        home: const _InitialScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
        },
      ),
    );
  }
}

class _InitialScreen extends StatefulWidget {
  const _InitialScreen();

  @override
  State<_InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<_InitialScreen> {
  bool _isLoading = true;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final isPro = await RevenueCatService.isPro();
    if (mounted) {
      setState(() {
        _isPro = isPro;
        _isLoading = false;
      });
      AnalyticsService.appOpened(isPro: isPro);
      AnalyticsService.setUserProperties(
        isPro: isPro,
        totalCompressions: 0,
        totalSavingsMB: 0,
        planType: isPro ? 'pro' : 'free',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return _isPro ? const HomeScreen() : const OnboardingScreen();
  }
}
