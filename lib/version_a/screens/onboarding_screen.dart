import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import 'paywall_screen.dart';

/// Onboarding flow: 3 screens (title → video placeholder → text → Next), then paywall.
/// Review prompt on screen 2. Video areas left empty for you to add assets.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final InAppReview _inAppReview = InAppReview.instance;
  int _currentPage = 0;
  bool _reviewRequested = false;
  int? _nextCooldownSeconds;
  Timer? _nextCooldownTimer;

  static const String _video3Asset = 'assets/videos/video3.mov';

  @override
  void initState() {
    super.initState();
    _nextCooldownSeconds = 3;
    _nextCooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_nextCooldownSeconds == null || _nextCooldownSeconds! <= 0) {
          _nextCooldownTimer?.cancel();
          _nextCooldownTimer = null;
          _nextCooldownSeconds = null;
          return;
        }
        _nextCooldownSeconds = _nextCooldownSeconds! - 1;
        if (_nextCooldownSeconds == 0) {
          _nextCooldownSeconds = null;
          _nextCooldownTimer?.cancel();
          _nextCooldownTimer = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _nextCooldownTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  static const String _reviewPromptAsset =
      'assets/prompt_manager/review_asking.txt';

  Future<String?> _loadReviewPromptText() async {
    try {
      return await rootBundle.loadString(_reviewPromptAsset);
    } catch (_) {
      return null;
    }
  }

  Future<void> _maybeRequestReview() async {
    if (_reviewRequested) return;
    _reviewRequested = true;
    final promptText = await _loadReviewPromptText();
    if (!mounted) return;
    if (promptText != null && promptText.trim().isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rate us'),
          content: SingleChildScrollView(
            child: Text(promptText.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _inAppReview.requestReview();
              },
              child: const Text('Rate us'),
            ),
          ],
        ),
      );
    } else if (await _inAppReview.isAvailable()) {
      await _inAppReview.requestReview();
    }
  }

  Future<void> _onNext() async {
    if (_currentPage < 2) {
      if (_currentPage == 1) await _maybeRequestReview();
      if (!mounted) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) => _OnboardingPage(
                  pageIndex: index,
                  video3Asset: _video3Asset,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_currentPage == 0 && _nextCooldownSeconds != null)
                      ? null
                      : _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                    disabledForegroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentPage == 2
                        ? 'Continue'
                        : (_currentPage == 0 && _nextCooldownSeconds != null
                            ? 'Next ($_nextCooldownSeconds)'
                            : 'Next'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.pageIndex,
    required this.video3Asset,
  });

  final int pageIndex;
  final String video3Asset;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    // Order: 0 = video (ex onboarding 3), 1 = image + EASILY (ex onboarding 1), 2 = slider + HIGH-QUALITY (ex onboarding 2)
    if (pageIndex == 0) {
      // Onboarding 1: video only
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            Expanded(child: _OnboardingVideo(videoAsset: video3Asset)),
          ],
        ),
      );
    }

    if (pageIndex == 1) {
      // Onboarding 2: image + Compress files EASILY!
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.asset(
                  'assets/images/onboarding1.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: textColor,
                      fontSize: Responsive.titleLarge(context),
                    ),
                children: [
                  const TextSpan(text: 'Compress files '),
                  TextSpan(
                    text: 'EASILY!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.fontSize(context, ratio: 0.058, min: 20, max: 30),
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Onboarding 3: before/after slider + Keep HIGH-QUALITY!
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(child: _BeforeAfterComparisonSlider()),
          const SizedBox(height: 24),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: textColor,
                      fontSize: Responsive.titleLarge(context),
                  ),
                children: [
                  const TextSpan(text: 'Keep '),
                  TextSpan(
                    text: 'HIGH-QUALITY!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.fontSize(context, ratio: 0.058, min: 20, max: 30),
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Plays an asset video in a rounded container. Loops and mutes by default.
class _OnboardingVideo extends StatefulWidget {
  const _OnboardingVideo({required this.videoAsset});

  final String videoAsset;

  @override
  State<_OnboardingVideo> createState() => _OnboardingVideoState();
}

class _OnboardingVideoState extends State<_OnboardingVideo> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoAsset)
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: _controller.value.isInitialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Interactive Before/After image comparison slider for Onboarding 2.
/// State is managed within this widget.
class _BeforeAfterComparisonSlider extends StatefulWidget {
  const _BeforeAfterComparisonSlider();

  static const double _handleWidth = 2;

  @override
  State<_BeforeAfterComparisonSlider> createState() =>
      _BeforeAfterComparisonSliderState();
}

class _BeforeAfterComparisonSliderState
    extends State<_BeforeAfterComparisonSlider> {
  double _position = 0.5; // 0.0 = all compressed, 1.0 = all original

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final local = box.globalToLocal(details.globalPosition);
    final width = box.size.width;
    if (width <= 0) return;
    final t = (local.dx / width).clamp(0.0, 1.0);
    setState(() => _position = t);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        return SizedBox(
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(
              builder: (context, innerConstraints) {
                final w = innerConstraints.maxWidth;
                final h = innerConstraints.maxHeight;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Bottom layer: Compressed (full width)
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/onboarding2_2.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Top layer: Original (clipped by widthFactor)
                  Positioned.fill(
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: _position,
                        child: SizedBox(
                          width: w,
                          height: h,
                          child: Image.asset(
                            'assets/images/onboarding2_1.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Data labels
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: _ComparisonLabel(
                      text: 'Original (10 MB)',
                      visible: _position > 0.15,
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: _ComparisonLabel(
                      text: 'Compressed (1.2 MB)',
                      visible: _position < 0.85,
                    ),
                  ),
                  // Slider handle (2px white vertical line)
                  Positioned(
                    left: w * _position -
                        _BeforeAfterComparisonSlider._handleWidth / 2,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          width: _BeforeAfterComparisonSlider._handleWidth,
                          height: double.infinity,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ComparisonLabel extends StatelessWidget {
  const _ComparisonLabel({required this.text, required this.visible});

  final String text;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.35,
      duration: const Duration(milliseconds: 120),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
