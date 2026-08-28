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
                  name: 'button-variants',
                  builder: buildButtonVariants,
                ),
                WidgetbookUseCase(
                  name: 'button-states',
                  builder: buildButtonStates,
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Typography',
              useCases: [
                WidgetbookUseCase(
                  name: 'typography-primary',
                  builder: buildTypographyPrimary,
                ),
                WidgetbookUseCase(
                  name: 'typography-scale',
                  builder: buildTypographyScale,
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Colors',
              useCases: [
                WidgetbookUseCase(
                  name: 'colors-semantic-roles',
                  builder: buildSemanticColors,
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Shape',
              useCases: [
                WidgetbookUseCase(
                  name: 'shape-radius-scale',
                  builder: buildRadiusScale,
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Elevation',
              useCases: [
                WidgetbookUseCase(
                  name: 'elevation-levels',
                  builder: buildElevationLevels,
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Surface',
              useCases: [
                WidgetbookUseCase(
                  name: 'surface-tones',
                  builder: buildSurfaceTones,
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Card',
              useCases: [
                WidgetbookUseCase(
                  name: 'card-variants',
                  builder: buildCardVariants,
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

Widget buildButtonVariants(BuildContext context) {
  return Center(
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        KButton(label: 'Create issue', onPressed: () {}),
        KButton(
          label: 'Cancel',
          variant: KButtonVariant.secondary,
          onPressed: () {},
        ),
        KButton(
          label: 'Dismiss',
          variant: KButtonVariant.ghost,
          onPressed: () {},
        ),
      ],
    ),
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
            KText('Adaptive foundation', variant: KTextVariant.heading3),
            SizedBox(height: tokens.spaceControlGap),
            KText(
              'Compare density, typography, presentation, input target and '
              'window spacing with the addons.',
              style: TextStyle(color: tokens.colorTextMuted),
            ),
            SizedBox(height: tokens.spaceLayoutSectionGap),
            _ButtonStateRow(variant: KButtonVariant.primary),
            const SizedBox(height: 14),
            _ButtonStateRow(variant: KButtonVariant.secondary),
            const SizedBox(height: 14),
            _ButtonStateRow(variant: KButtonVariant.ghost),
          ],
        ),
      ),
    ),
  );
}

Widget buildTypographyPrimary(BuildContext context) {
  return const Center(child: KText('Designing software with clarity'));
}

Widget buildTypographyScale(BuildContext context) {
  final tokens = Theme.of(context).extension<KDesignTokens>()!;
  return SingleChildScrollView(
    padding: EdgeInsets.all(tokens.spaceLayoutGutter),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const KText(
              'H1 · Product direction',
              variant: KTextVariant.heading1,
            ),
            SizedBox(height: tokens.spaceLayoutSectionGap),
            const KText(
              'H2 · Planning and strategy',
              variant: KTextVariant.heading2,
            ),
            SizedBox(height: tokens.spaceLayoutSectionGap),
            const KText(
              'H3 · Project overview',
              variant: KTextVariant.heading3,
            ),
            SizedBox(height: tokens.spaceLayoutSectionGap),
            const KText(
              'H4 · Current milestone',
              variant: KTextVariant.heading4,
            ),
            SizedBox(height: tokens.spaceLayoutSectionGap),
            const KText(
              'H5 · Work in progress',
              variant: KTextVariant.heading5,
            ),
            SizedBox(height: tokens.spaceLayoutSectionGap),
            const KText(
              'H6 · Supporting section',
              variant: KTextVariant.heading6,
            ),
            SizedBox(height: tokens.spaceLayoutSectionGap),
            const KText(
              'Body · Clear interface copy supports fast reading across '
              'product and editorial contexts.',
            ),
            SizedBox(height: tokens.spaceLayoutSectionGap),
            const KText(
              'Body small · Secondary information remains legible without '
              'competing with the main content.',
              variant: KTextVariant.bodySmall,
            ),
            SizedBox(height: tokens.spaceLayoutSectionGap),
            const KText('Label · ASSIGNEE', variant: KTextVariant.label),
            SizedBox(height: tokens.spaceLayoutSectionGap),
            const KText(
              'Caption · Updated moments ago',
              variant: KTextVariant.caption,
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildSemanticColors(BuildContext context) {
  final tokens = Theme.of(context).extension<KDesignTokens>()!;
  final roles = [
    (
      'Primary',
      'Brand and principal actions',
      tokens.colorBrandPrimaryAccent,
      tokens.colorBrandPrimaryBackground,
      tokens.colorBrandPrimaryForeground,
      tokens.colorBrandPrimaryBorder,
    ),
    (
      'Secondary',
      'Supporting brand emphasis',
      tokens.colorBrandSecondaryAccent,
      tokens.colorBrandSecondaryBackground,
      tokens.colorBrandSecondaryForeground,
      tokens.colorBrandSecondaryBorder,
    ),
    (
      'Info',
      'Neutral system information',
      tokens.colorStatusInfoAccent,
      tokens.colorStatusInfoBackground,
      tokens.colorStatusInfoForeground,
      tokens.colorStatusInfoBorder,
    ),
    (
      'Success',
      'Completed or healthy state',
      tokens.colorStatusSuccessAccent,
      tokens.colorStatusSuccessBackground,
      tokens.colorStatusSuccessForeground,
      tokens.colorStatusSuccessBorder,
    ),
    (
      'Warning',
      'Attention without failure',
      tokens.colorStatusWarningAccent,
      tokens.colorStatusWarningBackground,
      tokens.colorStatusWarningForeground,
      tokens.colorStatusWarningBorder,
    ),
    (
      'Error',
      'Failure or destructive state',
      tokens.colorStatusErrorAccent,
      tokens.colorStatusErrorBackground,
      tokens.colorStatusErrorForeground,
      tokens.colorStatusErrorBorder,
    ),
  ];

  return SingleChildScrollView(
    padding: EdgeInsets.all(tokens.spaceLayoutGutter),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final role in roles)
              _ColorRoleCard(
                name: role.$1,
                description: role.$2,
                accent: role.$3,
                background: role.$4,
                foreground: role.$5,
                border: role.$6,
              ),
          ],
        ),
      ),
    ),
  );
}

Widget _foundationFrame(BuildContext context, Widget child) {
  final tokens = Theme.of(context).extension<KDesignTokens>()!;
  return SingleChildScrollView(
    padding: EdgeInsets.all(tokens.spaceLayoutGutter),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: child,
      ),
    ),
  );
}

Widget buildRadiusScale(BuildContext context) {
  final tokens = Theme.of(context).extension<KDesignTokens>()!;
  final radii = [
    (KSurfaceRadius.none, 'None · 0'),
    (KSurfaceRadius.small, 'Small · 4'),
    (KSurfaceRadius.medium, 'Medium · 6'),
    (KSurfaceRadius.large, 'Large · 8'),
    (KSurfaceRadius.extraLarge, 'Extra large · 12'),
    (KSurfaceRadius.full, 'Full'),
  ];
  return _foundationFrame(
    context,
    Wrap(
      spacing: tokens.spaceLayoutSectionGap,
      runSpacing: tokens.spaceLayoutSectionGap,
      children: [
        for (final item in radii)
          SizedBox(
            width: 210,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 72,
                  width: double.infinity,
                  child: KSurface(radius: item.$1, child: const SizedBox()),
                ),
                SizedBox(height: tokens.spaceControlGap),
                KText(item.$2, variant: KTextVariant.caption),
              ],
            ),
          ),
      ],
    ),
  );
}

Widget buildElevationLevels(BuildContext context) {
  final tokens = Theme.of(context).extension<KDesignTokens>()!;
  final levels = [
    (KSurfaceElevation.none, 'None', 'Default cards and in-flow surfaces'),
    (KSurfaceElevation.low, 'Low', 'Floating utility controls'),
    (KSurfaceElevation.medium, 'Medium', 'Menus and popovers'),
    (KSurfaceElevation.overlay, 'Overlay', 'Dialogs and modal layers'),
  ];
  return _foundationFrame(
    context,
    ColoredBox(
      color: tokens.colorSurfaceCanvas,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Wrap(
          spacing: tokens.spaceLayoutSectionGap,
          runSpacing: tokens.spaceLayoutSectionGap,
          children: [
            for (final item in levels)
              SizedBox(
                width: 300,
                height: 112,
                child: KSurface(
                  border: item.$1 == KSurfaceElevation.none
                      ? KSurfaceBorder.standard
                      : KSurfaceBorder.none,
                  elevation: item.$1,
                  radius: item.$1 == KSurfaceElevation.overlay
                      ? KSurfaceRadius.overlay
                      : KSurfaceRadius.medium,
                  child: Padding(
                    padding: EdgeInsets.all(tokens.spaceCardPadding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KText(item.$2, variant: KTextVariant.label),
                        SizedBox(height: tokens.spaceControlGap),
                        KText(
                          item.$3,
                          variant: KTextVariant.bodySmall,
                          style: TextStyle(color: tokens.colorTextMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

Widget buildSurfaceTones(BuildContext context) {
  final tokens = Theme.of(context).extension<KDesignTokens>()!;
  final tones = [
    (KSurfaceTone.canvas, 'Canvas', 'Application background'),
    (KSurfaceTone.raised, 'Raised', 'Cards and panels'),
    (KSurfaceTone.subtle, 'Subtle', 'Quiet grouping and selection'),
  ];
  return _foundationFrame(
    context,
    Wrap(
      spacing: tokens.spaceLayoutSectionGap,
      runSpacing: tokens.spaceLayoutSectionGap,
      children: [
        for (final item in tones)
          SizedBox(
            width: 230,
            height: 112,
            child: KSurface(
              tone: item.$1,
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceCardPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KText(item.$2, variant: KTextVariant.label),
                    SizedBox(height: tokens.spaceControlGap),
                    KText(
                      item.$3,
                      variant: KTextVariant.bodySmall,
                      style: TextStyle(color: tokens.colorTextMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

Widget buildCardVariants(BuildContext context) {
  final tokens = Theme.of(context).extension<KDesignTokens>()!;
  Widget card(KSurfaceTone tone, String title, String copy, String action) {
    return SizedBox(
      width: 340,
      child: KCard(
        tone: tone,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KText(title, variant: KTextVariant.heading4),
            SizedBox(height: tokens.spaceControlGap),
            KText(
              copy,
              variant: KTextVariant.bodySmall,
              style: TextStyle(color: tokens.colorTextMuted),
            ),
            SizedBox(height: tokens.spaceControlGap),
            KButton(
              label: action,
              variant: tone == KSurfaceTone.subtle
                  ? KButtonVariant.ghost
                  : KButtonVariant.secondary,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  return _foundationFrame(
    context,
    Wrap(
      spacing: tokens.spaceLayoutSectionGap,
      runSpacing: tokens.spaceLayoutSectionGap,
      children: [
        card(
          KSurfaceTone.raised,
          'Project settings',
          'Default cards use a fine border and no shadow.',
          'Configure',
        ),
        card(
          KSurfaceTone.subtle,
          'Quiet grouping',
          'Subtle tone separates content without added depth.',
          'View details',
        ),
      ],
    ),
  );
}

class _ColorRoleCard extends StatelessWidget {
  const _ColorRoleCard({
    required this.name,
    required this.description,
    required this.accent,
    required this.background,
    required this.foreground,
    required this.border,
  });

  final String name;
  final String description;
  final Color accent;
  final Color background;
  final Color foreground;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return Container(
      width: 340,
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(tokens.radiusControl),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 54,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KText(
                  name,
                  variant: KTextVariant.label,
                  style: TextStyle(color: foreground),
                ),
                const SizedBox(height: 3),
                KText(
                  description,
                  variant: KTextVariant.bodySmall,
                  style: TextStyle(color: foreground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonStateRow extends StatelessWidget {
  const _ButtonStateRow({required this.variant});

  final KButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 72,
          child: KText(
            variant.name.toUpperCase(),
            variant: KTextVariant.caption,
            style: TextStyle(
              color: Theme.of(
                context,
              ).extension<KDesignTokens>()!.colorTextMuted,
            ),
          ),
        ),
        KButton(label: 'Continue', variant: variant, onPressed: () {}),
        KButton(label: 'Disabled', variant: variant, onPressed: null),
        KButton(
          label: 'Saving',
          variant: variant,
          loading: true,
          onPressed: () {},
        ),
      ],
    );
  }
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
