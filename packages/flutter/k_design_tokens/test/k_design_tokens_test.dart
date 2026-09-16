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
        density: KDensity.dense,
        typeScale: KTypeScale.standard,
        inputMode: KInputMode.touch,
        windowClass: KWindowClass.large,
      ),
    );

    expect(tokens.sizeControl, 32);
    expect(tokens.fontSize, 16);
    expect(tokens.fontControlSize, 14);
    expect(tokens.fontHeading1Size, 36);
    expect(tokens.fontHeading1LineHeight, 44);
    expect(tokens.sizeHitTarget, 48);
    expect(tokens.spaceLayoutSectionGap, 16);
    expect(tokens.spaceContentActionGap, 8);
    expect(tokens.spaceCardPadding, 12);
    expect(tokens.spaceLayoutGutter, 48);
  });

  test('all densities resolve the complete rhythm and presets', () {
    for (final (density, gap, action, inset, section, control) in [
      (KDensity.dense, 4, 8, 12, 16, 32),
      (KDensity.standard, 8, 16, 16, 32, 36),
      (KDensity.spacious, 12, 24, 24, 48, 44),
    ]) {
      final tokens = kDesignTokens(
        configuration: KDesignConfiguration(density: density),
      );
      expect(tokens.spaceControlGap, gap);
      expect(tokens.spaceContentActionGap, action);
      expect(tokens.spaceCardPadding, inset);
      expect(tokens.spaceLayoutSectionGap, section);
      expect(tokens.sizeControl, control);
    }
    expect(KDesignConfiguration.marketing.density, KDensity.spacious);
  });

  test('window classes are derived from available width boundaries', () {
    expect(kWindowClassForWidth(599), KWindowClass.compact);
    expect(kWindowClassForWidth(600), KWindowClass.medium);
    expect(kWindowClassForWidth(840), KWindowClass.expanded);
    expect(kWindowClassForWidth(1200), KWindowClass.large);
    expect(kWindowClassForWidth(1600), KWindowClass.extraLarge);
  });

  test('theme disables platform ripple feedback for Web parity', () {
    final theme = kDesignTheme();

    expect(theme.splashFactory, same(NoSplash.splashFactory));
    expect(theme.splashColor, Colors.transparent);
    expect(theme.highlightColor, Colors.transparent);
  });

  test('reference theme overrides flow through secondary button roles', () {
    expect(
      KDesignTokens.referenceLight.colorActionSecondaryHover,
      KDesignTokens.referenceLight.colorSurfaceSubtle,
    );
    expect(
      KDesignTokens.referenceLight.colorActionSecondaryHover,
      isNot(KDesignTokens.orbitLight.colorActionSecondaryHover),
    );
  });

  test('both platforms resolve the bundled Inter font asset', () {
    final theme = kDesignTheme();

    expect(
      KDesignTokens.orbitLight.fontFamily,
      'packages/k_design_tokens/Inter',
    );
    expect(theme.textTheme.bodyMedium!.fontFamily, contains('Inter'));
  });

  test('brand and status roles remain theme-overridable', () {
    expect(
      KDesignTokens.referenceLight.colorBrandPrimaryAccent,
      isNot(KDesignTokens.orbitLight.colorBrandPrimaryAccent),
    );
    expect(
      KDesignTokens.referenceDark.colorStatusInfoBackground,
      isNot(KDesignTokens.orbitDark.colorStatusInfoBackground),
    );
  });

  test('shape and elevation roles expose the shared foundation contract', () {
    final tokens = KDesignTokens.orbitLight;

    expect(tokens.radiusSmall, 4);
    expect(tokens.radiusCard, 6);
    expect(tokens.radiusOverlay, 8);
    expect(tokens.borderWidthDefault, 1);
    expect(tokens.elevationNone.single.color, Colors.transparent);
    expect(tokens.elevationLow, hasLength(1));
    expect(tokens.elevationMedium, hasLength(2));
    expect(tokens.elevationOverlay, hasLength(2));
    expect(
      KDesignTokens.orbitDark.elevationOverlay.first.color,
      isNot(tokens.elevationOverlay.first.color),
    );
  });
}
