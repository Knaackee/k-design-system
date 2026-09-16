import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'package:widgetbook/widgetbook.dart';

class KDesignConfigurationAddon extends WidgetbookAddon<KDesignConfiguration> {
  KDesignConfigurationAddon() : super(name: 'K Design');

  @override
  List<Field> get fields => [
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
  ];

  @override
  KDesignConfiguration valueFromQueryGroup(Map<String, String> group) {
    return KDesignConfiguration(
      density: valueOf<KDensity>('density', group)!,
      typeScale: valueOf<KTypeScale>('type-scale', group)!,
      inputMode: valueOf<KInputMode>('input-mode', group)!,
      windowClass: valueOf<KWindowClass>('window-class', group)!,
    );
  }

  @override
  Widget buildUseCase(
    BuildContext context,
    Widget child,
    KDesignConfiguration setting,
  ) {
    final theme = Theme.of(context);
    final baseTokens =
        theme.extension<KDesignTokens>() ?? KDesignTokens.orbitLight;
    final tokens = resolveKDesignTokens(baseTokens, setting);

    return Theme(
      data: theme.copyWith(
        visualDensity: switch (setting.density) {
          KDensity.dense => VisualDensity.compact,
          KDensity.standard || KDensity.spacious => VisualDensity.standard,
        },
        materialTapTargetSize: switch (setting.inputMode) {
          KInputMode.pointer => MaterialTapTargetSize.shrinkWrap,
          KInputMode.touch => MaterialTapTargetSize.padded,
        },
        extensions: <ThemeExtension<dynamic>>[tokens],
      ),
      child: child,
    );
  }
}
