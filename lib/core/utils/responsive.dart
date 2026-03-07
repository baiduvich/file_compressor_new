import 'package:flutter/material.dart';

/// Responsive scaling so the app looks proportional on all iPhone sizes.
/// Text uses these base sizes; Flutter applies MediaQuery.textScaleFactor automatically.
class Responsive {
  Responsive._();

  static Size _size(BuildContext context) => MediaQuery.sizeOf(context);

  /// Screen width.
  static double width(BuildContext context) => _size(context).width;

  /// Screen height.
  static double height(BuildContext context) => _size(context).height;

  /// Scalable font size: (screenWidth * ratio).clamp(min, max).
  /// Use for body, title, headline, etc. with appropriate ratio and clamps.
  static double fontSize(
    BuildContext context, {
    double ratio = 0.045,
    double min = 14,
    double max = 24,
  }) {
    final w = width(context);
    return (w * ratio).clamp(min, max);
  }

  /// Body / subtitle text.
  static double body(BuildContext context) =>
      fontSize(context, ratio: 0.038, min: 13, max: 18);

  /// Small caption.
  static double bodySmall(BuildContext context) =>
      fontSize(context, ratio: 0.032, min: 11, max: 15);

  /// Card title / section title.
  static double title(BuildContext context) =>
      fontSize(context, ratio: 0.042, min: 15, max: 20);

  /// Large title (e.g. screen title).
  static double titleLarge(BuildContext context) =>
      fontSize(context, ratio: 0.05, min: 18, max: 26);

  /// Headline / hero number.
  static double headline(BuildContext context) =>
      fontSize(context, ratio: 0.055, min: 20, max: 32);

  /// Display (splash, big numbers).
  static double display(BuildContext context) =>
      fontSize(context, ratio: 0.07, min: 24, max: 40);

  /// Empty state / splash illustration: 30% of screen height, capped so not stretched on iPad.
  static double emptyStateSize(BuildContext context) {
    final h = height(context);
    const minSize = 80.0;
    const maxSize = 220.0;
    return (h * 0.30).clamp(minSize, maxSize);
  }
}
