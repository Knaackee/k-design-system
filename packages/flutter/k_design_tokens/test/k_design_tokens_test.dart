import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

void main() {
  test('neutral actions stay separate from brand accents', () {
    expect(
      KDesignTokens.orbitLight.colorActionPrimaryBackground,
      KDesignTokens.referenceLight.colorActionPrimaryBackground,
    );
    expect(
      KDesignTokens.orbitLight.colorBrandPrimaryAccent,
      isNot(KDesignTokens.referenceLight.colorBrandPrimaryAccent),
    );
    expect(
      KDesignTokens.orbitLight.colorActionPrimaryBackground,
      const Color(0xff242428),
    );
    expect(
      KDesignTokens.orbitDark.colorActionPrimaryBackground,
      const Color(0xffe8e8eb),
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
        configuration: KDesignConfiguration(
          density: density,
          windowClass: KWindowClass.expanded,
        ),
      );
      expect(tokens.spaceControlGap, gap);
      expect(tokens.spaceContentActionGap, action);
      expect(tokens.spaceCardPadding, inset);
      expect(tokens.spaceLayoutSectionGap, section);
      expect(tokens.sizeControl, control);
    }
    expect(KDesignConfiguration.marketing.density, KDensity.spacious);
  });

  test('compact windows tighten section gaps and use the phone ramp', () {
    final tokens = kDesignTokens(configuration: KDesignConfiguration.mobileApp);
    expect(tokens.spaceLayoutSectionGap, 24);
    expect(tokens.spaceLayoutGutter, 16);
    expect(tokens.spaceCardPadding, 16);
    expect(tokens.fontBodySize, 16);
    expect(tokens.fontControlSize, 16);
    expect(tokens.fontHeading1Size, 28);
    expect(tokens.fontHeading1LineHeight, 34);
    expect(tokens.sizeHitTarget, 48);
    expect(tokens.fontCaption2Size, 11);
  });

  test('adaptive resolution follows window and platform', () {
    final phone = resolveKAdaptiveConfiguration(
      width: 393,
      platform: TargetPlatform.iOS,
    );
    expect(phone.windowClass, KWindowClass.compact);
    expect(phone.inputMode, KInputMode.touch);
    // Platform-native default (Decision 0014): iPhone gets the Apple style.
    expect(phone.style, KStyle.apple);
    expect(phone.typeScale, KTypeScale.apple);
    expect(phone.density, KDensity.standard);

    final android = resolveKAdaptiveConfiguration(
      width: 393,
      platform: TargetPlatform.android,
    );
    expect(android.style, KStyle.linear);
    expect(android.typeScale, KTypeScale.mobile);

    final tablet = resolveKAdaptiveConfiguration(
      width: 1024,
      platform: TargetPlatform.android,
    );
    expect(tablet.typeScale, KTypeScale.standard);
    expect(tablet.inputMode, KInputMode.touch);

    final desktop = resolveKAdaptiveConfiguration(
      width: 1440,
      platform: TargetPlatform.macOS,
      overrides: const KAdaptiveOverrides(density: KDensity.dense),
    );
    expect(desktop.typeScale, KTypeScale.standard);
    // Parity: tablet and desktop resolve the same ramp.
    expect(desktop.typeScale, tablet.typeScale);
    expect(desktop.inputMode, KInputMode.pointer);
    expect(desktop.density, KDensity.dense);
  });

  test('text scale caps are tokenized per role', () {
    final tokens = kDesignTokens();
    expect(tokens.textScaleMaxBody, 3);
    expect(tokens.textScaleMaxHeading, 2);
    expect(tokens.textScaleMaxControl, 3);
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

  test('scrollbars derive from tokens and remain consumer-overridable', () {
    final theme = kDesignTheme(brightness: Brightness.dark);
    final tokens = theme.extension<KDesignTokens>()!;
    expect(
      theme.scrollbarTheme.thumbColor!.resolve({}),
      tokens.colorBorderStrong,
    );
    expect(
      theme.scrollbarTheme.thumbColor!.resolve({WidgetState.hovered}),
      Color.lerp(tokens.colorBorderStrong, tokens.colorTextMuted, 0.45),
    );
    expect(theme.scrollbarTheme.thickness!.resolve({}), 6);
    expect(theme.scrollbarTheme.thickness!.resolve({WidgetState.dragged}), 6);
    expect(theme.scrollbarTheme.interactive, isTrue);
    expect(theme.scrollbarTheme.thumbVisibility!.resolve({}), isTrue);

    final touchTheme = kDesignTheme(
      configuration: KDesignConfiguration.mobileApp,
    ).scrollbarTheme;
    expect(touchTheme.interactive, isFalse);
    expect(touchTheme.thumbVisibility!.resolve({}), isFalse);

    const override = ScrollbarThemeData(thickness: WidgetStatePropertyAll(12));
    expect(kDesignTheme(scrollbarTheme: override).scrollbarTheme, override);
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

  test('consumer font override reaches theme and component tokens', () {
    final theme = kDesignTheme(fontFamily: 'Consumer Sans');
    expect(theme.textTheme.bodyMedium!.fontFamily, 'Consumer Sans');
    expect(theme.extension<KDesignTokens>()!.fontFamily, 'Consumer Sans');
  });

  test('semantic overrides cascade to component defaults', () {
    final squared = KDesignTokens.orbitLight.copyWith(
      radiusFull: 0,
      radiusSheet: 0,
    );

    expect(squared.componentMobileAppBarContainerRadiusFloating, 0);
    expect(squared.componentMobileAppBarContainerRadiusFixed, 0);
    expect(squared.componentMobileAppBarDestinationRadiusDefault, 0);
    expect(squared.componentMobileAppBarBadgeRadius, 0);

    final explicit = KDesignTokens.orbitLight.copyWith(
      radiusFull: 0,
      componentMobileAppBarBadgeRadius: 7,
    );
    expect(explicit.componentMobileAppBarContainerRadiusFloating, 0);
    expect(explicit.componentMobileAppBarBadgeRadius, 7);
  });

  test('button component defaults follow shared semantic roles', () {
    final tokens = KDesignTokens.orbitLight.copyWith(
      opacityDisabled: 0.3,
      sizeIndicatorSmall: 20,
      borderWidthStrong: 3,
    );

    expect(tokens.componentButtonDisabledOpacity, 0.3);
    expect(tokens.componentButtonLoadingIndicatorSize, 20);
    expect(tokens.componentButtonLoadingIndicatorStrokeWidth, 3);
  });

  test('foundation component aliases follow semantic geometry and motion', () {
    final tokens = KDesignTokens.orbitLight.copyWith(
      sizeCompact: 26,
      sizeIndicatorMedium: 20,
      motionModerate: const Duration(milliseconds: 240),
    );

    expect(tokens.componentKbdMinSize, 26);
    expect(tokens.componentSwitchTrackHeight, 26);
    expect(tokens.componentSliderInputSize, 26);
    expect(tokens.componentSpinnerDefaultSize, 20);
    expect(tokens.componentSliderThumbSize, 20);
    expect(
      tokens.componentCarouselTransitionDuration,
      const Duration(milliseconds: 240),
    );
  });

  test('theme helper applies a consumer token transform', () {
    final theme = kDesignTheme(
      tokenTransform: (tokens) =>
          tokens.copyWith(componentMobileAppBarPrimaryActionRadius: 3),
    );

    expect(
      theme
          .extension<KDesignTokens>()!
          .componentMobileAppBarPrimaryActionRadius,
      3,
    );
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
    expect(tokens.radiusControl, 6);
    expect(tokens.radiusCard, 8);
    expect(tokens.radiusOverlay, 12);
    expect(tokens.radiusSheet, 12);
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
