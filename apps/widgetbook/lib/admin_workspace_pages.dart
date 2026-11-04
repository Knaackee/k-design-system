part of 'admin_workspace_fixture.dart';

extension _AdminPages on _AdminWorkspaceState {
  List<Widget> _content(BuildContext context) => switch (page) {
    'navigation' => [_navigation(context)],
    'overview' => [
      KInline(
        gap: KLayoutGap.control,
        children: [
          for (final n in [7, 30, 90])
            Expanded(
              child: KButton(
                label: '$n Tage',
                variant: days == n
                    ? KButtonVariant.primary
                    : KButtonVariant.secondary,
                onPressed: () => updateState(() => days = n),
              ),
            ),
        ],
      ),
      AwKpis([
        ('Anmeldungen', '${(128 * days / 30).round()}', '+18 %'),
        ('Aktive Betriebe', '412', '+6 %'),
        ('Offene Anfragen', '37', ''),
        ('Umsatz', '${(6840 * days / 30).round()} €', '+9 %'),
      ]),
      AwCharts(days: days),
      AwGroup(
        'Braucht Aufmerksamkeit',
        child: AwCard(
          children: [
            AwRow(
              '3 neue Wartelisten-Anfragen',
              subtitle: 'Älteste vom 03.11.',
              end: const KIcon(KIconName.chevronRight),
              onTap: () => go('waitlist'),
            ),
            AwRow(
              '2 Zahlungsfehler',
              subtitle: 'Kund:innen wurden per Mail informiert',
              end: const AwBadge('Offen'),
              onTap: () => go('subscriptions'),
            ),
            AwRow(
              'Push verzögert',
              subtitle: '3 Zustellungen fehlgeschlagen',
              end: const AwBadge('Verzögert'),
              onTap: () => go('operations'),
            ),
          ],
        ),
      ),
    ],
    'customers' => [
      _search('Name, Betrieb, E-Mail …'),
      _filters(['Alle', 'Aktiv', 'Testphase', 'Gesperrt', 'Gekündigt']),
      _list(
        'customers',
        5,
        (r, i) => AwRow(
          '${r[0]} · ${r[1]}',
          avatar: r[0],
          subtitle: '${r[2]} · ${r[3]}',
          end: AwBadge(r[5]),
          onTap: () => _details(context, 'customers', i),
        ),
      ),
    ],
    'access' => [
      AwGroup(
        'Registrierung',
        child: AwCard(
          children: [
            AwRow(
              'Registrierung aktiv',
              subtitle: 'Neue Konten können angelegt werden.',
              end: KSwitch(
                value: registration,
                onChanged: (v) => updateState(() => registration = v),
                label: 'Registrierung aktiv',
                showLabel: false,
              ),
            ),
            AwRow(
              'Einladung erforderlich',
              subtitle: 'Nur mit gültigem Einladungscode.',
              end: KSwitch(
                value: inviteOnly,
                onChanged: (v) => updateState(() => inviteOnly = v),
                label: 'Einladung erforderlich',
                showLabel: false,
              ),
            ),
          ],
        ),
      ),
      AwGroup(
        'Administratoren',
        action: KButton(
          label: 'Hinzufügen',
          leading: const KIcon(KIconName.plus),
          variant: KButtonVariant.ghost,
          onPressed: () => _addAdmin(context),
        ),
        child: AwCard(
          children: [
            for (final r in rows('administrators'))
              AwRow(
                r[0],
                subtitle: r[1],
                avatar: r[0],
                end: r[2] == 'Owner'
                    ? const AwBadge('Owner')
                    : SizedBox(
                        width: 120,
                        child: KSelect(
                          label: 'Rolle für ${r[0]}',
                          value: r[2],
                          options: [
                            for (final s in ['Admin', 'Support', 'Lesen'])
                              KSelectOption(value: s, label: s),
                          ],
                          onChanged: (v) {
                            updateState(() {
                              for (final item
                                  in data['administrators'] as List) {
                                if (item[0] == r[0]) item[2] = v;
                              }
                            });
                          },
                        ),
                      ),
              ),
          ],
        ),
      ),
      AwGroup(
        'Rollen',
        child: AwCard(
          children: [
            for (final r in rows('roles')) AwRow(r[0], subtitle: r[1]),
          ],
        ),
      ),
    ],
    'growth' => [
      const AwKpis([
        ('Anmeldungen', '128', '+18 %'),
        ('Warteliste → Konto', '41 %', '+4 %'),
        ('Aktiviert (1. Buchung)', '63 %', '-2 %'),
        ('Über Ambassadors', '74', '+22 %'),
      ]),
      const AwCharts(revenue: false),
      _growthBars(context),
      const AwGroup(
        'Kampagnen',
        child: AwCard(
          children: [
            AwRow(
              'Herbst-Launch Instagram',
              subtitle: 'utm=ig_herbst · 38 Anmeldungen',
              end: KText('9 %'),
            ),
            AwRow(
              'Friseur-Messe Leipzig',
              subtitle: 'QR am Stand · 21 Anmeldungen',
              end: KText('34 %'),
            ),
            AwRow(
              'Newsletter Oktober',
              subtitle: 'utm=nl_okt · 9 Anmeldungen',
              end: KText('5 %'),
            ),
          ],
        ),
      ),
    ],
    'subscriptions' => [
      const AwKpis([
        ('Monatlicher Umsatz', '6.840 €', '+9 %'),
        ('Aktive Abos', '287', '+5 %'),
        ('In Testphase', '64', '+12 %'),
        ('Zahlungsfehler', '2', ''),
      ]),
      const AwGroup(
        'Tarife',
        child: AwCard(
          children: [
            AwRow(
              'Solo',
              subtitle: '19 €/Monat · 14 Tage Testphase',
              end: KText('141 Abos'),
            ),
            AwRow(
              'Pro',
              subtitle: '39 €/Monat · 14 Tage Testphase',
              end: KText('118 Abos'),
            ),
            AwRow(
              'Team',
              subtitle: '79 €/Monat · 14 Tage Testphase',
              end: KText('28 Abos'),
            ),
          ],
        ),
      ),
      AwGroup(
        'Zahlungsfehler',
        child: AwCard(
          children: [
            for (final r in rows('paymentFailures'))
              AwRow(
                r[0],
                avatar: r[0],
                subtitle: '${r[1]} · ${r[2]}',
                action: KButton(
                  label: 'Erneut',
                  variant: KButtonVariant.secondary,
                  onPressed: () => feedback('Zahlungswiederholung ausgewählt'),
                ),
              ),
          ],
        ),
      ),
      AwGroup(
        'Rechnungen',
        child: AwCard(
          children: [
            for (var i = 0; i < rows('invoices').length; i++)
              AwRow(
                '${rows('invoices')[i][0]} · ${rows('invoices')[i][2]}',
                subtitle: rows('invoices')[i][1],
                end: AwBadge(rows('invoices')[i][3]),
                onTap: () => _details(context, 'invoices', i),
              ),
          ],
        ),
      ),
    ],
    'waitlist' => [
      _filters(['Alle', 'Neu', 'Freigegeben', 'Abgelehnt']),
      _list(
        'waitlist',
        5,
        (r, i) => AwRow(
          r[0],
          avatar: r[0],
          subtitle: '${r[1]} · ${r[2]} · ${r[3]} · ${r[4]}',
          end: r[5] == 'Neu' ? null : AwBadge(r[5]),
          onTap: () => _details(context, 'waitlist', i),
          action: r[5] == 'Neu'
              ? KInline(
                  gap: KLayoutGap.control,
                  children: [
                    KIconButton(
                      label: 'Ablehnen',
                      icon: KIconName.x,
                      variant: KButtonVariant.ghost,
                      onPressed: () => change('waitlist', i, 5, 'Abgelehnt'),
                    ),
                    KIconButton(
                      label: 'Freigeben',
                      icon: KIconName.check,
                      variant: KButtonVariant.secondary,
                      onPressed: () => change('waitlist', i, 5, 'Freigegeben'),
                    ),
                  ],
                )
              : null,
        ),
      ),
    ],
    'invitations' => [
      _list(
        'invitations',
        3,
        (r, i) => AwRow(
          r[0],
          avatar: r[0],
          subtitle: '${r[1]} · läuft ab ${r[2]}',
          end: AwBadge(r[3]),
          onTap: () => _details(context, 'invitations', i),
        ),
      ),
    ],
    'applications' => [
      _list(
        'applications',
        6,
        (r, i) => AwRow(
          r[0],
          avatar: r[0],
          subtitle: '${r[1]} · ${r[2]} Follower · ${r[3]}',
          end: AwBadge(r[6]),
          onTap: () => _details(context, 'applications', i),
        ),
      ),
    ],
    'partners' => [
      AwKpis([
        (
          'Aktive Ambassadors',
          '${rows('partners').where((r) => r[4] == 'Aktiv').length}',
          '',
        ),
        ('Vermittelte Anmeldungen', '83', '+22 %'),
      ]),
      _list(
        'partners',
        4,
        (r, i) => AwRow(
          r[0],
          avatar: r[0],
          subtitle: '${r[1]} · ${r[2]} Anmeldungen · ${r[3]} % Conversion',
          end: AwBadge(r[4]),
          onTap: () => _details(context, 'partners', i),
          action: KIconButton(
            label: 'Link kopieren',
            icon: KIconName.copy,
            variant: KButtonVariant.ghost,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: r[1]));
              feedback('Beispiellink kopiert');
            },
          ),
        ),
      ),
    ],
    'operations' => [
      AwGroup(
        'Dienste',
        child: AwCard(
          children: [
            for (final r in rows('systems'))
              AwRow(r[0], subtitle: r[1], end: AwBadge(r[2])),
          ],
        ),
      ),
      AwGroup(
        'Letzte Fehler',
        child: AwCard(
          children: [
            for (final r in rows('errors'))
              AwRow(
                r[0],
                subtitle: '${r[1]} · ${r[2]}',
                action: KButton(
                  label: 'Erneut',
                  variant: KButtonVariant.secondary,
                  onPressed: () => feedback('Wiederholung ausgewählt'),
                ),
              ),
          ],
        ),
      ),
      AwGroup(
        'App-Versionen',
        child: AwCard(
          children: [
            for (final r in rows('versions'))
              AwRow(
                '${r[0]} · ${r[1]}',
                subtitle: '${r[2]} auf aktueller Version',
              ),
          ],
        ),
      ),
    ],
    'assistant' => [
      AwGroup(
        'Konfiguration',
        child: AwCard(
          inset: true,
          children: [
            KStack(
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
                  onChanged: (v) => updateState(() => provider = v!),
                ),
                KSelect(
                  label: 'Modell',
                  value: model,
                  options: [
                    for (final s in ['Demo-Modell', 'Alternatives Demo-Modell'])
                      KSelectOption(value: s, label: s),
                  ],
                  onChanged: (v) => updateState(() => model = v!),
                ),
                KSelect(
                  label: 'Ausweichmodell',
                  value: fallback,
                  options: [
                    for (final s in [
                      'Kein Ausweichmodell',
                      'Alternatives Demo-Modell',
                    ])
                      KSelectOption(value: s, label: s),
                  ],
                  onChanged: (v) => updateState(() => fallback = v!),
                ),
                KField(
                  label: 'API-Schlüssel',
                  child: Row(
                    children: [
                      const Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AwBadge('Hinterlegt'),
                        ),
                      ),
                      KButton(
                        label: 'Ersetzen',
                        variant: KButtonVariant.ghost,
                        onPressed: () => _replaceKey(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const AwGroup(
        'Verbindungen',
        child: AwCard(
          children: [
            AwRow(
              'OpenRouter API',
              subtitle: 'Antwortzeit 820 ms · 1.204 Anfragen heute',
              end: AwBadge('Stabil'),
            ),
            AwRow(
              'MCP-Zugänge',
              subtitle: '14 aktive Zugänge (Claude Code, Codex)',
              end: AwBadge('Stabil'),
            ),
          ],
        ),
      ),
      KButton(
        label: 'Speichern',
        onPressed: () => feedback('Konfiguration geändert'),
      ),
    ],
    'audit' => [
      _search('Admin, Aktion, Objekt …'),
      _filters(['Alle', 'Erfolgreich', 'Fehlgeschlagen']),
      _list(
        'logs',
        4,
        (r, i) => AwRow(
          r[1],
          avatar: r[0],
          subtitle: '${r[0]} · ${r[2]} · ${r[3]}',
          end: AwBadge(r[4]),
        ),
      ),
    ],
    _ => [],
  };
}
