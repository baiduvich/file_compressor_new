import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetched at app start from https://greensharkapp.com/file_compressor.json
/// Paywall reads from here (v1 defaults until fetch completes).
class PaywallConfigService {
  static const String _url = 'https://greensharkapp.com/file_compressor.json';

  static String _version = 'v1';
  static String _v2LifetimeTitle = 'Lifetime Plan';
  static String _v2LifetimeSubtitle = '\$14.99 for lifetime access';
  static String _v2LifetimeChipText = 'SAVE 90%';
  static String _v2WeeklyTitle = '3-Day Trial';
  static String _v2WeeklySubtitleFallback = 'then \$4.99 per week';
  static String _v2LifetimeButtonText = 'Unlock Now';
  static String _v2WeeklyButtonText = 'Start Free Trial';
  static bool _showFreeTrialToggle = true;

  static String get version => _version;
  static String get v2LifetimeTitle => _v2LifetimeTitle;
  static String get v2LifetimeSubtitle => _v2LifetimeSubtitle;
  static String get v2LifetimeChipText => _v2LifetimeChipText;
  static String get v2WeeklyTitle => _v2WeeklyTitle;
  static String get v2WeeklySubtitleFallback => _v2WeeklySubtitleFallback;
  static String get v2LifetimeButtonText => _v2LifetimeButtonText;
  static String get v2WeeklyButtonText => _v2WeeklyButtonText;
  static bool get showFreeTrialToggle => _showFreeTrialToggle;

  /// Call once when app opens (e.g. from main).
  static Future<void> fetch() async {
    try {
      final response = await http.get(Uri.parse(_url)).timeout(
        const Duration(seconds: 5),
      );
      if (response.statusCode != 200) return;
      final data = json.decode(response.body) as Map<String, dynamic>?;
      if (data == null) return;

      _showFreeTrialToggle = data['showFreeTrialToggle'] as bool? ?? true;

      final version = data['version'] as String?;
      if (version != 'v2') return;

      final v2 = data['v2'] as Map<String, dynamic>?;
      if (v2 == null) return;

      _version = 'v2';
      _v2LifetimeTitle = v2['lifetimeTitle'] as String? ?? _v2LifetimeTitle;
      _v2LifetimeSubtitle = v2['lifetimeSubtitle'] as String? ?? _v2LifetimeSubtitle;
      _v2LifetimeChipText = v2['lifetimeChipText'] as String? ?? _v2LifetimeChipText;
      _v2WeeklyTitle = v2['weeklyTitle'] as String? ?? _v2WeeklyTitle;
      _v2WeeklySubtitleFallback = v2['weeklySubtitleFallback'] as String? ?? _v2WeeklySubtitleFallback;
      _v2LifetimeButtonText = v2['lifetimeButtonText'] as String? ?? _v2LifetimeButtonText;
      _v2WeeklyButtonText = v2['weeklyButtonText'] as String? ?? _v2WeeklyButtonText;
    } catch (_) {
      // Keep defaults
    }
  }
}
