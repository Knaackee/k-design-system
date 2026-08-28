import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

void main() {
  test('Orbit and reference themes expose different action colors', () {
    expect(
      KDesignTokens.orbitLight.colorActionPrimaryBackground,
      isNot(KDesignTokens.referenceLight.colorActionPrimaryBackground),
    );
  });

  test('theme helper installs the selected token extension', () {
    final theme = kDesignTheme(
      brand: KBrand.reference,
      brightness: Brightness.dark,
    );
    final tokens = theme.extension<KDesignTokens>()!;
    expect(
      tokens.colorActionPrimaryBackground,
      KDesignTokens.referenceDark.colorActionPrimaryBackground,
    );
  });

  test('adaptive axes resolve independently', () {
    final tokens = kDesignTokens(
      configuration: const KDesignConfiguration(
        presentation: KPresentation.expressive,
        density: KDensity.dense,
        typeScale: KTypeScale.standard,
        inputMode: KInputMode.touch,
        windowClass: KWindowClass.large,
      ),
    );

    expect(tokens.sizeControl, 32);
    expect(tokens.fontSize, 16);
    expect(tokens.sizeHitTarget, 48);
    expect(tokens.spaceLayoutSectionGap, 64);
    expect(tokens.spaceLayoutGutter, 48);
  });

  test('window classes are derived from available width boundaries', () {
    expect(kWindowClassForWidth(599), KWindowClass.compact);
    expect(kWindowClassForWidth(600), KWindowClass.medium);
    expect(kWindowClassForWidth(840), KWindowClass.expanded);
    expect(kWindowClassForWidth(1200), KWindowClass.large);
    expect(kWindowClassForWidth(1600), KWindowClass.extraLarge);
  });
}
