
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/analytics_service.dart';
import '../../core/utils/responsive.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool hasSeenOnboarding;
  
  const SplashScreen({
    super.key, 
    required this.hasSeenOnboarding,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    AnalyticsService.screenViewed('splash');
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _navigate();
      }
    });
  }
  
  void _navigate() {
    if (widget.hasSeenOnboarding) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoSize = Responsive.emptyStateSize(context);
    final innerSize = logoSize * 0.5;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 40,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/icons/compress_icon.png',
                      width: innerSize,
                      height: innerSize,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.compress,
                          size: innerSize * 0.8,
                          color: AppColors.textOnPrimary,
                        );
                      },
                    ),
                  ),
                ),
              )
                .animate(controller: _controller)
                .fadeIn(duration: 600.ms)
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  duration: 800.ms,
                  curve: Curves.elasticOut,
                )
                .then()
                .shimmer(
                  duration: 1000.ms,
                  color: AppColors.textOnPrimary.withValues(alpha: 0.3),
                ),
            
            const SizedBox(height: 40),
            
            // App title
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: AppColors.primaryGradient,
              ).createShader(bounds),
              child: Text(
                'File Compressor',
                style: TextStyle(
                  fontSize: Responsive.display(context),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
                .animate(controller: _controller)
                .fadeIn(delay: 400.ms, duration: 600.ms)
                .slideY(
                  begin: 0.3,
                  end: 0,
                  duration: 600.ms,
                  curve: Curves.easeOut,
                ),
            
            const SizedBox(height: 12),
            
            Text(
              'Compress Smarter, Not Harder',
              style: TextStyle(
                fontSize: Responsive.body(context),
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            )
                .animate(controller: _controller)
                .fadeIn(delay: 600.ms, duration: 600.ms),
            
            const SizedBox(height: 60),
            
            // Loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            )
                .animate(controller: _controller)
                .fadeIn(delay: 800.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
