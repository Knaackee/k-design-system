import 'package:flutter/material.dart';

import 'generated/k_design_tokens.g.dart';
import 'k_design_theme.dart';

/// Resolves the adaptive axes from the available window and the platform
/// (Decision 0010). A gallery device frame and a real phone of the same width
/// therefore receive the same configuration. Explicit values in [overrides]
/// win; presets such as [KDesignConfiguration.mobileApp] are overrides.
KDesignConfiguration resolveKAdaptiveConfiguration({
  required double width,
  required TargetPlatform platform,
  KAdaptiveOverrides overrides = const KAdaptiveOverrides(),
}) {
  final windowClass = overrides.windowClass ?? kWindowClassForWidth(width);
  final inputMode =
      overrides.inputMode ??
      switch (platform) {
        TargetPlatform.iOS ||
        TargetPlatform.android ||
        TargetPlatform.fuchsia => KInputMode.touch,
        _ => KInputMode.pointer,
      };
  // Parity rule: the type ramp follows the window class only. Tablet and
  // desktop share one ramp; mobile Web and the mobile app share another.
  // Input mode changes hit targets, never typography.
  final typeScale =
      overrides.typeScale ??
      (windowClass == KWindowClass.compact
          ? KTypeScale.mobile
          : KTypeScale.standard);
  return KDesignConfiguration(
    density: overrides.density ?? KDensity.standard,
    typeScale: typeScale,
    inputMode: inputMode,
    windowClass: windowClass,
  );
}

/// Partial configuration used to pin individual axes.
@immutable
class KAdaptiveOverrides {
  const KAdaptiveOverrides({
    this.density,
    this.typeScale,
    this.inputMode,
    this.windowClass,
  });

  /// Pins every axis of [configuration] except the window class.
  factory KAdaptiveOverrides.from(KDesignConfiguration configuration) =>
      KAdaptiveOverrides(
        density: configuration.density,
        typeScale: configuration.typeScale,
        inputMode: configuration.inputMode,
      );

  final KDensity? density;
  final KTypeScale? typeScale;
  final KInputMode? inputMode;
  final KWindowClass? windowClass;
}

/// Exposes the resolved configuration below a [KAdaptiveTheme].
class KAdaptive extends InheritedWidget {
  const KAdaptive({
    super.key,
    required this.configuration,
    required super.child,
  });

  final KDesignConfiguration configuration;

  static KDesignConfiguration? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KAdaptive>()?.configuration;

  @override
  bool updateShouldNotify(KAdaptive oldWidget) =>
      oldWidget.configuration != configuration;
}

/// Applies a K theme resolved from the current window and platform and caps
/// the system text scale (body/control cap globally; [KText] applies the
/// tighter heading cap). Place it below `MaterialApp.builder` or around a
/// screen; it re-resolves when the window size changes.
class KAdaptiveTheme extends StatelessWidget {
  const KAdaptiveTheme({
    super.key,
    required this.child,
    this.brand = KBrand.orbit,
    this.brightness,
    this.overrides = const KAdaptiveOverrides(),
    this.tokenTransform,
    this.fontFamily,
  });

  final Widget child;
  final KBrand brand;

  /// Defaults to the platform brightness.
  final Brightness? brightness;
  final KAdaptiveOverrides overrides;
  final KDesignTokenTransform? tokenTransform;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final configuration = resolveKAdaptiveConfiguration(
      width: media.size.width,
      platform: Theme.of(context).platform,
      overrides: overrides,
    );
    final theme = kDesignTheme(
      brand: brand,
      brightness: brightness ?? media.platformBrightness,
      configuration: configuration,
      tokenTransform: tokenTransform,
      fontFamily: fontFamily,
    );
    final tokens = theme.extension<KDesignTokens>()!;
    return KAdaptive(
      configuration: configuration,
      child: Theme(
        data: theme,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: tokens.textScaleMaxBody,
          child: child,
        ),
      ),
    );
  }
}
