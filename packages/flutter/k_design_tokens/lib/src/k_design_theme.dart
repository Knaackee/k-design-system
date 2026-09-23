import 'package:flutter/material.dart';

import 'generated/k_design_tokens.g.dart';

enum KBrand { orbit, reference }

enum KDensity { dense, standard, spacious }

enum KTypeScale { compact, standard }

enum KInputMode { pointer, touch }

enum KWindowClass { compact, medium, expanded, large, extraLarge }

@immutable
class KDesignConfiguration {
  const KDesignConfiguration({
    this.density = KDensity.standard,
    this.typeScale = KTypeScale.compact,
    this.inputMode = KInputMode.pointer,
    this.windowClass = KWindowClass.compact,
  });

  final KDensity density;
  final KTypeScale typeScale;
  final KInputMode inputMode;
  final KWindowClass windowClass;

  static const dashboard = KDesignConfiguration(density: KDensity.dense);

  static const desktopApp = KDesignConfiguration();

  static const mobileApp = KDesignConfiguration(
    density: KDensity.spacious,
    typeScale: KTypeScale.standard,
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

  final resolved = base.copyWith(
    spaceControlGap: controlGap,
    spaceControlInsetInline: controlInsetInline,
    sizeControl: controlSize,
    spaceContentActionGap: actionGap,
    spaceCardPadding: cardPadding,
    spaceLayoutSectionGap: sectionGap,
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
  };
}

KDesignTokens kDesignTokens({
  KBrand brand = KBrand.orbit,
  Brightness brightness = Brightness.light,
  KDesignConfiguration configuration = const KDesignConfiguration(),
}) {
  final base = switch ((brand, brightness)) {
    (KBrand.orbit, Brightness.light) => KDesignTokens.orbitLight,
    (KBrand.orbit, Brightness.dark) => KDesignTokens.orbitDark,
    (KBrand.reference, Brightness.light) => KDesignTokens.referenceLight,
    (KBrand.reference, Brightness.dark) => KDesignTokens.referenceDark,
  };
  return resolveKDesignTokens(base, configuration);
}

ThemeData kDesignTheme({
  KBrand brand = KBrand.orbit,
  Brightness brightness = Brightness.light,
  KDesignConfiguration configuration = const KDesignConfiguration(),
  String? fontFamily,
  ScrollbarThemeData? scrollbarTheme,
}) {
  final tokens = kDesignTokens(
    brand: brand,
    brightness: brightness,
    configuration: configuration,
  ).copyWith(fontFamily: fontFamily);

  return ThemeData(
    brightness: brightness,
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
