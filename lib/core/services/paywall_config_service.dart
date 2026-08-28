
/// Paywall copy, fixed in the binary.
/// Paywall reads from here (v1 defaults until fetch completes).
class PaywallConfigService {

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
  // The paywall used to be fetched from a JSON file on our own web host,
  // so its copy could be changed after review without shipping anything.
  // Apple reads that as an app being controlled remotely. The values kept
  // below are the ones the server was actually serving, so nothing the
  // user sees changes; to alter the paywall now, edit it here and ship.
  static Future<void> fetch() async {}
}
