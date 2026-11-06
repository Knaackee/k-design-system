import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../generated/k_icons.g.dart';
export '../generated/k_icons.g.dart' show KIconName, kIconLabels;

class KIconSizeScope extends InheritedWidget {
  const KIconSizeScope({required this.size, required super.child, super.key});

  final double size;

  static double? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KIconSizeScope>()?.size;

  @override
  bool updateShouldNotify(KIconSizeScope oldWidget) => size != oldWidget.size;
}

/// Turns off text scaling for icons below (tab bar glyphs, control glyphs),
/// as iOS keeps tab bar symbols at one size.
class KIconFixedScope extends InheritedWidget {
  const KIconFixedScope({required super.child, super.key});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KIconFixedScope>() != null;

  @override
  bool updateShouldNotify(KIconFixedScope oldWidget) => false;
}

/// Scale factor of text-adjacent icons: the system text scale, capped at
/// `text.scaleMax.icon` (2×). Use it for boxes that hold an icon.
double kIconScale(BuildContext context) {
  if (KIconFixedScope.of(context)) return 1;
  final tokens =
      Theme.of(context).extension<KDesignTokens>() ?? KDesignTokens.orbitLight;
  return MediaQuery.textScalerOf(
    context,
  ).clamp(maxScaleFactor: tokens.textScaleMaxIcon).scale(1);
}

class KIcon extends StatelessWidget {
  const KIcon(
    this.name, {
    this.size = 16,
    this.strokeWidth,
    this.color,
    this.label,
    super.key,
  });
  final KIconName name;
  final double size;

  /// Stroke in the icon's 24-unit grid. Leave it unset: the style's
  /// `size.iconStroke` then draws the same screen stroke at every size
  /// (Decision 0015). App code must not set it (UI rule gate).
  final double? strokeWidth;
  final Color? color;

  /// Omit for decorative icons; label meaningful standalone icons.
  final String? label;
  @override
  Widget build(BuildContext context) {
    final base = KIconSizeScope.maybeOf(context) ?? size;
    // Text-adjacent icons (16–24) grow with the text; control glyphs (12)
    // and display icons (32, 48) keep their size (Decision 0015).
    final resolvedSize = base >= 16 && base <= 24
        ? base * kIconScale(context)
        : base;
    if (!resolvedSize.isFinite || resolvedSize <= 0) {
      throw ArgumentError.value(
        resolvedSize,
        'size',
        'Must be positive and finite',
      );
    }
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    if (strokeWidth != null && (!strokeWidth!.isFinite || strokeWidth! <= 0)) {
      throw ArgumentError.value(
        strokeWidth,
        'strokeWidth',
        'Must be positive and finite',
      );
    }
    // Absolute stroke: the token is in screen pixels, the SVG grid is 24.
    // Measured at the base size, so a text-scaled icon grows its stroke with
    // it, as SF Symbols do and as the Web mask does.
    final stroke = strokeWidth ?? tokens.sizeIconStroke * 24 / base;
    final svg = kIconSvg[name]!.replaceAll(
      RegExp('stroke-width="[^"]*"'),
      'stroke-width="${stroke.toStringAsFixed(3)}"',
    );
    return SvgPicture.string(
      svg,
      width: resolvedSize,
      height: resolvedSize,
      colorFilter: ColorFilter.mode(
        color ?? tokens.colorTextPrimary,
        BlendMode.srcIn,
      ),
      semanticsLabel: label,
      excludeFromSemantics: label == null || label!.isEmpty,
    );
  }
}
