import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

import 'package:widgetbook/widgetbook.dart';

/// `device` resolves the axes like a real app does (Decision 0010): from the
/// use case's available width and the selected device platform. `manual`
/// pins every axis from the fields below.
class KGalleryConfiguration {
  const KGalleryConfiguration({required this.device, required this.manual});
  final bool device;
  final KDesignConfiguration manual;
}

class KDesignConfigurationAddon extends WidgetbookAddon<KGalleryConfiguration> {
  KDesignConfigurationAddon() : super(name: 'K Design');

  @override
  List<Field> get fields => [
    ObjectDropdownField<String>(
      name: 'resolve',
      values: const ['device', 'manual'],
      initialValue: 'device',
    ),
    ObjectDropdownField<KDensity>(
      name: 'density',
      values: KDensity.values,
      initialValue: KDensity.standard,
      labelBuilder: (value) => value.name,
    ),
    ObjectDropdownField<KTypeScale>(
      name: 'type-scale',
      values: KTypeScale.values,
      initialValue: KTypeScale.compact,
      labelBuilder: (value) => value.name,
    ),
    ObjectDropdownField<KInputMode>(
      name: 'input-mode',
      values: KInputMode.values,
      initialValue: KInputMode.pointer,
      labelBuilder: (value) => value.name,
    ),
    ObjectDropdownField<KWindowClass>(
      name: 'window-class',
      values: KWindowClass.values,
      initialValue: KWindowClass.compact,
      labelBuilder: (value) => value.name,
    ),
    // Applies in both modes (Decision 0011); the platform reduce-motion
    // setting still wins in `device`.
    ObjectDropdownField<KMotionStyle>(
      name: 'motion',
      values: KMotionStyle.values,
      initialValue: KMotionStyle.apple,
      labelBuilder: (value) => value.name,
    ),
    // Style preset (Decision 0014); applies in both modes.
    ObjectDropdownField<KStyle>(
      name: 'style',
      values: KStyle.values,
      initialValue: KStyle.linear,
      labelBuilder: (value) => value.name,
    ),
  ];

  @override
  KGalleryConfiguration valueFromQueryGroup(Map<String, String> group) {
    return KGalleryConfiguration(
      device: valueOf<String>('resolve', group) != 'manual',
      manual: KDesignConfiguration(
        density: valueOf<KDensity>('density', group)!,
        typeScale: valueOf<KTypeScale>('type-scale', group)!,
        inputMode: valueOf<KInputMode>('input-mode', group)!,
        windowClass: valueOf<KWindowClass>('window-class', group)!,
        motion: valueOf<KMotionStyle>('motion', group) ?? KMotionStyle.apple,
        style: valueOf<KStyle>('style', group) ?? KStyle.linear,
      ),
    );
  }

  @override
  Widget buildUseCase(
    BuildContext context,
    Widget child,
    KGalleryConfiguration setting,
  ) {
    final gallery = setting;
    final theme = Theme.of(context);
    final resolved = gallery.device
        ? resolveKAdaptiveConfiguration(
            width: MediaQuery.sizeOf(context).width,
            platform: theme.platform,
            overrides: KAdaptiveOverrides(
              density: gallery.manual.density,
              motion: gallery.manual.motion,
              style: gallery.manual.style,
            ),
            reduceMotion: MediaQuery.disableAnimationsOf(context),
          )
        : gallery.manual;
    final baseTokens =
        theme.extension<KDesignTokens>() ?? KDesignTokens.orbitLight;
    final tokens = resolveKDesignTokens(baseTokens, resolved);

    return Theme(
      data: theme.copyWith(
        visualDensity: switch (resolved.density) {
          KDensity.dense => VisualDensity.compact,
          KDensity.standard || KDensity.spacious => VisualDensity.standard,
        },
        materialTapTargetSize: switch (resolved.inputMode) {
          KInputMode.pointer => MaterialTapTargetSize.shrinkWrap,
          KInputMode.touch => MaterialTapTargetSize.padded,
        },
        extensions: <ThemeExtension<dynamic>>[tokens],
      ),
      child: KAdaptive(
        configuration: resolved,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: tokens.textScaleMaxBody,
          child: resolved.motion == KMotionStyle.reduced
              ? Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(disableAnimations: true),
                    child: child,
                  ),
                )
              : child,
        ),
      ),
    );
  }
}

/// Component messages only; the gallery shell and example data keep their labels.
class KLanguageAddon extends WidgetbookAddon<String> {
  KLanguageAddon() : super(name: 'Language');
  static const supportedLocales = [
    'en',
    'de',
    'fr',
    'es',
    'it',
    'pt',
    'nl',
    'pl',
    'cs',
    'sv',
    'da',
    'nb',
    'fi',
    'tr',
  ];
  @override
  List<Field> get fields => [
    ObjectDropdownField<String>(
      name: 'locale',
      values: supportedLocales,
      initialValue: 'en',
    ),
  ];
  @override
  String valueFromQueryGroup(Map<String, String> group) =>
      valueOf<String>('locale', group)!;
  @override
  Widget buildUseCase(BuildContext context, Widget child, String setting) =>
      KLocalization(locale: setting, child: child);
}
