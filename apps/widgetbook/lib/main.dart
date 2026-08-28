import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:widgetbook/widgetbook.dart';

void main() => runApp(const KDesignWidgetbook());

class KDesignWidgetbook extends StatelessWidget {
  const KDesignWidgetbook({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      lightTheme: kDesignTheme(),
      darkTheme: kDesignTheme(brightness: Brightness.dark),
      header: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('K Design System'),
      ),
      addons: [
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Orbit Light', data: kDesignTheme()),
            WidgetbookTheme(
              name: 'Orbit Dark',
              data: kDesignTheme(brightness: Brightness.dark),
            ),
            WidgetbookTheme(
              name: 'Reference Light',
              data: kDesignTheme(brand: KBrand.reference),
            ),
            WidgetbookTheme(
              name: 'Reference Dark',
              data: kDesignTheme(
                brand: KBrand.reference,
                brightness: Brightness.dark,
              ),
            ),
          ],
        ),
        ViewportAddon(const [
          ViewportData(
            name: 'Compact · 375',
            width: 375,
            height: 812,
            pixelRatio: 1,
            platform: TargetPlatform.android,
          ),
          ViewportData(
            name: 'Medium · 700',
            width: 700,
            height: 900,
            pixelRatio: 1,
            platform: TargetPlatform.android,
          ),
          ViewportData(
            name: 'Expanded · 1024',
            width: 1024,
            height: 900,
            pixelRatio: 1,
            platform: TargetPlatform.windows,
          ),
          ViewportData(
            name: 'Large · 1440',
            width: 1440,
            height: 1000,
            pixelRatio: 1,
            platform: TargetPlatform.windows,
          ),
          ViewportData(
            name: 'Extra large · 1680',
            width: 1680,
            height: 1050,
            pixelRatio: 1,
            platform: TargetPlatform.windows,
          ),
        ]),
        KDesignConfigurationAddon(),
        TextScaleAddon(initialScale: 1, min: 1, max: 2, divisions: 4),
      ],
      directories: [
        WidgetbookCategory(
          name: 'Primitives',
          children: [
            WidgetbookComponent(
              name: 'Button',
              useCases: [
                WidgetbookUseCase(
                  name: 'button-primary',
                  builder: buildButtonPrimary,
                ),
                WidgetbookUseCase(
                  name: 'button-states',
                  builder: buildButtonStates,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

Widget buildButtonPrimary(BuildContext context) {
  return Center(
    child: KButton(label: 'Continue', onPressed: () {}),
  );
}

Widget buildButtonStates(BuildContext context) {
  final tokens = Theme.of(context).extension<KDesignTokens>()!;
  return SingleChildScrollView(
    padding: EdgeInsets.all(tokens.spaceLayoutGutter),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adaptive foundation',
              style: TextStyle(
                color: tokens.colorTextPrimary,
                fontFamily: tokens.fontFamily,
                fontSize: tokens.fontSize * 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: tokens.spaceControlGap),
            Text(
              'Compare density, typography, presentation, input target and '
              'window spacing with the addons.',
              style: TextStyle(
                color: tokens.colorTextMuted,
                fontFamily: tokens.fontFamily,
                fontSize: tokens.fontSize,
                height: 1.5,
              ),
            ),
            SizedBox(height: tokens.spaceLayoutSectionGap),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                KButton(label: 'Continue', onPressed: () {}),
                const KButton(label: 'Disabled', onPressed: null),
                KButton(label: 'Saving', loading: true, onPressed: () {}),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class KDesignConfigurationAddon extends WidgetbookAddon<KDesignConfiguration> {
  KDesignConfigurationAddon() : super(name: 'K Design');

  @override
  List<Field> get fields => [
    ObjectDropdownField<KPresentation>(
      name: 'presentation',
      values: KPresentation.values,
      initialValue: KPresentation.productive,
      labelBuilder: (value) => value.name,
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
  ];

  @override
  KDesignConfiguration valueFromQueryGroup(Map<String, String> group) {
    return KDesignConfiguration(
      presentation: valueOf<KPresentation>('presentation', group)!,
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
