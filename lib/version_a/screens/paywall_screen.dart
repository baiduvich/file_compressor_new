import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/paywall_config_service.dart';
import 'home_screen.dart';

enum Plan { lifetime, weekly }

const ENTITLEMENT_ID = 'pro1';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with SingleTickerProviderStateMixin {
  Plan selected = Plan.weekly;
  bool showLoadingBar = false;
  bool showCloseButton = false;
  double loadingProgress = 0.0;
  Timer? _progressTimer;

  Package? _subPackage;
  Package? _lifetimePackage;
  bool _loading = true;

  bool get isWeekly => selected == Plan.weekly;
  bool get freeTrialEnabled => isWeekly;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
    Purchases.addCustomerInfoUpdateListener((info) {
      final isPro = info.entitlements.active.containsKey(ENTITLEMENT_ID);
      if (isPro && mounted) {
        // Defer navigation until after build phase
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _goSuccess();
        });
      }
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => showLoadingBar = true);
      const total = 30;
      int tick = 0;
      _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
        tick++;
        if (!mounted) return;
        setState(() => loadingProgress = tick / total);
        if (tick >= total) t.cancel();
      });
    });
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        showCloseButton = true;
        showLoadingBar = false;
      });
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOfferings() async {
    setState(() {
      _loading = true;
    });
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      setState(() {
        _subPackage = current?.weekly ?? current?.monthly ?? current?.annual;
        _lifetimePackage = current?.lifetime;
      });
    } catch (e) {
      _showError('Failed to load products: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _buySelected() async {
    final pkg = (selected == Plan.lifetime) ? _lifetimePackage : _subPackage;
    if (pkg == null) {
      _showError('Selected product unavailable. Please try again later.');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await Purchases.purchasePackage(pkg);
      final info = result.customerInfo;
      final isPro = info.entitlements.active.containsKey(ENTITLEMENT_ID);
      if (!mounted) return;
      if (isPro) {
        // Defer navigation until after build phase
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _goSuccess();
        });
      } else {
        _showSnack('Purchase pending…');
      }
    } on PurchasesErrorCode {
      // User cancelled
    } catch (e) {
      _showError('Purchase failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _loading = true);
    try {
      final info = await Purchases.restorePurchases();
      final isPro = info.entitlements.active.containsKey(ENTITLEMENT_ID);
      if (!mounted) return;
      if (isPro) {
        // Defer navigation until after build phase
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _goSuccess();
        });
      } else {
        _showSnack('No previous purchases found.');
      }
    } catch (e) {
      _showError('Restore failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goSuccess() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showError(String msg) {
    _showSnack(msg);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool canBuyWeekly = _subPackage != null && !_loading;
    final bool canBuyLifetime = _lifetimePackage != null && !_loading;
    final bool ctaEnabled =
        (selected == Plan.weekly) ? canBuyWeekly : canBuyLifetime;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Image.asset(
                    'assets/images/paywall_banner.png',
                    height: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.compress,
                        size: 80,
                        color: AppColors.primary,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Fixed Title
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Compress ',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        const TextSpan(
                          text: 'Any File. No Limits. High Quality.',
                          style: TextStyle(
                            color: Colors.yellow,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Fixed Feature Bullets
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FeatureRow(
                            icon: Icons.all_inclusive,
                            rich: TextSpan(
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                              children: [
                                TextSpan(text: 'Compress '),
                                TextSpan(
                                  text: 'UNLIMITED',
                                  style: TextStyle(
                                      color: Colors.yellow,
                                      fontWeight: FontWeight.w800),
                                ),
                                TextSpan(text: ' files — no size stress!'),
                              ],
                            ),
                          ),
                          SizedBox(height: 12),
                          _FeatureRow(
                            icon: Icons.high_quality,
                            rich: TextSpan(
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                              children: [
                                TextSpan(text: 'Preserve '),
                                TextSpan(
                                  text: 'QUALITY',
                                  style: TextStyle(
                                      color: Colors.yellow,
                                      fontWeight: FontWeight.w800),
                                ),
                                TextSpan(text: ' without a big size!'),
                              ],
                            ),
                          ),
                          SizedBox(height: 12),
                          _FeatureRow(
                            icon: Icons.tune,
                            rich: TextSpan(
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                              children: [
                                TextSpan(text: 'Choose the compression level that '),
                                TextSpan(
                                  text: 'FITS YOUR NEEDS!',
                                  style: TextStyle(
                                      color: Colors.yellow,
                                      fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12),
                          _FeatureRow(
                            icon: Icons.verified_user,
                            rich: TextSpan(
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                              children: [
                                TextSpan(text: 'Try it '),
                                TextSpan(
                                  text: 'FOR FREE',
                                  style: TextStyle(
                                      color: Colors.yellow,
                                      fontWeight: FontWeight.w800),
                                ),
                                TextSpan(text: '. Cancel anytime — '),
                                TextSpan(
                                  text: 'NO RISK AT ALL!',
                                  style: TextStyle(
                                      color: Colors.yellow,
                                      fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Plans (v1 = hardcoded, v2 = from remote JSON, read at app start)
                  _PlanCard(
                    title: PaywallConfigService.version == 'v2' ? PaywallConfigService.v2LifetimeTitle : 'Lifetime Plan',
                    subtitle: PaywallConfigService.version == 'v2' ? PaywallConfigService.v2LifetimeSubtitle : '\$14.99 for lifetime access',
                    selected: selected == Plan.lifetime,
                    chipText: PaywallConfigService.version == 'v2' ? PaywallConfigService.v2LifetimeChipText : 'SAVE 90%',
                    onTap: () => setState(() => selected = Plan.lifetime),
                  ),
                  const SizedBox(height: 12),
                  _PlanCard(
                    title: PaywallConfigService.version == 'v2' ? PaywallConfigService.v2WeeklyTitle : '3-Day Trial',
                    subtitle: _subPackage != null
                        ? 'then ${_subPackage!.storeProduct.priceString} per week'
                        : (PaywallConfigService.version == 'v2' ? PaywallConfigService.v2WeeklySubtitleFallback : 'then \$4.99 per week'),
                    selected: selected == Plan.weekly,
                    onTap: () => setState(() => selected = Plan.weekly),
                  ),

                  if (PaywallConfigService.showFreeTrialToggle) ...[
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile.adaptive(
                        value: isWeekly,
                        onChanged: (val) {
                          setState(() {
                            selected = val ? Plan.weekly : Plan.lifetime;
                          });
                        },
                        title: const Text(
                          'Free Trial Enabled',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  SizedBox(
                    width: width,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: ctaEnabled ? _buySelected : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            selected == Plan.lifetime
                              ? (PaywallConfigService.version == 'v2' ? PaywallConfigService.v2LifetimeButtonText : 'Unlock Now')
                              : (PaywallConfigService.version == 'v2' ? PaywallConfigService.v2WeeklyButtonText : 'Start Free Trial'),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_right_alt_rounded, size: 35),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: _loading ? null : _restore,
                              child: const Text('Restore',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ),
                            const SizedBox(width: 20),
                            TextButton(
                              onPressed: () => _openUrl(
                                  'https://sites.google.com/view/xmleula/home'),
                              child: const Text('Terms of Use EULA',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ),
                            const SizedBox(width: 20),
                            TextButton(
                              onPressed: () => _openUrl(
                                  'https://sites.google.com/view/odtconverterreader/home'),
                              child: const Text('Privacy Policy',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            // loader / close button
            Padding(
              padding: const EdgeInsets.only(top: 8.0, right: 8.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: showCloseButton
                    ? IconButton(
                        key: const ValueKey('close'),
                        onPressed: _loading
                            ? null
                            : () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                                  (route) => false,
                                );
                              },
                        icon: Icon(
                          Icons.cancel_rounded,
                          color: Colors.white.withOpacity(0.85),
                          size: 28,
                        ),
                      )
                    : (showLoadingBar
                        ? SizedBox(
                            key: const ValueKey('loader'),
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              value: loadingProgress.clamp(0.0, 1.0),
                              strokeWidth: 3,
                              color: AppColors.primary,
                              backgroundColor: Colors.white.withOpacity(0.15),
                            ),
                          )
                        : const SizedBox.shrink()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String? text; // legacy usage
  final InlineSpan? rich; // new rich text with bold/yellow parts
  const _FeatureRow({required this.icon, this.text, this.rich})
      : assert(text != null || rich != null);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 28,
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: (rich != null)
              ? Text.rich(rich!)
              : Text(
                  text!,
                  textAlign: TextAlign.left,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? chipText;
  final bool selected;
  final VoidCallback onTap;
  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.chipText,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.primary : Colors.white.withOpacity(0.18);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: selected ? Colors.white.withOpacity(0.04) : Colors.transparent,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          children: [
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7), fontSize: 14)),
                ],
              ),
            ),
            if (chipText != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                child: Text(chipText!,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, height: 1)),
              ),
              const SizedBox(width: 10),
            ],
            Icon(selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? AppColors.primary : Colors.grey, size: 24),
          ],
        ),
      ),
    );
  }
}
