part of 'catalog_editor_fixture.dart';

extension _CatalogEditorOverlays on _CatalogEditorFixtureState {
  void save() {
    final cents = double.tryParse(price.text.replaceAll(',', '.'));
    final validName = name.text.trim().isNotEmpty && name.text.length <= 120;
    final validPrice = kind == 'request' || (cents != null && cents >= 0);
    final validDuration =
        widget.product || (int.tryParse(duration.text) ?? 0) > 0;
    final validGroups = groups.every(
      (g) =>
          g.name.text.trim().isNotEmpty &&
          (g.rule != 'required' || g.options.any((o) => o.active)) &&
          (g.rule != 'custom' ||
              ((int.tryParse(g.min.text) ?? -1) >= 0 &&
                  (g.max.text.isEmpty ||
                      (int.tryParse(g.max.text) ?? -1) >=
                          (int.tryParse(g.min.text) ?? 0)))) &&
          g.options.every(
            (o) =>
                o.name.text.trim().isNotEmpty &&
                (double.tryParse(o.price.text.replaceAll(',', '.')) ?? -1) >= 0,
          ),
    );
    update(
      () => status = !validName
          ? 'Bitte einen Namen eingeben.'
          : !validPrice
          ? 'Bitte einen gültigen Preis eingeben.'
          : !validDuration
          ? 'Bitte eine Dauer eingeben.'
          : description.text.length > 4000
          ? 'Die Beschreibung darf höchstens 4000 Zeichen enthalten.'
          : !validGroups
          ? 'Bitte Zusatzoptionen prüfen.'
          : 'Gespeichert',
    );
    if (status == 'Gespeichert') {
      widget.onSaved?.call(name.text.trim(), price.text);
    }
  }

  Future<void> discard() async {
    final yes = await KAlertDialog.show(
      context: context,
      title: const Text('Änderungen verwerfen?'),
      description: const Text(
        'Bereits gebuchte Bestandsänderungen bleiben erhalten.',
      ),
      cancelLabel: 'Weiter bearbeiten',
      actionLabel: 'Verwerfen',
    );
    if (yes != true || !mounted) return;
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    update(() {
      name.text = widget.product ? 'Styling-Set' : 'Kurzhaarschnitt';
      price.text = widget.product ? '24,90' : '32,00';
      duration.text = '30';
      description.text = widget.product
          ? 'Dein Styling für zu Hause – mit Wachs und Finish-Spray.'
          : 'Persönliche Beratung, Waschen, Schneiden und Styling.';
      category = widget.product ? 'Pflege & Styling' : 'Haarschnitte';
      threshold.text = '3';
      track = true;
      hide = true;
      for (final group in groups) {
        group.dispose();
      }
      groups.clear();
      groups.add(
        _DemoGroup(
          widget.product ? 'Verpackung' : 'Haarlänge',
          widget.product
              ? [('Geschenkbox', '2,50'), ('Stoffbeutel', '4,00')]
              : [('Schulterlang', '8,00'), ('Sehr lang', '15,00')],
        ),
      );
      recommended
        ..clear()
        ..addAll([if (!widget.product) 'Pflege-Shampoo', 'Kopfmassage']);
      imageBytes = null;
      kind = 'fixed';
      active = true;
      featured = false;
      status = 'Entwurf zurückgesetzt';
    });
  }

  Future<void> imageDialog() => showAvatarEditorFixture(
    context,
    data: avatarData,
    onAvatarChange: (bytes) {
      if (mounted) {
        update(() {
          imageBytes = bytes;
          status = 'Ungespeichert';
        });
      }
    },
  );
  Future<void> recommendations() async {
    var query = '', filter = 'all';
    final search = TextEditingController();
    const catalog = [
      ('Styling-Set', '24,90 €', 'product'),
      ('Pflege-Shampoo', '18,00 €', 'product'),
      ('Kopfmassage', '12,00 €', 'service'),
    ];
    await KAdaptiveDialog.show<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, refresh) {
          final visible = catalog
              .where(
                (c) =>
                    (filter == 'all' || filter == c.$3) &&
                    c.$1.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
          return KAdaptiveDialog(
            title: const Text('Dazu empfehlen'),
            onClose: () => Navigator.of(ctx).pop(),
            actions: KButton(
              label: 'Fertig',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            child: KStack(
              gap: KLayoutGap.action,
              align: KLayoutAlign.stretch,
              children: [
                KInput(
                  label: 'Angebote suchen',
                  placeholder: 'Angebote suchen',
                  controller: search,
                  leading: const KIcon(KIconName.search, size: 18),
                  onChanged: (v) => refresh(() => query = v),
                ),
                KTabs(
                  expanded: true,
                  value: filter,
                  onChanged: (v) => refresh(() => filter = v),
                  items: [
                    for (final p in [
                      ('all', 'Alle'),
                      ('service', 'Leistungen'),
                      ('product', 'Produkte'),
                    ])
                      KTabItem(
                        id: p.$1,
                        label: Text(p.$2),
                        content: const SizedBox.shrink(),
                      ),
                  ],
                ),
                for (final c in visible)
                  KCatalogEditorRow(
                    title: c.$1,
                    help: c.$2,
                    trailing: KCheckbox(
                      label: 'Empfehlen',
                      value: recommended.contains(c.$1),
                      onChanged: (v) {
                        update(() {
                          if (v == true) {
                            recommended.add(c.$1);
                          } else {
                            recommended.remove(c.$1);
                          }
                          status = 'Ungespeichert';
                        });
                        refresh(() {});
                      },
                    ),
                  ),
                if (visible.isEmpty)
                  KButton(
                    label: 'Keine Treffer – Suche zurücksetzen',
                    variant: KButtonVariant.ghost,
                    onPressed: () => refresh(() {
                      query = '';
                      filter = 'all';
                      search.clear();
                    }),
                  ),
              ],
            ),
          );
        },
      ),
    );
    search.dispose();
  }

  Future<void> stockDialog() async {
    var mode = 'in', reason = 'Lieferung';
    final amount = TextEditingController(text: '1');
    await KAdaptiveDialog.show<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, refresh) {
          final q = int.tryParse(amount.text),
              tokens = Theme.of(context).extension<KDesignTokens>()!;
          final next = q == null
              ? null
              : mode == 'set'
              ? q
              : stock + (mode == 'out' ? -q : q);
          final valid =
              q != null &&
              q >= (mode == 'set' ? 0 : 1) &&
              next != null &&
              next >= 2 &&
              next != stock;
          return KAdaptiveDialog(
            title: const Text('Bestand ändern'),
            onClose: () => Navigator.of(ctx).pop(),
            actions: KButton(
              label: 'Jetzt buchen',
              onPressed: !valid
                  ? null
                  : () {
                      update(() {
                        history.insert(
                          0,
                          '${next - stock >= 0 ? '+' : ''}${next - stock} · $reason',
                        );
                        stock = next;
                        status = 'Bestand in dieser Demo gebucht';
                      });
                      Navigator.of(ctx).pop();
                    },
            ),
            child: KStack(
              gap: KLayoutGap.action,
              align: KLayoutAlign.stretch,
              children: [
                Row(
                  children: [
                    for (final p in [
                      ('Auf Lager', stock),
                      ('Reserviert', 2),
                      ('Verfügbar', stock - 2),
                    ])
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(tokens.spaceControlGap / 2),
                          child: KCatalogEditorCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                KText(p.$1, variant: KTextVariant.caption),
                                KText(
                                  '${p.$2}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const KText(
                  'Bestandsänderungen gelten sofort – hier nur als Demo.',
                  variant: KTextVariant.caption,
                ),
                KTabs(
                  expanded: true,
                  value: mode,
                  onChanged: (v) => refresh(() => mode = v),
                  items: [
                    for (final p in [
                      ('in', 'Zugang'),
                      ('out', 'Abgang'),
                      ('set', 'Neu zählen'),
                    ])
                      KTabItem(
                        id: p.$1,
                        label: Text(p.$2),
                        content: const SizedBox.shrink(),
                      ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    KIconButton(
                      label: 'Menge verringern',
                      icon: KIconName.minus,
                      variant: KButtonVariant.secondary,
                      onPressed: () => refresh(
                        () =>
                            amount.text = '${((q ?? 1) - 1).clamp(0, 1000000)}',
                      ),
                    ),
                    SizedBox(width: tokens.spaceContentActionGap),
                    SizedBox(
                      width: 110,
                      child: KInput(
                        label: 'Menge',
                        controller: amount,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => refresh(() {}),
                      ),
                    ),
                    SizedBox(width: tokens.spaceContentActionGap),
                    KIconButton(
                      label: 'Menge erhöhen',
                      icon: KIconName.plus,
                      variant: KButtonVariant.secondary,
                      onPressed: () =>
                          refresh(() => amount.text = '${(q ?? 0) + 1}'),
                    ),
                  ],
                ),
                Center(child: Text('$stock → ${next ?? '–'} auf Lager')),
                if (!valid)
                  const KText(
                    'Bitte eine gültige Menge eingeben. Reservierte Ware darf nicht unterschritten werden.',
                    variant: KTextVariant.caption,
                  ),
                KSelect(
                  label: 'Grund',
                  value: reason,
                  options: [
                    for (final r in [
                      'Lieferung',
                      'Verkauf',
                      'Korrektur',
                      'Beschädigt',
                    ])
                      KSelectOption(value: r, label: r),
                  ],
                  onChanged: (v) => refresh(() => reason = v ?? reason),
                ),
                const KText(
                  'Letzte Bewegungen',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                for (final h in history.take(4))
                  KText(h, variant: KTextVariant.caption),
              ],
            ),
          );
        },
      ),
    );
    amount.dispose();
  }
}
