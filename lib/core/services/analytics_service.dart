import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PostHog analytics — wraps every event the app fires.
///
/// Coverage strategy: lots of small events with rich properties so we can see
/// where the funnel leaks without redeploying. Errors and unhandled
/// exceptions are auto-captured. Session replay is on (sampled by remote
/// config) so we can rewatch sessions when an event tells us something is off.
class AnalyticsService {
  static final _posthog = Posthog();
  static const _distinctIdKey = 'posthog_distinct_id';
  static const _projectToken = 'phc_AbxvrdNV7BPx59ERR4KEa5ZN9rFeMzxDfe5KGtzMAy3L';

  static String? _distinctId;
  static bool _initialized = false;

  // ── Init ────────────────────────────────────────────────────────────────
  static Future<void> init() async {
    if (_initialized) return;

    final config = PostHogConfig(_projectToken)
      ..host = 'https://us.i.posthog.com'
      ..debug = kDebugMode
      ..captureApplicationLifecycleEvents = true
      ..personProfiles = PostHogPersonProfiles.always
      ..sessionReplay = true
      ..flushAt = 10;

    config.sessionReplayConfig
      ..maskAllTexts = false
      ..maskAllImages = false
      ..throttleDelay = const Duration(milliseconds: 500);

    config.errorTrackingConfig
      ..captureFlutterErrors = true
      ..captureSilentFlutterErrors = false
      ..capturePlatformDispatcherErrors = true
      ..captureNativeExceptions = true
      ..captureIsolateErrors = true;

    await _posthog.setup(config);

    // Stable per-install distinct ID. Avoids the "everyone is anonymous"
    // problem that breaks funnel + retention analysis.
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_distinctIdKey);
    if (id == null) {
      id = await _posthog.getDistinctId();
      await prefs.setString(_distinctIdKey, id);
    }
    _distinctId = id;

    await _posthog.register('platform', Platform.operatingSystem);
    await _posthog.register('platform_version', Platform.operatingSystemVersion);

    _initialized = true;
  }

  static String? get distinctId => _distinctId;

  // ── Lifecycle ───────────────────────────────────────────────────────────
  static Future<void> appOpened({required bool isPro}) =>
      _capture('app_opened', {'is_pro': isPro});

  static Future<void> appBackgrounded() => _capture('app_backgrounded');
  static Future<void> appResumed() => _capture('app_resumed');

  static Future<void> setUserProperties({
    required bool isPro,
    required int totalCompressions,
    required double totalSavingsMB,
    required String planType,
  }) async {
    final id = _distinctId;
    if (id == null) return;
    await _posthog.identify(
      userId: id,
      userProperties: {
        'is_pro': isPro,
        'total_compressions': totalCompressions,
        'total_savings_mb': totalSavingsMB,
        'plan_type': planType,
        'platform': Platform.operatingSystem,
      },
    );
  }

  // ── Screens ─────────────────────────────────────────────────────────────
  static Future<void> screenViewed(String name, {Map<String, Object>? properties}) =>
      _posthog.screen(screenName: name, properties: properties);

  // ── Onboarding ──────────────────────────────────────────────────────────
  static Future<void> onboardingScreenViewed({required int index}) =>
      _capture('onboarding_screen_viewed', {'screen_index': index});

  static Future<void> onboardingNextTapped({required int fromIndex}) =>
      _capture('onboarding_next_tapped', {'from_index': fromIndex});

  static Future<void> onboardingNextBlocked({required int fromIndex, required int cooldownSec}) =>
      _capture('onboarding_next_blocked', {'from_index': fromIndex, 'cooldown_sec': cooldownSec});

  static Future<void> onboardingVideoStarted() => _capture('onboarding_video_started');
  static Future<void> onboardingVideoFailed({required String error}) =>
      _capture('onboarding_video_failed', {'error': error});

  static Future<void> onboardingSliderInteracted({required double position}) =>
      _capture('onboarding_slider_interacted', {'position': position});

  static Future<void> onboardingCompleted({required int durationSec}) =>
      _capture('onboarding_completed', {'duration_sec': durationSec});

  // ── Reviews ─────────────────────────────────────────────────────────────
  static Future<void> reviewPromptShown({String source = 'onboarding'}) =>
      _capture('review_prompt_shown', {'source': source});
  static Future<void> reviewPromptAccepted({String source = 'onboarding'}) =>
      _capture('review_prompt_accepted', {'source': source});
  static Future<void> reviewPromptDeclined({String source = 'onboarding'}) =>
      _capture('review_prompt_declined', {'source': source});
  static Future<void> nativeReviewRequested({String source = 'compression'}) =>
      _capture('native_review_requested', {'source': source});

  // ── Paywall ─────────────────────────────────────────────────────────────
  static Future<void> paywallViewed({required String source, String? version}) =>
      _capture('paywall_viewed', {
        'source': source,
        if (version != null) 'paywall_version': version,
      });

  static Future<void> paywallOfferingsLoaded({required int productCount}) =>
      _capture('paywall_offerings_loaded', {'product_count': productCount});

  static Future<void> paywallOfferingsFailed({required String error}) =>
      _capture('paywall_offerings_failed', {'error': error});

  static Future<void> paywallPlanSelected({required String plan}) =>
      _capture('paywall_plan_selected', {'plan': plan});

  static Future<void> paywallPurchaseTapped({required String plan}) =>
      _capture('paywall_purchase_tapped', {'plan': plan});

  static Future<void> paywallPurchaseCompleted({required String plan}) =>
      _capture('paywall_purchase_completed', {'plan': plan});

  static Future<void> paywallPurchaseCancelled({required String plan}) =>
      _capture('paywall_purchase_cancelled', {'plan': plan});

  static Future<void> paywallPurchaseFailed({required String plan, required String error}) =>
      _capture('paywall_purchase_failed', {'plan': plan, 'error': error});

  static Future<void> paywallRestoreTapped() => _capture('paywall_restore_tapped');
  static Future<void> paywallRestoreSucceeded() => _capture('paywall_restore_succeeded');
  static Future<void> paywallRestoreFailed({required String error}) =>
      _capture('paywall_restore_failed', {'error': error});
  static Future<void> paywallRestoreEmpty() => _capture('paywall_restore_empty');

  static Future<void> paywallTermsTapped({required String type}) =>
      _capture('paywall_terms_tapped', {'type': type});

  static Future<void> paywallClosed({required int timeOnPaywallSec, required String selectedPlan, required String source}) =>
      _capture('paywall_closed', {
        'time_on_paywall_sec': timeOnPaywallSec,
        'selected_plan': selectedPlan,
        'source': source,
      });

  // ── Compression ─────────────────────────────────────────────────────────
  static Future<void> filePickerOpened({String source = 'home'}) =>
      _capture('file_picker_opened', {'source': source});

  static Future<void> filePickerSourceSelected({required String pickerSource, String source = 'home'}) =>
      _capture('file_picker_source_selected', {'picker_source': pickerSource, 'source': source});

  static Future<void> filePickerCancelled({String source = 'home'}) =>
      _capture('file_picker_cancelled', {'source': source});

  static Future<void> filePickerFailed({required String error, String source = 'home'}) =>
      _capture('file_picker_failed', {'error': error, 'source': source});

  static Future<void> filesSelected({
    required int count,
    required List<String> types,
    required double totalSizeMB,
    String source = 'home',
  }) =>
      _capture('files_selected', {
        'count': count,
        'types': types,
        'total_size_mb': totalSizeMB,
        'source': source,
      });

  static Future<void> compressionOptionsViewed() => _capture('compression_options_viewed');

  static Future<void> compressionPresetTapped({required String preset}) =>
      _capture('compression_preset_tapped', {'preset': preset});
  static Future<void> compressionOptionsCancelled() => _capture('compression_options_cancelled');

  static Future<void> compressionOptionsConfirmed({
    required String preset,
    required bool bundleFiles,
    required bool bulkConversion,
  }) =>
      _capture('compression_options_confirmed', {
        'preset': preset,
        'bundle_files': bundleFiles,
        'bulk_conversion': bulkConversion,
      });

  static Future<void> compressionStarted({
    required String preset,
    required int fileCount,
    required List<String> types,
    required double totalSizeMB,
  }) =>
      _capture('compression_started', {
        'preset': preset,
        'file_count': fileCount,
        'types': types,
        'total_size_mb': totalSizeMB,
      });

  static Future<void> compressionCompleted({
    required String preset,
    required int fileCount,
    required List<String> types,
    required double originalMB,
    required double compressedMB,
    required double savingsPercent,
    required int durationSec,
  }) =>
      _capture('compression_completed', {
        'preset': preset,
        'file_count': fileCount,
        'types': types,
        'original_mb': originalMB,
        'compressed_mb': compressedMB,
        'savings_percent': savingsPercent,
        'duration_sec': durationSec,
      });

  static Future<void> compressionFailed({
    required String preset,
    required List<String> types,
    required String error,
  }) =>
      _capture('compression_failed', {'preset': preset, 'types': types, 'error': error});

  static Future<void> compressionCancelled({String reason = 'user'}) =>
      _capture('compression_cancelled', {'reason': reason});

  // ── Results ─────────────────────────────────────────────────────────────
  static Future<void> resultsViewed({required int fileCount, required double avgSavings}) =>
      _capture('results_viewed', {'file_count': fileCount, 'avg_savings': avgSavings});

  static Future<void> fileOpened({String source = 'results'}) =>
      _capture('file_opened', {'source': source});

  static Future<void> fileShared({String source = 'results'}) =>
      _capture('file_shared', {'source': source});

  static Future<void> savingsShared() => _capture('savings_shared');

  static Future<void> featureGateHit({required String feature}) =>
      _capture('feature_gate_hit', {'feature': feature});

  // ── History ─────────────────────────────────────────────────────────────
  static Future<void> historyViewed({required int itemCount}) =>
      _capture('history_viewed', {'item_count': itemCount});

  static Future<void> historyItemDeleted() => _capture('history_item_deleted');

  static Future<void> historyCleared({required int itemCount}) =>
      _capture('history_cleared', {'item_count': itemCount});

  static Future<void> historyOpenTapped() => _capture('history_open_tapped');

  // ── Errors ──────────────────────────────────────────────────────────────
  static Future<void> errorOccurred({
    required String location,
    required String error,
  }) =>
      _capture('error_occurred', {'location': location, 'error': error});

  static Future<void> exceptionCaptured(Object error, StackTrace? stack) =>
      _posthog.captureException(error: error, stackTrace: stack);

  // ── Internal ────────────────────────────────────────────────────────────
  static Future<void> _capture(String name, [Map<String, Object>? props]) async {
    try {
      await _posthog.capture(eventName: name, properties: props);
    } catch (_) {
      // Never let analytics crash the app.
    }
  }
}
