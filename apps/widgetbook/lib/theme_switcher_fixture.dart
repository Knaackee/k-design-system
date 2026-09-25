import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class ThemeSwitcherFixture extends StatefulWidget {
  const ThemeSwitcherFixture({super.key});
  @override
  State<ThemeSwitcherFixture> createState() => _ThemeSwitcherFixtureState();
}

class _ThemeSwitcherFixtureState extends State<ThemeSwitcherFixture> {
  ThemeMode _value = ThemeMode.system;
  @override
  Widget build(BuildContext context) {
    final inherited = Theme.of(context).extension<KDesignTokens>()!;
    final brightness = _value == ThemeMode.system
        ? MediaQuery.platformBrightnessOf(context)
        : _value == ThemeMode.dark
        ? Brightness.dark
        : Brightness.light;
    final theme = kDesignTheme(
      brightness: brightness,
      tokenTransform: (base) => base.copyWith(
        sizeControl: inherited.sizeControl,
        sizeHitTarget: inherited.sizeHitTarget,
        spaceControlGap: inherited.spaceControlGap,
        spaceControlInsetInline: inherited.spaceControlInsetInline,
        spaceCardPadding: inherited.spaceCardPadding,
        spaceLayoutSectionGap: inherited.spaceLayoutSectionGap,
        fontControlSize: inherited.fontControlSize,
      ),
    );
    final t = theme.extension<KDesignTokens>()!;
    return Theme(
      data: theme,
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(t.spaceCardPadding),
          decoration: BoxDecoration(
            color: t.colorSurfaceCanvas,
            borderRadius: BorderRadius.circular(t.radiusCard),
          ),
          child: KStack(
            gap: KLayoutGap.section,
            align: KLayoutAlign.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: KText('Appearance', variant: KTextVariant.heading3),
                  ),
                  KThemeSwitcher(
                    value: _value,
                    onChanged: (value) => setState(() => _value = value),
                  ),
                ],
              ),
              const KText(
                'Choose Light, Dark or System. The app owns the selected preference.',
              ),
              KText(
                'Selected: ${_value.name} · Effective: ${brightness.name}',
                variant: KTextVariant.bodySmall,
              ),
              KInline(
                wrap: true,
                gap: KLayoutGap.control,
                children: [
                  KButton(label: 'Primary action', onPressed: () {}),
                  KButton(
                    label: 'Secondary action',
                    variant: KButtonVariant.secondary,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
