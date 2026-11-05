import 'package:flutter/material.dart';

import 'generated/k_design_tokens.g.dart';
import 'k_page_transitions.dart';

enum KBrand { orbit, reference }

enum KDensity { dense, standard, spacious }

/// Type ramp. [mobile] is the phone ramp (compact window class): smaller
/// headings, 16 px body and 16 px controls.
enum KTypeScale { compact, standard, mobile, apple }

enum KInputMode { pointer, touch }

enum KWindowClass { compact, medium, expanded, large, extraLarge }

/// Motion style (Decision 0011). [apple]: calm springs without bounce.
/// [expressive]: Material Expressive-like springs with bounce on spatial
/// motion. [reduced]: short cross-fades without movement; chosen
/// automatically when the platform asks to reduce motion.
enum KMotionStyle { apple, expressive, reduced }

/// Style preset (Decision 0014): structure and rhythm of components, not
/// colours. [linear]: compact productivity look (default). [apple]: iOS/iPadOS
/// Human Interface Guidelines: 44 pt rows, inset grouped lists, large titles.
enum KStyle { linear, apple }

typedef KDesignTokenTransform = KDesignTokens Function(KDesignTokens tokens);

@immutable
class KDesignConfiguration {
  const KDesignConfiguration({
    this.density = KDensity.standard,
    this.typeScale = KTypeScale.compact,
    this.inputMode = KInputMode.pointer,
    this.windowClass = KWindowClass.compact,
    this.motion = KMotionStyle.apple,
    this.style = KStyle.linear,
  });

  final KDensity density;
  final KTypeScale typeScale;
  final KInputMode inputMode;
  final KWindowClass windowClass;
  final KMotionStyle motion;
  final KStyle style;

  @override
  bool operator ==(Object other) =>
      other is KDesignConfiguration &&
      other.density == density &&
      other.typeScale == typeScale &&
      other.inputMode == inputMode &&
      other.windowClass == windowClass &&
      other.motion == motion &&
      other.style == style;

  @override
  int get hashCode =>
      Object.hash(density, typeScale, inputMode, windowClass, motion, style);

  /// Explicit opt-in for data-dense desktop screens (tables, admin).
  static const dashboard = KDesignConfiguration(density: KDensity.dense);

  /// Tablet and desktop share the standard ramp (parity rule).
  static const desktopApp = KDesignConfiguration(
    typeScale: KTypeScale.standard,
  );

  /// Phone context: standard density, phone type ramp, touch targets.
  /// Prefer [KAdaptiveTheme], which resolves this from the window.
  static const mobileApp = KDesignConfiguration(
    typeScale: KTypeScale.mobile,
    inputMode: KInputMode.touch,
  );

  static const marketing = KDesignConfiguration(
    density: KDensity.spacious,
    typeScale: KTypeScale.standard,
  );
}

KWindowClass kWindowClassForWidth(double width) {
  if (width < 600) return KWindowClass.compact;
  if (width < 840) return KWindowClass.medium;
  if (width < 1200) return KWindowClass.expanded;
  if (width < 1600) return KWindowClass.large;
  return KWindowClass.extraLarge;
}

KDesignTokens resolveKDesignTokens(
  KDesignTokens base,
  KDesignConfiguration configuration,
) {
  final (
    controlGap,
    controlInsetInline,
    controlSize,
    actionGap,
    cardPadding,
    sectionGap,
  ) = switch (configuration.density) {
    KDensity.dense => (
      KDesignTokenVariants.densityDenseSpaceControlGap,
      KDesignTokenVariants.densityDenseSpaceControlInsetInline,
      KDesignTokenVariants.densityDenseSizeControl,
      KDesignTokenVariants.densityDenseSpaceContentActionGap,
      KDesignTokenVariants.densityDenseSpaceCardPadding,
      KDesignTokenVariants.densityDenseSpaceLayoutSectionGap,
    ),
    KDensity.standard => (
      KDesignTokenVariants.densityStandardSpaceControlGap,
      KDesignTokenVariants.densityStandardSpaceControlInsetInline,
      KDesignTokenVariants.densityStandardSizeControl,
      KDesignTokenVariants.densityStandardSpaceContentActionGap,
      KDesignTokenVariants.densityStandardSpaceCardPadding,
      KDesignTokenVariants.densityStandardSpaceLayoutSectionGap,
    ),
    KDensity.spacious => (
      KDesignTokenVariants.densitySpaciousSpaceControlGap,
      KDesignTokenVariants.densitySpaciousSpaceControlInsetInline,
      KDesignTokenVariants.densitySpaciousSizeControl,
      KDesignTokenVariants.densitySpaciousSpaceContentActionGap,
      KDesignTokenVariants.densitySpaciousSpaceCardPadding,
      KDesignTokenVariants.densitySpaciousSpaceLayoutSectionGap,
    ),
  };

  final moved = switch (configuration.motion) {
    KMotionStyle.apple => base.copyWith(
      motionFeedbackDuration:
          KDesignTokenVariants.motionAppleMotionFeedbackDuration,
      motionFeedbackBounce:
          KDesignTokenVariants.motionAppleMotionFeedbackBounce,
      motionFeedbackDistance:
          KDesignTokenVariants.motionAppleMotionFeedbackDistance,
      motionControlDuration:
          KDesignTokenVariants.motionAppleMotionControlDuration,
      motionControlBounce: KDesignTokenVariants.motionAppleMotionControlBounce,
      motionControlDistance:
          KDesignTokenVariants.motionAppleMotionControlDistance,
      motionEnterDuration: KDesignTokenVariants.motionAppleMotionEnterDuration,
      motionEnterBounce: KDesignTokenVariants.motionAppleMotionEnterBounce,
      motionEnterDistance: KDesignTokenVariants.motionAppleMotionEnterDistance,
      motionExitDuration: KDesignTokenVariants.motionAppleMotionExitDuration,
      motionExitBounce: KDesignTokenVariants.motionAppleMotionExitBounce,
      motionExitDistance: KDesignTokenVariants.motionAppleMotionExitDistance,
      motionPageDuration: KDesignTokenVariants.motionAppleMotionPageDuration,
      motionPageBounce: KDesignTokenVariants.motionAppleMotionPageBounce,
      motionPageDistance: KDesignTokenVariants.motionAppleMotionPageDistance,
      motionAttentionDuration:
          KDesignTokenVariants.motionAppleMotionAttentionDuration,
      motionAttentionBounce:
          KDesignTokenVariants.motionAppleMotionAttentionBounce,
      motionAttentionDistance:
          KDesignTokenVariants.motionAppleMotionAttentionDistance,
    ),
    KMotionStyle.expressive => base.copyWith(
      motionFeedbackDuration:
          KDesignTokenVariants.motionExpressiveMotionFeedbackDuration,
      motionFeedbackBounce:
          KDesignTokenVariants.motionExpressiveMotionFeedbackBounce,
      motionFeedbackDistance:
          KDesignTokenVariants.motionExpressiveMotionFeedbackDistance,
      motionControlDuration:
          KDesignTokenVariants.motionExpressiveMotionControlDuration,
      motionControlBounce:
          KDesignTokenVariants.motionExpressiveMotionControlBounce,
      motionControlDistance:
          KDesignTokenVariants.motionExpressiveMotionControlDistance,
      motionEnterDuration:
          KDesignTokenVariants.motionExpressiveMotionEnterDuration,
      motionEnterBounce: KDesignTokenVariants.motionExpressiveMotionEnterBounce,
      motionEnterDistance:
          KDesignTokenVariants.motionExpressiveMotionEnterDistance,
      motionExitDuration:
          KDesignTokenVariants.motionExpressiveMotionExitDuration,
      motionExitBounce: KDesignTokenVariants.motionExpressiveMotionExitBounce,
      motionExitDistance:
          KDesignTokenVariants.motionExpressiveMotionExitDistance,
      motionPageDuration:
          KDesignTokenVariants.motionExpressiveMotionPageDuration,
      motionPageBounce: KDesignTokenVariants.motionExpressiveMotionPageBounce,
      motionPageDistance:
          KDesignTokenVariants.motionExpressiveMotionPageDistance,
      motionAttentionDuration:
          KDesignTokenVariants.motionExpressiveMotionAttentionDuration,
      motionAttentionBounce:
          KDesignTokenVariants.motionExpressiveMotionAttentionBounce,
      motionAttentionDistance:
          KDesignTokenVariants.motionExpressiveMotionAttentionDistance,
    ),
    KMotionStyle.reduced => base.copyWith(
      motionFeedbackDuration:
          KDesignTokenVariants.motionReducedMotionFeedbackDuration,
      motionFeedbackBounce:
          KDesignTokenVariants.motionReducedMotionFeedbackBounce,
      motionFeedbackDistance:
          KDesignTokenVariants.motionReducedMotionFeedbackDistance,
      motionControlDuration:
          KDesignTokenVariants.motionReducedMotionControlDuration,
      motionControlBounce:
          KDesignTokenVariants.motionReducedMotionControlBounce,
      motionControlDistance:
          KDesignTokenVariants.motionReducedMotionControlDistance,
      motionEnterDuration:
          KDesignTokenVariants.motionReducedMotionEnterDuration,
      motionEnterBounce: KDesignTokenVariants.motionReducedMotionEnterBounce,
      motionEnterDistance:
          KDesignTokenVariants.motionReducedMotionEnterDistance,
      motionExitDuration: KDesignTokenVariants.motionReducedMotionExitDuration,
      motionExitBounce: KDesignTokenVariants.motionReducedMotionExitBounce,
      motionExitDistance: KDesignTokenVariants.motionReducedMotionExitDistance,
      motionPageDuration: KDesignTokenVariants.motionReducedMotionPageDuration,
      motionPageBounce: KDesignTokenVariants.motionReducedMotionPageBounce,
      motionPageDistance: KDesignTokenVariants.motionReducedMotionPageDistance,
      motionAttentionDuration:
          KDesignTokenVariants.motionReducedMotionAttentionDuration,
      motionAttentionBounce:
          KDesignTokenVariants.motionReducedMotionAttentionBounce,
      motionAttentionDistance:
          KDesignTokenVariants.motionReducedMotionAttentionDistance,
    ),
  };

  final styled = switch (configuration.style) {
    KStyle.linear => KDesignTokenVariants.applyStyleLinear(moved),
    KStyle.apple => KDesignTokenVariants.applyStyleApple(moved),
  };

  final resolved = styled.copyWith(
    spaceControlGap: controlGap,
    spaceControlInsetInline: controlInsetInline,
    sizeControl: controlSize,
    spaceContentActionGap: actionGap,
    spaceCardPadding: cardPadding,
    spaceLayoutSectionGap: configuration.windowClass == KWindowClass.compact
        ? KDesignTokenVariants.windowCompactSpaceLayoutSectionGap
        : sectionGap,
    sizeHitTarget: switch (configuration.inputMode) {
      KInputMode.pointer => KDesignTokenVariants.inputModePointerSizeHitTarget,
      KInputMode.touch => KDesignTokenVariants.inputModeTouchSizeHitTarget,
    },
    spaceLayoutGutter: switch (configuration.windowClass) {
      KWindowClass.compact =>
        KDesignTokenVariants.windowCompactSpaceLayoutGutter,
      KWindowClass.medium => KDesignTokenVariants.windowMediumSpaceLayoutGutter,
      KWindowClass.expanded =>
        KDesignTokenVariants.windowExpandedSpaceLayoutGutter,
      KWindowClass.large => KDesignTokenVariants.windowLargeSpaceLayoutGutter,
      KWindowClass.extraLarge =>
        KDesignTokenVariants.windowExtraLargeSpaceLayoutGutter,
    },
  );

  return switch (configuration.typeScale) {
    // iOS/iPadOS ramp (Decision 0014): body 17, large title 34.
    KTypeScale.apple => KDesignTokenVariants.applyTypeScaleApple(resolved),
    KTypeScale.compact => resolved.copyWith(
      fontSize: KDesignTokenVariants.typeScaleCompactFontSize,
      fontControlSize: KDesignTokenVariants.typeScaleCompactFontControlSize,
      fontHeading1Size: KDesignTokenVariants.typeScaleCompactFontHeading1Size,
      fontHeading1LineHeight:
          KDesignTokenVariants.typeScaleCompactFontHeading1LineHeight,
      fontHeading2Size: KDesignTokenVariants.typeScaleCompactFontHeading2Size,
      fontHeading2LineHeight:
          KDesignTokenVariants.typeScaleCompactFontHeading2LineHeight,
      fontHeading3Size: KDesignTokenVariants.typeScaleCompactFontHeading3Size,
      fontHeading3LineHeight:
          KDesignTokenVariants.typeScaleCompactFontHeading3LineHeight,
      fontHeading4Size: KDesignTokenVariants.typeScaleCompactFontHeading4Size,
      fontHeading4LineHeight:
          KDesignTokenVariants.typeScaleCompactFontHeading4LineHeight,
      fontHeading5Size: KDesignTokenVariants.typeScaleCompactFontHeading5Size,
      fontHeading5LineHeight:
          KDesignTokenVariants.typeScaleCompactFontHeading5LineHeight,
      fontHeading6Size: KDesignTokenVariants.typeScaleCompactFontHeading6Size,
      fontHeading6LineHeight:
          KDesignTokenVariants.typeScaleCompactFontHeading6LineHeight,
      fontBodySize: KDesignTokenVariants.typeScaleCompactFontBodySize,
      fontBodyLineHeight:
          KDesignTokenVariants.typeScaleCompactFontBodyLineHeight,
      fontBodySmallSize: KDesignTokenVariants.typeScaleCompactFontBodySmallSize,
      fontBodySmallLineHeight:
          KDesignTokenVariants.typeScaleCompactFontBodySmallLineHeight,
      fontLabelSize: KDesignTokenVariants.typeScaleCompactFontLabelSize,
      fontLabelLineHeight:
          KDesignTokenVariants.typeScaleCompactFontLabelLineHeight,
    ),
    KTypeScale.standard => resolved.copyWith(
      fontSize: KDesignTokenVariants.typeScaleStandardFontSize,
      fontControlSize: KDesignTokenVariants.typeScaleStandardFontControlSize,
      fontHeading1Size: KDesignTokenVariants.typeScaleStandardFontHeading1Size,
      fontHeading1LineHeight:
          KDesignTokenVariants.typeScaleStandardFontHeading1LineHeight,
      fontHeading2Size: KDesignTokenVariants.typeScaleStandardFontHeading2Size,
      fontHeading2LineHeight:
          KDesignTokenVariants.typeScaleStandardFontHeading2LineHeight,
      fontHeading3Size: KDesignTokenVariants.typeScaleStandardFontHeading3Size,
      fontHeading3LineHeight:
          KDesignTokenVariants.typeScaleStandardFontHeading3LineHeight,
      fontHeading4Size: KDesignTokenVariants.typeScaleStandardFontHeading4Size,
      fontHeading4LineHeight:
          KDesignTokenVariants.typeScaleStandardFontHeading4LineHeight,
      fontHeading5Size: KDesignTokenVariants.typeScaleStandardFontHeading5Size,
      fontHeading5LineHeight:
          KDesignTokenVariants.typeScaleStandardFontHeading5LineHeight,
      fontHeading6Size: KDesignTokenVariants.typeScaleStandardFontHeading6Size,
      fontHeading6LineHeight:
          KDesignTokenVariants.typeScaleStandardFontHeading6LineHeight,
      fontBodySize: KDesignTokenVariants.typeScaleStandardFontBodySize,
      fontBodyLineHeight:
          KDesignTokenVariants.typeScaleStandardFontBodyLineHeight,
      fontBodySmallSize:
          KDesignTokenVariants.typeScaleStandardFontBodySmallSize,
      fontBodySmallLineHeight:
          KDesignTokenVariants.typeScaleStandardFontBodySmallLineHeight,
      fontLabelSize: KDesignTokenVariants.typeScaleStandardFontLabelSize,
      fontLabelLineHeight:
          KDesignTokenVariants.typeScaleStandardFontLabelLineHeight,
    ),
    KTypeScale.mobile => resolved.copyWith(
      fontSize: KDesignTokenVariants.typeScaleMobileFontSize,
      fontControlSize: KDesignTokenVariants.typeScaleMobileFontControlSize,
      fontHeading1Size: KDesignTokenVariants.typeScaleMobileFontHeading1Size,
      fontHeading1LineHeight:
          KDesignTokenVariants.typeScaleMobileFontHeading1LineHeight,
      fontHeading2Size: KDesignTokenVariants.typeScaleMobileFontHeading2Size,
      fontHeading2LineHeight:
          KDesignTokenVariants.typeScaleMobileFontHeading2LineHeight,
      fontHeading3Size: KDesignTokenVariants.typeScaleMobileFontHeading3Size,
      fontHeading3LineHeight:
          KDesignTokenVariants.typeScaleMobileFontHeading3LineHeight,
      fontHeading4Size: KDesignTokenVariants.typeScaleMobileFontHeading4Size,
      fontHeading4LineHeight:
          KDesignTokenVariants.typeScaleMobileFontHeading4LineHeight,
      fontHeading5Size: KDesignTokenVariants.typeScaleMobileFontHeading5Size,
      fontHeading5LineHeight:
          KDesignTokenVariants.typeScaleMobileFontHeading5LineHeight,
      fontHeading6Size: KDesignTokenVariants.typeScaleMobileFontHeading6Size,
      fontHeading6LineHeight:
          KDesignTokenVariants.typeScaleMobileFontHeading6LineHeight,
      fontBodySize: KDesignTokenVariants.typeScaleMobileFontBodySize,
      fontBodyLineHeight:
          KDesignTokenVariants.typeScaleMobileFontBodyLineHeight,
      fontBodySmallSize: KDesignTokenVariants.typeScaleMobileFontBodySmallSize,
      fontBodySmallLineHeight:
          KDesignTokenVariants.typeScaleMobileFontBodySmallLineHeight,
      fontLabelSize: KDesignTokenVariants.typeScaleMobileFontLabelSize,
      fontLabelLineHeight:
          KDesignTokenVariants.typeScaleMobileFontLabelLineHeight,
    ),
  };
}

KDesignTokens kDesignTokens({
  KBrand brand = KBrand.orbit,
  Brightness brightness = Brightness.light,
  KDesignConfiguration configuration = const KDesignConfiguration(),
  KDesignTokenTransform? tokenTransform,
}) {
  final base = switch ((brand, brightness)) {
    (KBrand.orbit, Brightness.light) => KDesignTokens.orbitLight,
    (KBrand.orbit, Brightness.dark) => KDesignTokens.orbitDark,
    (KBrand.reference, Brightness.light) => KDesignTokens.referenceLight,
    (KBrand.reference, Brightness.dark) => KDesignTokens.referenceDark,
  };
  final resolved = resolveKDesignTokens(base, configuration);
  return tokenTransform?.call(resolved) ?? resolved;
}

ThemeData kDesignTheme({
  KBrand brand = KBrand.orbit,
  Brightness brightness = Brightness.light,
  KDesignConfiguration configuration = const KDesignConfiguration(),
  String? fontFamily,
  ScrollbarThemeData? scrollbarTheme,
  KDesignTokenTransform? tokenTransform,
}) {
  final tokens = kDesignTokens(
    brand: brand,
    brightness: brightness,
    configuration: configuration,
    tokenTransform: tokenTransform,
  ).copyWith(fontFamily: fontFamily);

  return ThemeData(
    brightness: brightness,
    // iOS/macOS: Cupertino transition with the iOS 26 content-area back
    // swipe (Decision 0012). Android keeps the system's back handling.
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        ...const PageTransitionsTheme().builders,
        TargetPlatform.iOS: const KPageTransitionsBuilder(),
        TargetPlatform.macOS: const KPageTransitionsBuilder(),
      },
    ),
    scaffoldBackgroundColor: tokens.colorSurfaceCanvas,
    fontFamily: tokens.fontFamily,
    visualDensity: switch (configuration.density) {
      KDensity.dense => VisualDensity.compact,
      KDensity.standard || KDensity.spacious => VisualDensity.standard,
    },
    materialTapTargetSize: switch (configuration.inputMode) {
      KInputMode.pointer => MaterialTapTargetSize.shrinkWrap,
      KInputMode.touch => MaterialTapTargetSize.padded,
    },
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    scrollbarTheme:
        scrollbarTheme ??
        ScrollbarThemeData(
          interactive: configuration.inputMode == KInputMode.pointer,
          thumbVisibility: WidgetStatePropertyAll(
            configuration.inputMode == KInputMode.pointer,
          ),
          trackVisibility: const WidgetStatePropertyAll(false),
          minThumbLength: 48,
          mainAxisMargin: 4,
          crossAxisMargin: 2,
          radius: Radius.circular(tokens.radiusFull),
          thickness: const WidgetStatePropertyAll(6),
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return Color.lerp(
                tokens.colorBorderStrong,
                tokens.colorTextMuted,
                0.45,
              );
            }
            return tokens.colorBorderStrong;
          }),
          trackColor: const WidgetStatePropertyAll(Colors.transparent),
          trackBorderColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: tokens.colorActionPrimaryBackground,
      brightness: brightness,
      surface: tokens.colorSurfaceRaised,
    ),
    extensions: <ThemeExtension<dynamic>>[tokens],
  );
}
