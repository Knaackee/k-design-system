import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

/// Matching Web fixture: showcase-login-assetry. No authentication or persistence.
class LoginShowcase extends StatefulWidget {
  const LoginShowcase({super.key});
  @override
  State<LoginShowcase> createState() => _LoginShowcaseState();
}

class _LoginShowcaseState extends State<LoginShowcase> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _submitted = false;
  String _message = 'Showcase – bitte nur Testdaten eingeben.';

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() => setState(() {
    _submitted = true;
    _message = _username.text.trim().isNotEmpty && _password.text.length >= 12
        ? 'Demo: Eingaben geprüft. Es wurden keine Zugangsdaten gesendet.'
        : 'Bitte ergänze die markierten Angaben.';
  });

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).extension<KDesignTokens>()!;
    final light = base.copyWith(
      colorSurfaceCanvas: const Color(0xfffcfbf8),
      colorSurfaceRaised: Colors.white,
      colorTextPrimary: const Color(0xff23221e),
      colorTextMuted: const Color(0xff78736b),
      colorBorderDefault: const Color(0xffdedbd4),
      colorBorderFocus: const Color(0xff2fa6ae),
      colorActionPrimaryBackground: const Color(0xff23221e),
      colorActionPrimaryHover: const Color(0xff4d4a44),
      colorActionPrimaryPressed: const Color(0xff302f2a),
      colorActionPrimaryForeground: Colors.white,
      colorStatusInfoAccent: const Color(0xff23221e),
      colorStatusInfoForeground: const Color(0xff23221e),
      radiusControl: 8,
      sizeControl: 44,
    );
    final dark = light.copyWith(
      colorSurfaceCanvas: const Color(0xff23221e),
      colorTextPrimary: const Color(0xfffcfbf8),
      colorTextMuted: const Color(0xffa9a29a),
    );
    return Theme(
      data: Theme.of(context).copyWith(extensions: [light]),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth <= 760;
          final gutter = light.spaceLayoutGutter;
          final section = light.spaceLayoutSectionGap;
          final contextPanel = Theme(
            data: Theme.of(context).copyWith(extensions: [dark]),
            child: ColoredBox(
              color: dark.colorSurfaceCanvas,
              child: Padding(
                padding: EdgeInsets.all(
                  compact
                      ? gutter
                      : math.max(
                          section,
                          math.min(72, constraints.maxWidth * .05),
                        ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const KText('Assetry', variant: KTextVariant.heading3),
                    if (!compact) const Spacer(),
                    SizedBox(height: section),
                    const KStack(
                      gap: KLayoutGap.action,
                      children: [
                        KText(
                          'PORTFOLIO INTELLIGENCE',
                          variant: KTextVariant.caption,
                        ),
                        KText(
                          'Mehr aus deinen Immobilien machen.',
                          variant: KTextVariant.heading1,
                        ),
                        KText(
                          'Assetry zeigt dir, wo sich Investitionen lohnen und wie du Betriebskosten nachhaltig senken kannst.',
                        ),
                      ],
                    ),
                    if (!compact) const Spacer(),
                  ],
                ),
              ),
            ),
          );
          final formPanel = Padding(
            padding: EdgeInsets.all(
              compact
                  ? gutter
                  : math.max(gutter, math.min(96, constraints.maxWidth * .07)),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: KStack(
                  align: KLayoutAlign.stretch,
                  gap: KLayoutGap.section,
                  children: [
                    const KStack(
                      gap: KLayoutGap.action,
                      children: [
                        KText(
                          'GESCHÜTZTER BEREICH',
                          variant: KTextVariant.caption,
                        ),
                        KText('Anmelden', variant: KTextVariant.heading1),
                        KText(
                          'Nutze die Zugangsdaten, die dir für Assetry bereitgestellt wurden.',
                        ),
                      ],
                    ),
                    KStack(
                      align: KLayoutAlign.stretch,
                      gap: KLayoutGap.action,
                      children: [
                        KField(
                          label: 'Benutzername',
                          required: true,
                          errorText: _submitted && _username.text.trim().isEmpty
                              ? 'Bitte Benutzername eingeben.'
                              : null,
                          child: KInput(
                            controller: _username,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                        KField(
                          label: 'Passwort',
                          required: true,
                          errorText: _submitted && _password.text.length < 12
                              ? 'Mindestens 12 Zeichen eingeben.'
                              : null,
                          child: KInput(
                            controller: _password,
                            obscureText: true,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                        KButton(label: 'Anmelden', onPressed: _submit),
                        Center(
                          child: KLink(
                            label: 'Passwort vergessen?',
                            variant: KLinkVariant.standalone,
                            onPressed: () => setState(
                              () => _message =
                                  'Demo: Hier würde die Passwort-Wiederherstellung geöffnet.',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const KText(
                      'Noch kein Zugang? Kontaktiere deine Assetry-Ansprechperson.',
                      variant: KTextVariant.bodySmall,
                    ),
                    Semantics(liveRegion: true, child: KText(_message)),
                  ],
                ),
              ),
            ),
          );
          return ColoredBox(
            color: light.colorSurfaceCanvas,
            child: SingleChildScrollView(
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [contextPanel, formPanel],
                    )
                  : SizedBox(
                      height: math.max(
                        760,
                        constraints.hasBoundedHeight
                            ? constraints.maxHeight
                            : 760,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 82, child: contextPanel),
                          Expanded(flex: 118, child: formPanel),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
