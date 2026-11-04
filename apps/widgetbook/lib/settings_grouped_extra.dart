import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'settings_grouped_parts.dart';
import 'settings_overhaul_dialogs.dart';

// Claude artwork: Simple Icons (CC0), matching Storybook and live Web.
const _claudeMark =
    'm4.7144 15.9555 4.7174-2.6471.079-.2307-.079-.1275h-.2307l-.7893-.0486-2.6956-.0729-2.3375-.0971-2.2646-.1214-.5707-.1215-.5343-.7042.0546-.3522.4797-.3218.686.0608 1.5179.1032 2.2767.1578 1.6514.0972 2.4468.255h.3886l.0546-.1579-.1336-.0971-.1032-.0972L6.973 9.8356l-2.55-1.6879-1.3356-.9714-.7225-.4918-.3643-.4614-.1578-1.0078.6557-.7225.8803.0607.2246.0607.8925.686 1.9064 1.4754 2.4893 1.8336.3643.3035.1457-.1032.0182-.0728-.164-.2733-1.3539-2.4467-1.445-2.4893-.6435-1.032-.17-.6194c-.0607-.255-.1032-.4674-.1032-.7285L6.287.1335 6.6997 0l.9957.1336.419.3642.6192 1.4147 1.0018 2.2282 1.5543 3.0296.4553.8985.2429.8318.091.255h.1579v-.1457l.1275-1.706.2368-2.0947.2307-2.6957.0789-.7589.3764-.9107.7468-.4918.5828.2793.4797.686-.0668.4433-.2853 1.8517-.5586 2.9021-.3643 1.9429h.2125l.2429-.2429.9835-1.3053 1.6514-2.0643.7286-.8196.85-.9046.5464-.4311h1.0321l.759 1.1293-.34 1.1657-1.0625 1.3478-.8804 1.1414-1.2628 1.7-.7893 1.36.0729.1093.1882-.0183 2.8535-.607 1.5421-.2794 1.8396-.3157.8318.3886.091.3946-.3278.8075-1.967.4857-2.3072.4614-3.4364.8136-.0425.0304.0486.0607 1.5482.1457.6618.0364h1.621l3.0175.2247.7892.522.4736.6376-.079.4857-1.2142.6193-1.6393-.3886-3.825-.9107-1.3113-.3279h-.1822v.1093l1.0929 1.0686 2.0035 1.8092 2.5075 2.3314.1275.5768-.3218.4554-.34-.0486-2.2039-1.6575-.85-.7468-1.9246-1.621h-.1275v.17l.4432.6496 2.3436 3.5214.1214 1.0807-.17.3521-.6071.2125-.6679-.1214-1.3721-1.9246L14.38 17.959l-1.1414-1.9428-.1397.079-.674 7.2552-.3156.3703-.7286.2793-.6071-.4614-.3218-.7468.3218-1.4753.3886-1.9246.3157-1.53.2853-1.9004.17-.6314-.0121-.0425-.1397.0182-1.4328 1.9672-2.1796 2.9446-1.7243 1.8456-.4128.164-.7164-.3704.0667-.6618.4008-.5889 2.386-3.0357 1.4389-1.882.929-1.0868-.0062-.1579h-.0546l-6.3385 4.1164-1.1293.1457-.4857-.4554.0608-.7467.2307-.2429 1.9064-1.3114Z';

class SgExtra extends StatefulWidget {
  const SgExtra({required this.page, this.overhaul = false, super.key});
  final bool overhaul;
  final String page;
  @override
  State<SgExtra> createState() => _SgExtraState();
}

class _SgExtraState extends State<SgExtra> {
  String client = '', expiry = '90 Tage', status = 'Auf dem neuesten Stand';
  int step = 1;
  bool copied = false;
  final name = TextEditingController();
  final tokens = ['Laptop'];
  static const config =
      '# Vorschau – kein gültiger Schlüssel\nServer: https://onzeit.example/mcp\nAuthorization: Bearer demo-not-a-real-token';
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => switch (widget.page) {
    'integrations' => _integrations(context),
    'about' => _about(context),
    _ => KStack(
      gap: KLayoutGap.section,
      align: KLayoutAlign.stretch,
      children: [
        const KInline(
          gap: KLayoutGap.control,
          children: [
            KText('Server', variant: KTextVariant.heading2),
            SgStatus('Admin'),
          ],
        ),
        const SgMuted(
          'Gilt für alle Nutzer:innen dieses Servers. Wird in der Server-Konfiguration festgelegt.',
        ),
        SgGroup(
          children: [
            SgInset(
              child: KInline(
                gap: KLayoutGap.control,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KText('Öffentliche Adresse'),
                        SgMuted('https://onzeit.example'),
                      ],
                    ),
                  ),
                  KButton(
                    label: 'Adresse kopieren',
                    variant: KButtonVariant.secondary,
                    leading: const KIcon(KIconName.copy),
                    onPressed: () async {
                      await Clipboard.setData(
                        const ClipboardData(text: 'https://onzeit.example'),
                      );
                      if (mounted) setState(() => copied = true);
                    },
                  ),
                ],
              ),
            ),
            const SgInset(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  KText('Status'),
                  SgStatus('Erreichbar · Demo', success: true),
                ],
              ),
            ),
          ],
        ),
        if (copied) const KText('Adresse kopiert'),
      ],
    ),
  };
  Widget _about(BuildContext context) => KStack(
    gap: KLayoutGap.section,
    align: KLayoutAlign.stretch,
    children: [
      SgGroup(
        children: [
          SgInset(
            child: KStack(
              gap: KLayoutGap.control,
              children: [
                const KText('Onzeit', variant: KTextVariant.heading3),
                const SgMuted('Version 0.1.0+1 · Galerie'),
                SgStatus('✓ $status', success: true),
              ],
            ),
          ),
          SgRow(
            'Nach Updates suchen',
            icon: KIconName.refreshCw,
            onTap: () async {
              if (!widget.overhaul) {
                setState(() => status = 'Keine neue Version · Demo');
                return;
              }
              final result = await showSettingsReviewDialog(
                context,
                'Update verfügbar',
              );
              if (mounted && result != null) setState(() => status = result);
            },
          ),
        ],
      ),
      for (final group in <(String, List<String>)>[
        ('Hilfe', ['Hilfe & Anleitungen', 'Feedback senden']),
        (
          'Rechtliches',
          ['Impressum', 'Datenschutz', 'AGB', 'Open-Source-Lizenzen'],
        ),
      ])
        SgGroup(
          title: group.$1,
          children: [
            for (final label in group.$2)
              SgRow(
                label,
                onTap: () => sgDialog(
                  context,
                  label,
                  KText(
                    'Hier wird in der Anwendung „$label“ geöffnet. Diese Galerie enthält keine verbindlichen Rechtstexte.',
                  ),
                ),
              ),
          ],
        ),
    ],
  );
  Widget _integrations(BuildContext context) => KStack(
    gap: KLayoutGap.section,
    align: KLayoutAlign.stretch,
    children: [
      const SgMuted(
        'Verbinde KI-Assistenten wie Claude Code oder Codex mit deinem Onzeit-Konto.',
      ),
      SgGroup(
        title: 'Neuen Assistenten verbinden',
        children: [
          SgInset(
            child: KStack(
              gap: KLayoutGap.action,
              align: KLayoutAlign.stretch,
              children: [
                Semantics(
                  label: 'Schritt $step von 3',
                  child: Row(
                    spacing:
                        Theme.of(
                          context,
                        ).extension<KDesignTokens>()!.spaceSmallInset +
                        Theme.of(
                              context,
                            ).extension<KDesignTokens>()!.spaceSmallInset /
                            2,
                    children: [
                      for (var n = 1; n <= 3; n++)
                        Expanded(
                          child: Container(
                            height: Theme.of(
                              context,
                            ).extension<KDesignTokens>()!.spaceSmallInset,
                            decoration: BoxDecoration(
                              color: step >= n
                                  ? Theme.of(context)
                                        .extension<KDesignTokens>()!
                                        .colorActionPrimaryBackground
                                  : Theme.of(context)
                                        .extension<KDesignTokens>()!
                                        .colorBorderDefault,
                              borderRadius: BorderRadius.circular(
                                Theme.of(
                                  context,
                                ).extension<KDesignTokens>()!.radiusControl,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (step == 1) ...[
                  const KText('Welchen Assistenten willst du verbinden?'),
                  Row(
                    spacing: Theme.of(
                      context,
                    ).extension<KDesignTokens>()!.spaceControlGap,
                    children: [
                      for (final c in ['Claude Code', 'Codex', 'Andere'])
                        Expanded(
                          child: KButton(
                            label: c,
                            variant: KButtonVariant.secondary,
                            paddingInline: Theme.of(
                              context,
                            ).extension<KDesignTokens>()!.spaceControlGap,
                            content: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: Theme.of(context)
                                    .extension<KDesignTokens>()!
                                    .spaceControlInsetInline,
                              ),
                              child: KStack(
                                align: KLayoutAlign.center,
                                gap: KLayoutGap.control,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: c == 'Claude Code'
                                          ? const Color(0xffd97757)
                                          : c == 'Codex'
                                          ? const Color(0xff18181b)
                                          : const Color(0xff71717a),
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: c == 'Claude Code'
                                        ? SvgPicture.string(
                                            '<svg viewBox="0 0 24 24"><path d="$_claudeMark" fill="white"/></svg>',
                                            width: 24,
                                            height: 24,
                                          )
                                        : KIcon(
                                            c == 'Codex'
                                                ? KIconName.terminal
                                                : KIconName.ellipsis,
                                            size: 24,
                                            color: Colors.white,
                                          ),
                                  ),
                                  KText(c, variant: KTextVariant.caption),
                                ],
                              ),
                            ),
                            onPressed: () => setState(() {
                              client = c;
                              name.text = '$c · Laptop';
                              step = 2;
                            }),
                          ),
                        ),
                    ],
                  ),
                ] else if (step == 2) ...[
                  KField(
                    label: 'Name des Zugangs',
                    child: KInput(
                      controller: name,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  KSelect(
                    label: 'Gültig für',
                    value: expiry,
                    options: [
                      for (final s in ['30 Tage', '90 Tage', '1 Jahr'])
                        KSelectOption(value: s, label: s),
                    ],
                    onChanged: (v) => setState(() => expiry = v!),
                  ),
                  KInline(
                    gap: KLayoutGap.action,
                    wrap: true,
                    children: [
                      KButton(
                        label: 'Zurück',
                        variant: KButtonVariant.secondary,
                        onPressed: () => setState(() => step = 1),
                      ),
                      KButton(
                        label: 'Zugang erstellen',
                        onPressed: name.text.trim().isEmpty
                            ? null
                            : () => setState(() {
                                tokens.add(name.text.trim());
                                step = 3;
                              }),
                      ),
                    ],
                  ),
                ] else ...[
                  const KText(
                    'Dieser Schlüssel wird nur jetzt angezeigt. Hier handelt es sich um einen Demo-Schlüssel.',
                  ),
                  KText('Konfiguration für $client'),
                  const SelectableText(config),
                  KButton(
                    label: copied ? 'Kopiert' : 'Konfiguration kopieren',
                    variant: KButtonVariant.secondary,
                    onPressed: () async {
                      await Clipboard.setData(
                        const ClipboardData(text: config),
                      );
                      if (mounted) setState(() => copied = true);
                    },
                  ),
                  KButton(
                    label: 'Fertig',
                    onPressed: () => setState(() {
                      step = 1;
                      copied = false;
                    }),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      SgGroup(
        title: 'Deine Zugänge',
        children: [
          for (var i = 0; i < tokens.length; i++)
            SgInset(
              child: KInline(
                gap: KLayoutGap.control,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KText(tokens[i]),
                        SgMuted('Demo-Zugang · $expiry'),
                      ],
                    ),
                  ),
                  KButton(
                    label: 'Widerrufen',
                    variant: KButtonVariant.secondary,
                    onPressed: () => setState(() => tokens.removeAt(i)),
                  ),
                ],
              ),
            ),
          if (tokens.isEmpty)
            const SgInset(child: KText('Noch keine Zugänge.')),
        ],
      ),
    ],
  );
}
