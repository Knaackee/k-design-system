part of 'admin_workspace_fixture.dart';

extension _AdminDetails on _AdminWorkspaceState {
  Widget _value(String text, {bool singleLine = false}) => KText(
    text,
    variant: KTextVariant.body,
    align: TextAlign.right,
    maxLines: singleLine ? 1 : null,
    overflow: singleLine ? TextOverflow.ellipsis : null,
  );
  Future<void> _details(BuildContext context, String kind, int index) async {
    final r = rows(kind)[index];
    final note = TextEditingController(text: kind == 'waitlist' ? r[6] : '');
    await KAdaptiveDialog.show<void>(
      context: context,
      builder: (route) => StatefulBuilder(
        builder: (route, update) {
          final current = rows(kind)[index];
          final t = Theme.of(route).extension<KDesignTokens>()!;
          void status(int column, String value) {
            change(kind, index, column, value);
            update(() {});
          }

          Widget action(
            String label,
            VoidCallback callback, {
            bool primary = false,
            bool danger = false,
          }) {
            final button = KButton(
              label: label,
              variant: primary
                  ? KButtonVariant.primary
                  : KButtonVariant.secondary,
              onPressed: callback,
            );
            return danger
                ? Theme(
                    data: Theme.of(route).copyWith(
                      extensions: [
                        ...Theme.of(
                          route,
                        ).extensions.values.where((e) => e is! KDesignTokens),
                        t.copyWith(
                          colorActionSecondaryForeground:
                              t.colorStatusErrorAccent,
                        ),
                      ],
                    ),
                    child: button,
                  )
                : button;
          }

          final values = <(String, Widget)>[];
          final actions = <Widget>[];
          final extra = <Widget>[];
          switch (kind) {
            case 'customers':
              values.addAll([
                ('Betrieb', _value(r[1])),
                ('E-Mail', _value(r[2], singleLine: true)),
                ('Beruf', _value(r[3])),
                ('Ort', _value(r[6])),
                ('Tarif', _value(r[4])),
                ('Status', AwBadge(current[5])),
                ('Kund:in seit', _value(r[7])),
                ('Buchungen', _value(r[8])),
              ]);
              actions.addAll([
                action(
                  'Passwort-Link senden',
                  () => _notice(
                    route,
                    'Passwort-Link angefordert · Demo, keine E-Mail',
                  ),
                ),
                action(
                  current[5] == 'Gesperrt' ? 'Entsperren' : 'Sperren',
                  () => status(
                    5,
                    current[5] == 'Gesperrt' ? 'Aktiv' : 'Gesperrt',
                  ),
                  danger: current[5] != 'Gesperrt',
                  primary: current[5] == 'Gesperrt',
                ),
              ]);
              extra.add(
                KText(
                  'Gesperrte Betriebe können sich nicht anmelden, ihre Buchungsseite ist offline. Bestehende Buchungen bleiben erhalten.',
                  variant: KTextVariant.caption,
                  style: TextStyle(color: t.colorTextMuted),
                ),
              );
            case 'waitlist':
              values.addAll([
                ('Beruf', _value(r[1])),
                ('Herkunft', _value(r[2])),
                ('Sprache', _value(r[3])),
                ('Angefragt', _value(r[4])),
                ('Status', AwBadge(current[5])),
              ]);
              extra.add(
                KTextarea(
                  label: 'Notiz (nur intern)',
                  controller: note,
                  onChanged: (v) => change(kind, index, 6, v),
                ),
              );
              if (current[5] == 'Neu') {
                actions.addAll([
                  action('Ablehnen', () => status(5, 'Abgelehnt')),
                  action(
                    'Freigeben & einladen',
                    () => status(5, 'Freigegeben'),
                    primary: true,
                  ),
                ]);
              }
            case 'invitations':
              values.addAll([
                ('Versand', AwBadge(current[1])),
                ('Läuft ab', _value(r[2])),
                ('Einlösung', AwBadge(current[3])),
              ]);
              if (current[3] != 'Eingelöst') {
                actions.addAll([
                  action(
                    'Widerrufen',
                    () => status(3, 'Widerrufen'),
                    danger: true,
                  ),
                  action('Erneut senden', () {
                    status(3, 'Offen');
                    _notice(
                      route,
                      'Erneut senden ausgewählt · Demo, keine E-Mail',
                    );
                  }, primary: true),
                ]);
              }
            case 'applications':
              values.addAll([
                ('Social-Profil', _value(r[1], singleLine: true)),
                ('Reichweite', _value('${r[2]} Follower')),
                ('Themen', _value(r[3])),
                ('Sprache', _value(r[4])),
                ('Status', AwBadge(current[6])),
              ]);
              extra.add(
                AwGroup(
                  'Motivation',
                  child: AwCard(
                    inset: true,
                    children: [
                      KText(r[5], style: const TextStyle(height: 1.5)),
                    ],
                  ),
                ),
              );
              actions.addAll([
                action(
                  'Profil prüfen',
                  () => _notice(
                    route,
                    'Beispielprofil · keine echte Social-Verknüpfung',
                  ),
                ),
                action('Ablehnen', () => status(6, 'Abgelehnt')),
                action(
                  'Annehmen',
                  () => status(6, 'Angenommen'),
                  primary: true,
                ),
              ]);
            case 'partners':
              values.addAll([
                (
                  'Empfehlungslink',
                  Semantics(label: r[1], child: _value(r[1], singleLine: true)),
                ),
                ('Vermittelte Anmeldungen', _value(r[2])),
                ('Conversion', _value('${r[3]} %')),
                ('Status', AwBadge(current[4])),
              ]);
              actions.addAll([
                action('Link kopieren', () {
                  Clipboard.setData(ClipboardData(text: r[1]));
                  _notice(route, 'Beispiellink kopiert');
                }),
                action(
                  current[4] == 'Aktiv' ? 'Pausieren' : 'Aktivieren',
                  () => status(4, current[4] == 'Aktiv' ? 'Pausiert' : 'Aktiv'),
                ),
              ]);
            case 'invoices':
              values.addAll([
                ('Rechnungsnummer', _value(r[0])),
                ('Betrieb', _value(r[1])),
                ('Betrag', _value(r[2])),
                ('Status', AwBadge(r[3])),
              ]);
              actions.add(
                action(
                  'PDF öffnen',
                  () =>
                      _notice(route, 'Designvorschau · kein Rechnungsdokument'),
                ),
              );
          }
          return KAdaptiveDialog(
            title: KText(r[0], variant: KTextVariant.heading3),
            maxWidth: 520,
            expandBody: false,
            onClose: () => Navigator.pop(route),
            child: KStack(
              gap: KLayoutGap.action,
              align: KLayoutAlign.stretch,
              children: [
                AwKeyValues(values),
                ...extra,
                if (actions.isNotEmpty)
                  LayoutBuilder(
                    builder: (context, box) => Wrap(
                      spacing: t.spaceControlGap,
                      runSpacing: t.spaceControlGap,
                      children: [
                        for (final a in actions)
                          SizedBox(
                            width: box.maxWidth < 330
                                ? box.maxWidth
                                : (box.maxWidth - t.spaceControlGap) / 2,
                            child: a,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
    // Allow the outgoing route's animation to release its field listeners.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    note.dispose();
  }

  void _notice(BuildContext route, String text) {
    Navigator.pop(route);
    feedback(text);
  }

  Future<void> _addAdmin(BuildContext context) async {
    final email = TextEditingController();
    String role = 'Admin';
    String? error;
    await KAdaptiveDialog.show<void>(
      context: context,
      builder: (route) => StatefulBuilder(
        builder: (route, update) => KAdaptiveDialog(
          title: const KText(
            'Admin hinzufügen',
            variant: KTextVariant.heading3,
          ),
          expandBody: false,
          onClose: () => Navigator.pop(route),
          child: KStack(
            gap: KLayoutGap.action,
            align: KLayoutAlign.stretch,
            children: [
              KField(
                label: 'E-Mail',
                child: KInput(
                  controller: email,
                  placeholder: 'name@example.invalid',
                  onChanged: (_) => update(() => error = null),
                ),
              ),
              KSelect(
                label: 'Rolle',
                value: role,
                options: [
                  for (final s in ['Admin', 'Support', 'Lesen'])
                    KSelectOption(value: s, label: s),
                ],
                onChanged: (v) => update(() => role = v!),
              ),
              if (error != null)
                KText(
                  error!,
                  style: TextStyle(
                    color: Theme.of(
                      route,
                    ).extension<KDesignTokens>()!.colorStatusErrorAccent,
                  ),
                ),
              const KText(
                'Designvorschau: keine E-Mail und keine echten Berechtigungen.',
                variant: KTextVariant.caption,
              ),
              KButton(
                label: 'Einladen',
                fullWidth: true,
                onPressed: () {
                  if (!RegExp(
                    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                  ).hasMatch(email.text)) {
                    update(
                      () =>
                          error = 'Bitte eine gültige E-Mail-Adresse eingeben.',
                    );
                    return;
                  }
                  updateState(
                    () => (data['administrators'] as List).add([
                      email.text,
                      email.text,
                      role,
                    ]),
                  );
                  Navigator.pop(route);
                  feedback('Admin zur Vorschau hinzugefügt');
                },
              ),
            ],
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    email.dispose();
  }

  Future<void> _replaceKey(BuildContext context) async {
    final controller = TextEditingController();
    await KAdaptiveDialog.show<void>(
      context: context,
      builder: (route) => KAdaptiveDialog(
        title: const KText(
          'API-Schlüssel ersetzen',
          variant: KTextVariant.heading3,
        ),
        expandBody: false,
        onClose: () => Navigator.pop(route),
        child: KStack(
          gap: KLayoutGap.action,
          align: KLayoutAlign.stretch,
          children: [
            KField(
              label: 'API-Schlüssel',
              child: KInput(
                controller: controller,
                obscureText: true,
                placeholder: 'Nur Testwert eingeben',
              ),
            ),
            const KText(
              'Dieser Wert wird nicht gespeichert.',
              variant: KTextVariant.caption,
            ),
            KButton(
              label: 'Übernehmen',
              onPressed: () => _notice(route, 'Schlüsseländerung demonstriert'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    controller.dispose();
  }
}
