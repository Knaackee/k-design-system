import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'settings_grouped_parts.dart';

const _requests = [
  ('Lea Schmidt', 'lea@example.com', 'Friseurin', 'Leipzig', 5),
  ('Mira Weber', 'mira@example.com', 'Nail Artist', 'Hamburg', 4),
  ('Tom Fischer', 'tom@example.com', 'Personal Training', 'Berlin', 5),
  ('Sophie Berger', 'sophie@example.com', 'Massage', 'Wien', 3),
];

class SgAccess extends StatefulWidget {
  const SgAccess({this.empty = false, super.key});
  final bool empty;
  @override
  State<SgAccess> createState() => _SgAccessState();
}

class _SgAccessState extends State<SgAccess> {
  String mode = 'Nur mit Einladung', filter = 'Neu', message = '';
  bool sort = true;
  final states = <String, String>{
    'tom@example.com': 'Eingeladen',
    'sophie@example.com': 'Eingelöst',
  };
  final selected = <String>{};
  void update(String mail, String state) => setState(() {
    states[mail] = state;
    selected.remove(mail);
  });
  @override
  Widget build(BuildContext context) {
    final items =
        (widget.empty ? <(String, String, String, String, int)>[] : _requests)
            .where((r) => (states[r.$2] ?? 'Neu') == filter)
            .toList();
    if (sort) items.sort((a, b) => b.$5.compareTo(a.$5));
    return KStack(
      gap: KLayoutGap.section,
      align: KLayoutAlign.stretch,
      children: [
        SgGroup(
          title: 'Neue Konten',
          footer: mode == 'Offen'
              ? 'Jede:r kann sich registrieren.'
              : mode == 'Geschlossen'
              ? 'Keine neuen Konten. Bestehende Konten können sich weiter anmelden.'
              : 'Neue Konten brauchen eine gültige Einladung. Bestehende Konten können sich weiter anmelden.',
          children: [
            SgChoices(
              items: const ['Offen', 'Nur mit Einladung', 'Geschlossen'],
              value: mode,
              onChanged: (v) => setState(() => mode = v),
            ),
          ],
        ),
        KStack(
          gap: KLayoutGap.control,
          align: KLayoutAlign.stretch,
          children: [
            KInline(
              gap: KLayoutGap.control,
              wrap: true,
              children: [
                const SgMuted('Einladungsanfragen'),
                KButton(
                  label: 'Sortieren: ${sort ? 'Priorität' : 'Neueste'}',
                  variant: KButtonVariant.ghost,
                  onPressed: () => setState(() => sort = !sort),
                ),
              ],
            ),
            SgChoices(
              items: const ['Neu', 'Eingeladen', 'Eingelöst', 'Abgelehnt'],
              value: filter,
              onChanged: (v) => setState(() {
                filter = v;
                selected.clear();
              }),
            ),
            SgGroup(
              children: [
                for (final r in items)
                  SgInset(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final t = Theme.of(context).extension<KDesignTokens>()!;
                        final compact =
                            constraints.maxWidth < t.layoutPanelWidth;
                        final actions = KInline(
                          gap: KLayoutGap.control,
                          wrap: true,
                          children: [
                            if (filter == 'Neu') ...[
                              KIconButton(
                                icon: KIconName.x,
                                label: '${r.$2} ablehnen',
                                onPressed: () => update(r.$2, 'Abgelehnt'),
                              ),
                              KIconButton(
                                icon: KIconName.send,
                                label: '${r.$2} einladen',
                                onPressed: () => update(r.$2, 'Eingeladen'),
                              ),
                            ] else if (filter == 'Eingeladen')
                              KButton(
                                label: 'Erneut senden',
                                variant: KButtonVariant.secondary,
                                onPressed: () => setState(
                                  () => message =
                                      'Erneut senden wurde in der Vorschau simuliert.',
                                ),
                              ),
                          ],
                        );
                        return KStack(
                          gap: KLayoutGap.control,
                          align: KLayoutAlign.stretch,
                          children: [
                            KInline(
                              gap: KLayoutGap.control,
                              align: KLayoutAlign.center,
                              children: [
                                if (filter == 'Neu')
                                  Semantics(
                                    label: '${r.$2} auswählen',
                                    child: KCheckbox(
                                      label: '',
                                      value: selected.contains(r.$2),
                                      onChanged: (value) => setState(() {
                                        if (value == true) {
                                          selected.add(r.$2);
                                        } else {
                                          selected.remove(r.$2);
                                        }
                                      }),
                                    ),
                                  )
                                else
                                  KIcon(
                                    filter == 'Eingelöst'
                                        ? KIconName.user
                                        : filter == 'Abgelehnt'
                                        ? KIconName.x
                                        : KIconName.send,
                                  ),
                                Expanded(
                                  child: KStack(
                                    gap: KLayoutGap.control,
                                    align: KLayoutAlign.stretch,
                                    children: [
                                      KText(r.$2, variant: KTextVariant.label),
                                      SgMuted('${r.$3} · ${r.$4}'),
                                      SgMuted('Priorität ${r.$5} von 5'),
                                    ],
                                  ),
                                ),
                                if (!compact &&
                                    (filter == 'Neu' || filter == 'Eingeladen'))
                                  actions,
                              ],
                            ),
                            if (compact &&
                                (filter == 'Neu' || filter == 'Eingeladen'))
                              Align(
                                alignment: Alignment.centerRight,
                                child: actions,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                if (items.isEmpty)
                  const SgInset(child: KText('Keine Anfragen.')),
              ],
            ),
            if (selected.isNotEmpty)
              SgGroup(
                children: [
                  SgInset(
                    child: KInline(
                      gap: KLayoutGap.control,
                      wrap: true,
                      children: [
                        KText('${selected.length} ausgewählt'),
                        KButton(
                          label: 'Alle einladen',
                          onPressed: () => setState(() {
                            for (final mail in selected) {
                              states[mail] = 'Eingeladen';
                            }
                            selected.clear();
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SgMuted(
              'Priorität ergibt sich aus den Angaben nach der Anmeldung und aus angenommenen Empfehlungen. Alle Aktionen sind lokal simuliert.',
            ),
            if (message.isNotEmpty) KText(message),
          ],
        ),
      ],
    );
  }
}

class SgAssistant extends StatefulWidget {
  const SgAssistant({super.key});
  @override
  State<SgAssistant> createState() => _SgAssistantState();
}

class _SgAssistantState extends State<SgAssistant> {
  String provider = 'OpenRouter', savedProvider = 'OpenRouter';
  final model = TextEditingController(text: 'Beispielmodell');
  final prompt = TextEditingController(
    text:
        'Du bist der persönliche Assistent des angemeldeten Onzeit-Nutzers. Antworte präzise und verwende nur bereitgestellte Werkzeuge und Daten.',
  );
  final apiKey = TextEditingController();
  late String savedModel = model.text, savedPrompt = prompt.text;
  bool replace = false, answer = false;
  bool get dirty =>
      provider != savedProvider ||
      model.text != savedModel ||
      prompt.text != savedPrompt ||
      apiKey.text.isNotEmpty;
  @override
  void dispose() {
    model.dispose();
    prompt.dispose();
    apiKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KStack(
    gap: KLayoutGap.section,
    align: KLayoutAlign.stretch,
    children: [
      const KInline(
        gap: KLayoutGap.control,
        children: [
          KText('KI-Assistent', variant: KTextVariant.heading2),
          SgStatus('Admin'),
        ],
      ),
      const SgMuted(
        'Gilt für alle Nutzer:innen dieses Servers. Designvorschau ohne Serververbindung.',
      ),
      SgGroup(
        title: 'Modell und Verbindung',
        children: [
          SgInset(
            child: KStack(
              gap: KLayoutGap.action,
              align: KLayoutAlign.stretch,
              children: [
                KSelect(
                  label: 'Anbieter',
                  value: provider,
                  options: [
                    for (final s in ['OpenRouter', 'Anthropic', 'OpenAI'])
                      KSelectOption(value: s, label: s),
                  ],
                  onChanged: (v) => setState(() => provider = v!),
                ),
                KField(
                  label: 'Modell',
                  child: KInput(
                    controller: model,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                KField(
                  label: 'API-Schlüssel',
                  child: replace
                      ? KInput(
                          controller: apiKey,
                          obscureText: true,
                          placeholder: 'Nur Testwert eingeben',
                          onChanged: (_) => setState(() {}),
                        )
                      : KInline(
                          gap: KLayoutGap.action,
                          wrap: true,
                          children: [
                            const SgStatus('Hinterlegt · Demo', success: true),
                            KButton(
                              label: 'Ersetzen',
                              variant: KButtonVariant.ghost,
                              onPressed: () => setState(() => replace = true),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      KStack(
        gap: KLayoutGap.control,
        align: KLayoutAlign.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SgMuted('Systemanweisung'),
              SgMuted('${prompt.text.length} Zeichen'),
            ],
          ),
          KTextarea(
            label: 'Systemanweisung',
            controller: prompt,
            onChanged: (_) => setState(() {}),
          ),
          KInline(
            gap: KLayoutGap.control,
            children: [
              KButton(
                label: 'Testen',
                leading: const KIcon(KIconName.play),
                variant: KButtonVariant.secondary,
                onPressed: () => setState(() => answer = true),
              ),
              const Expanded(
                child: SgMuted(
                  'Schickt eine Beispielfrage mit den aktuellen Einstellungen.',
                ),
              ),
            ],
          ),
        ],
      ),
      if (answer)
        const SgGroup(
          children: [
            SgInset(
              child: KStack(
                gap: KLayoutGap.control,
                children: [
                  SgMuted('Beispielantwort auf „Was steht heute an?“'),
                  KText(
                    'Heute hast du 4 bestätigte Termine. Der nächste ist um 11:50 bei Elisa Ferrari, 18 Minuten Fahrt.',
                  ),
                ],
              ),
            ),
          ],
        ),
      if (dirty)
        SgGroup(
          children: [
            SgInset(
              child: KInline(
                gap: KLayoutGap.control,
                wrap: true,
                children: [
                  const KText('Ungespeicherte Änderungen'),
                  KButton(
                    label: 'Verwerfen',
                    variant: KButtonVariant.secondary,
                    onPressed: () => setState(() {
                      provider = savedProvider;
                      model.text = savedModel;
                      prompt.text = savedPrompt;
                      apiKey.clear();
                      replace = false;
                    }),
                  ),
                  KButton(
                    label: 'Speichern',
                    onPressed: () => setState(() {
                      savedProvider = provider;
                      savedModel = model.text;
                      savedPrompt = prompt.text;
                      apiKey.clear();
                      replace = false;
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
    ],
  );
}
