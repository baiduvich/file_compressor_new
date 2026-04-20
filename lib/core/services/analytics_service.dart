import 'package:posthog_flutter/posthog_flutter.dart';

class AnalyticsService {
  static final _posthog = Posthog();

  // ── Init ──────────────────────────────────────────────────────────────────
  static Future<void> init() async {
    final config = PostHogConfig('phc_AbxvrdNV7BPx59ERR4KEa5ZN9rFeMzxDfe5KGtzMAy3L');
    config.host = 'https://us.i.posthog.com';
    config.debug = false;
    await _posthog.setup(config);
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  static Future<void> appOpened({required bool isPro}) async {
    await _posthog.capture(
      eventName: 'app_opened',
      properties: {'is_pro': isPro},
    );
  }

  static Future<void> setUserProperties({
    required bool isPro,
    required int totalCompressions,
    required double totalSavingsMB,
    required String planType,
  }) async {
    await _posthog.identify(
      userId: 'anonymous',
      userProperties: {
        'is_pro': isPro,
        'total_compressions': totalCompressions,
        'total_savings_mb': totalSavingsMB,
        'plan_type': planType,
      },
    );
  }

  // ── Onboarding ────────────────────────────────────────────────────────────
  static Future<void> onboardingScreenViewed({required int index}) async {
    await _posthog.capture(
      eventName: 'onboarding_screen_viewed',
      properties: {'screen_index': index},
    );
  }

  static Future<void> onboardingCompleted({required int durationSec}) async {
    await _posthog.capture(
      eventName: 'onboarding_completed',
      properties: {'duration_sec': durationSec},
    );
  }

  static Future<void> reviewPromptShown() async {
    await _posthog.capture(eventName: 'review_prompt_shown');
  }

  static Future<void> reviewPromptAccepted() async {
    await _posthog.capture(eventName: 'review_prompt_accepted');
  }

  static Future<void> reviewPromptDeclined() async {
    await _posthog.capture(eventName: 'review_prompt_declined');
  }

  // ── Paywall ───────────────────────────────────────────────────────────────
  static Future<void> paywallViewed({required String source}) async {
    await _posthog.capture(
      eventName: 'paywall_viewed',
      properties: {'source': source},
    );
  }

  static Future<void> paywallPlanSelected({required String plan}) async {
    await _posthog.capture(
      eventName: 'paywall_plan_selected',
      properties: {'plan': plan},
    );
  }

  static Future<void> paywallPurchaseTapped({required String plan}) async {
    await _posthog.capture(
      eventName: 'paywall_purchase_tapped',
      properties: {'plan': plan},
    );
  }

  static Future<void> paywallPurchaseCompleted({required String plan}) async {
    await _posthog.capture(
      eventName: 'paywall_purchase_completed',
      properties: {'plan': plan},
    );
  }

  static Future<void> paywallPurchaseFailed({
    required String plan,
    required String error,
  }) async {
    await _posthog.capture(
      eventName: 'paywall_purchase_failed',
      properties: {'plan': plan, 'error': error},
    );
  }

  static Future<void> paywallRestoreTapped() async {
    await _posthog.capture(eventName: 'paywall_restore_tapped');
  }

  static Future<void> paywallClosed({required int timeOnPaywallSec}) async {
    await _posthog.capture(
      eventName: 'paywall_closed',
      properties: {'time_on_paywall_sec': timeOnPaywallSec},
    );
  }

  // ── Compression ───────────────────────────────────────────────────────────
  static Future<void> filePickerOpened({String source = 'home'}) async {
    await _posthog.capture(
      eventName: 'file_picker_opened',
      properties: {'source': source},
    );
  }

  static Future<void> filesSelected({
    required int count,
    required List<String> types,
    required double totalSizeMB,
  }) async {
    await _posthog.capture(
      eventName: 'files_selected',
      properties: {
        'count': count,
        'types': types,
        'total_size_mb': totalSizeMB,
      },
    );
  }

  static Future<void> compressionStarted({
    required String preset,
    required int fileCount,
    required List<String> types,
    required double totalSizeMB,
  }) async {
    await _posthog.capture(
      eventName: 'compression_started',
      properties: {
        'preset': preset,
        'file_count': fileCount,
        'types': types,
        'total_size_mb': totalSizeMB,
      },
    );
  }

  static Future<void> compressionCompleted({
    required String preset,
    required int fileCount,
    required List<String> types,
    required double originalMB,
    required double compressedMB,
    required double savingsPercent,
    required int durationSec,
  }) async {
    await _posthog.capture(
      eventName: 'compression_completed',
      properties: {
        'preset': preset,
        'file_count': fileCount,
        'types': types,
        'original_mb': originalMB,
        'compressed_mb': compressedMB,
        'savings_percent': savingsPercent,
        'duration_sec': durationSec,
      },
    );
  }

  static Future<void> compressionFailed({
    required String preset,
    required List<String> types,
    required String error,
  }) async {
    await _posthog.capture(
      eventName: 'compression_failed',
      properties: {'preset': preset, 'types': types, 'error': error},
    );
  }

  static Future<void> compressionCancelled() async {
    await _posthog.capture(eventName: 'compression_cancelled');
  }

  // ── Results ───────────────────────────────────────────────────────────────
  static Future<void> fileOpened() async {
    await _posthog.capture(eventName: 'file_opened');
  }

  static Future<void> fileShared({String source = 'results'}) async {
    await _posthog.capture(
      eventName: 'file_shared',
      properties: {'source': source},
    );
  }

  static Future<void> savingsShared() async {
    await _posthog.capture(eventName: 'savings_shared');
  }

  static Future<void> featureGateHit({required String feature}) async {
    await _posthog.capture(
      eventName: 'feature_gate_hit',
      properties: {'feature': feature},
    );
  }

  // ── History ───────────────────────────────────────────────────────────────
  static Future<void> historyViewed({required int itemCount}) async {
    await _posthog.capture(
      eventName: 'history_viewed',
      properties: {'item_count': itemCount},
    );
  }

  static Future<void> historyItemDeleted() async {
    await _posthog.capture(eventName: 'history_item_deleted');
  }

  static Future<void> historyCleared({required int itemCount}) async {
    await _posthog.capture(
      eventName: 'history_cleared',
      properties: {'item_count': itemCount},
    );
  }
}
