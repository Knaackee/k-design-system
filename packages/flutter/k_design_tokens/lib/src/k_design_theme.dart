import 'package:flutter/material.dart';

import 'generated/k_design_tokens.g.dart';

enum KBrand { orbit, reference }

KDesignTokens kDesignTokens({
  KBrand brand = KBrand.orbit,
  Brightness brightness = Brightness.light,
}) {
  return switch ((brand, brightness)) {
    (KBrand.orbit, Brightness.light) => KDesignTokens.orbitLight,
    (KBrand.orbit, Brightness.dark) => KDesignTokens.orbitDark,
    (KBrand.reference, Brightness.light) => KDesignTokens.referenceLight,
    (KBrand.reference, Brightness.dark) => KDesignTokens.referenceDark,
  };
}

ThemeData kDesignTheme({
  KBrand brand = KBrand.orbit,
  Brightness brightness = Brightness.light,
}) {
  final tokens = kDesignTokens(brand: brand, brightness: brightness);

  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: tokens.colorSurfaceCanvas,
    fontFamily: tokens.fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: tokens.colorActionPrimaryBackground,
      brightness: brightness,
      surface: tokens.colorSurfaceRaised,
    ),
    extensions: <ThemeExtension<dynamic>>[tokens],
  );
}
