import 'package:flutter/material.dart';

import 'generated/k_design_tokens.g.dart';

enum KBrand { orbit, reference }

enum KPresentation { productive, expressive }

enum KDensity { dense, standard, spacious }

enum KTypeScale { compact, standard }

enum KInputMode { pointer, touch }

enum KWindowClass { compact, medium, expanded, large, extraLarge }

@immutable
class KDesignConfiguration {
  const KDesignConfiguration({
    this.presentation = KPresentation.productive,
    this.density = KDensity.standard,
    this.typeScale = KTypeScale.compact,
    this.inputMode = KInputMode.pointer,
    this.windowClass = KWindowClass.compact,
  });

  final KPresentation presentation;
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
    presentation: KPresentation.expressive,
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
  ) = switch (configuration.density) {
    KDensity.dense => (
      KDesignTokenVariants.densityDenseSpaceControlGap,
      KDesignTokenVariants.densityDenseSpaceControlInsetInline,
      KDesignTokenVariants.densityDenseSizeControl,
    ),
    KDensity.standard => (
      KDesignTokenVariants.densityStandardSpaceControlGap,
      KDesignTokenVariants.densityStandardSpaceControlInsetInline,
      KDesignTokenVariants.densityStandardSizeControl,
    ),
    KDensity.spacious => (
      KDesignTokenVariants.densitySpaciousSpaceControlGap,
      KDesignTokenVariants.densitySpaciousSpaceControlInsetInline,
      KDesignTokenVariants.densitySpaciousSizeControl,
    ),
  };

  return base.copyWith(
    spaceControlGap: controlGap,
    spaceControlInsetInline: controlInsetInline,
    sizeControl: controlSize,
    spaceLayoutSectionGap: switch (configuration.presentation) {
      KPresentation.productive =>
        KDesignTokenVariants.presentationProductiveSpaceLayoutSectionGap,
      KPresentation.expressive =>
        KDesignTokenVariants.presentationExpressiveSpaceLayoutSectionGap,
    },
    fontSize: switch (configuration.typeScale) {
      KTypeScale.compact => KDesignTokenVariants.typeScaleCompactFontSize,
      KTypeScale.standard => KDesignTokenVariants.typeScaleStandardFontSize,
    },
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
}) {
  final tokens = kDesignTokens(
    brand: brand,
    brightness: brightness,
    configuration: configuration,
  );

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
    colorScheme: ColorScheme.fromSeed(
      seedColor: tokens.colorActionPrimaryBackground,
      brightness: brightness,
      surface: tokens.colorSurfaceRaised,
    ),
    extensions: <ThemeExtension<dynamic>>[tokens],
  );
}
