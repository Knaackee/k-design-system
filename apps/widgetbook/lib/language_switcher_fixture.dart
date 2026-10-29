import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class LanguageSwitcherFixture extends StatefulWidget {
  const LanguageSwitcherFixture({
    this.disabled = false,
    this.flags = false,
    super.key,
  });
  final bool disabled;
  final bool flags;
  @override
  State<LanguageSwitcherFixture> createState() =>
      _LanguageSwitcherFixtureState();
}

class _LanguageSwitcherFixtureState extends State<LanguageSwitcherFixture> {
  String language = 'de';
  ThemeMode mode = ThemeMode.light;
  static const copy = {
    'de': [
      'Willkommen bei Onzeit',
      'Dein Unternehmen. Dein Alltag. Deine Sprache.',
    ],
    'en': ['Welcome to Onzeit', 'Your business. Your day. Your language.'],
    'fr': [
      'Bienvenue chez Onzeit',
      'Votre entreprise. Votre quotidien. Votre langue.',
    ],
    'es': [
      'Te damos la bienvenida a Onzeit',
      'Tu negocio. Tu día a día. Tu idioma.',
    ],
    'it': [
      'Benvenuto su Onzeit',
      'La tua attività. La tua giornata. La tua lingua.',
    ],
  };
  @override
  Widget build(BuildContext context) {
    final inherited = Theme.of(context).extension<KDesignTokens>()!;
    final brightness = mode == ThemeMode.system
        ? MediaQuery.platformBrightnessOf(context)
        : mode == ThemeMode.dark
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
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 720),
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
                      child: KText('onzeit', variant: KTextVariant.heading3),
                    ),
                    KInline(
                      gap: KLayoutGap.control,
                      align: KLayoutAlign.center,
                      children: [
                        KLanguageSwitcher(
                          value: language,
                          onChanged: (value) =>
                              setState(() => language = value),
                          label: 'Sprache / Language',
                          disabled: widget.disabled,
                          languages: [
                            for (final item in const [
                              ['de', 'Deutsch', '🇩🇪'],
                              ['en', 'English', '🇬🇧'],
                              ['fr', 'Français', '🇫🇷'],
                              ['es', 'Español', '🇪🇸'],
                              ['it', 'Italiano', '🇮🇹'],
                            ])
                              KLanguageOption(
                                value: item[0],
                                label: item[1],
                                flag: widget.flags ? Text(item[2]) : null,
                              ),
                          ],
                        ),
                        KThemeSwitcher(
                          value: mode,
                          onChanged: (value) => setState(() => mode = value),
                        ),
                      ],
                    ),
                  ],
                ),
                KStack(
                  gap: KLayoutGap.control,
                  children: [
                    KText(copy[language]![0], variant: KTextVariant.heading2),
                    KText(copy[language]![1]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
