part of 'catalog_editor_fixture.dart';

extension _CatalogEditorView on _CatalogEditorFixtureState {
  Widget editorView(BuildContext context) {
    final dark = widget.dark || Theme.of(context).brightness == Brightness.dark;
    final tokens = settingsGroupedTokens(t, dark).copyWith(
      radiusControl: 12,
      sizeControl: 50,
      fontControlSize: 15.5,
      componentBadgeMinHeight: 18,
      componentBadgePaddingBlock: 2,
      componentBadgePaddingInline: 8,
    );
    return Theme(
      data: Theme.of(context).copyWith(
        brightness: dark ? Brightness.dark : Brightness.light,
        extensions: [tokens],
      ),
      child: Builder(
        builder: (context) => KCatalogEditorDialog(
          title: Text('${widget.product ? 'Produkt' : 'Leistung'} bearbeiten'),
          description: Text(
            '${widget.product ? 'Produkt' : 'Leistung'} · Änderungen als Entwurf',
          ),
          onClose: discard,
          actions: Row(
            children: [
              Expanded(
                child: KText(
                  status,
                  variant: KTextVariant.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              SizedBox(width: tokens.spaceControlGap),
              Flexible(
                child: KButton(
                  label: 'Abbrechen',
                  paddingInline: 12,
                  variant: KButtonVariant.secondary,
                  onPressed: discard,
                ),
              ),
              SizedBox(width: tokens.spaceControlGap),
              Flexible(
                child: KButton(
                  label: 'Speichern',
                  paddingInline: 12,
                  onPressed: save,
                ),
              ),
            ],
          ),
          child: KCatalogEditorBody(
            preview: KCatalogEditorPreview(
              image: KButton(
                label: 'Bild ändern',
                variant: KButtonVariant.secondary,
                content: imageBytes == null
                    ? const KIcon(KIconName.image, size: 24)
                    : Image.memory(
                        imageBytes!,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                      ),
                onPressed: imageDialog,
              ),
              name: name.text,
              subtitle:
                  '${widget.product ? '' : '${duration.text} Min · '}${kind == 'request' ? 'Preis auf Anfrage' : '${kind == 'from' ? 'ab ' : ''}${price.text} €'}',
              tags: [
                if (widget.product && track)
                  KBadge(
                    variant: stock - 2 <= (int.tryParse(threshold.text) ?? 3)
                        ? KBadgeVariant.warning
                        : KBadgeVariant.success,
                    child: Text('${stock - 2} verfügbar'),
                  ),
                if (featured)
                  const KBadge(
                    variant: KBadgeVariant.info,
                    child: Text('★ Hervorgehoben'),
                  ),
                if (groups.isNotEmpty)
                  KBadge(
                    variant: KBadgeVariant.secondary,
                    child: Text(
                      '+ ${groups.map((g) => g.name.text).join(", ")}',
                    ),
                  ),
              ],
            ),
            children: [
              KCatalogEditorSection(
                title: 'Grunddaten',
                child: card([
                  input('Name', name),
                  KField(
                    labelStyle: fieldLabelStyle,
                    helperStyle: fieldHelperStyle,
                    label: 'Kategorie',
                    child: KSelect(
                      value: category,
                      options: const [
                        KSelectOption(
                          value: 'Haarschnitte',
                          label: 'Haarschnitte',
                        ),
                        KSelectOption(
                          value: 'Pflege & Styling',
                          label: 'Pflege & Styling',
                        ),
                        KSelectOption(value: 'Extras', label: 'Extras'),
                      ],
                      onChanged: (v) => update(() => category = v ?? category),
                    ),
                  ),
                  KField(
                    labelStyle: fieldLabelStyle,
                    helperStyle: fieldHelperStyle,
                    label: 'Beschreibung (optional)',
                    child: KTextarea(
                      controller: description,
                      rows: 3,
                      onChanged: changed,
                    ),
                  ),
                  KText(
                    '${description.text.length}/4000 · erscheint auf deiner Buchungsseite',
                    variant: KTextVariant.caption,
                  ),
                ]),
              ),
              KCatalogEditorSection(
                title: widget.product ? 'Preis' : 'Preis & Dauer',
                child: card([
                  KTabs(
                    expanded: true,
                    value: kind,
                    onChanged: (v) => update(() => kind = v),
                    items: [
                      for (final p in [
                        ('fixed', 'Festpreis'),
                        ('from', 'Ab-Preis'),
                        ('request', 'Auf Anfrage'),
                      ])
                        KTabItem(
                          id: p.$1,
                          label: Text(p.$2),
                          content: const SizedBox.shrink(),
                        ),
                    ],
                  ),
                  if (kind == 'request')
                    const KText(
                      'Kund:innen senden eine Anfrage, du nennst den Preis danach.',
                      variant: KTextVariant.caption,
                    ),
                  Row(
                    children: [
                      if (kind != 'request')
                        Expanded(
                          child: input(
                            kind == 'from' ? 'Preis ab' : 'Preis',
                            price,
                            suffix: '€',
                          ),
                        ),
                      if (!widget.product) ...[
                        if (kind != 'request')
                          SizedBox(width: tokens.spaceContentActionGap),
                        Expanded(
                          child: input('Dauer', duration, suffix: 'Min'),
                        ),
                      ],
                    ],
                  ),
                  if (!widget.product)
                    KInline(
                      gap: KLayoutGap.control,
                      wrap: true,
                      children: [
                        for (final n in [15, 30, 45, 60, 90])
                          KButton(
                            label: '$n Min',
                            variant: duration.text == '$n'
                                ? KButtonVariant.primary
                                : KButtonVariant.secondary,
                            onPressed: () => update(() => duration.text = '$n'),
                          ),
                      ],
                    ),
                ]),
              ),
              if (widget.product)
                KCatalogEditorSection(
                  title: 'Bestand',
                  child: KCatalogEditorCard(
                    inset: false,
                    child: Column(
                      children: [
                        toggle(
                          'Bestand führen',
                          'Verkäufe und Reservierungen werden mitgezählt.',
                          track,
                          (v) => track = v,
                        ),
                        if (track) ...[
                          KCatalogEditorRow(
                            title: '${stock - 2} verfügbar',
                            help: '$stock auf Lager · 2 reserviert',
                            divider: true,
                            trailing: KButton(
                              label: 'Ändern',
                              variant: KButtonVariant.ghost,
                              trailing: const KIcon(
                                KIconName.chevronRight,
                                size: 16,
                              ),
                              onPressed: stockDialog,
                            ),
                          ),
                          toggle(
                            'Bei 0 ausblenden',
                            'Kund:innen sehen das Produkt nicht, wenn nichts verfügbar ist.',
                            hide,
                            (v) => hide = v,
                            divider: true,
                          ),
                          KCatalogEditorRow(
                            title: 'Warnen ab',
                            help:
                                'Hinweis „Nur noch wenige“ in deiner Übersicht.',
                            divider: true,
                            trailing: SizedBox(
                              width: 96,
                              child: KInput(
                                label: 'Warnen ab',
                                controller: threshold,
                                trailingAction: const Text('Stk.'),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              KCatalogEditorSection(
                title: 'Sichtbarkeit',
                child: KCatalogEditorCard(
                  inset: false,
                  child: Column(
                    children: [
                      toggle(
                        'Buchbar',
                        'Kund:innen können ${widget.product ? 'das Produkt' : 'diese Leistung'} auf deiner Seite wählen.',
                        active,
                        (v) => active = v,
                      ),
                      toggle(
                        'Hervorheben',
                        'Erscheint oben in deinem Angebot.',
                        featured,
                        (v) => featured = v,
                        divider: true,
                      ),
                    ],
                  ),
                ),
              ),
              optionsSection(tokens),
              KCatalogEditorSection(
                title: 'Dazu empfehlen',
                action: KButton(
                  label: 'Bearbeiten',
                  variant: KButtonVariant.ghost,
                  onPressed: recommendations,
                ),
                help:
                    'Wird nach der Auswahl vorgeschlagen, nicht automatisch hinzugefügt.',
                child: card([
                  KInline(
                    gap: KLayoutGap.control,
                    wrap: true,
                    children: [
                      for (final r in recommended)
                        KButton(
                          label: r,
                          trailing: const KIcon(KIconName.x, size: 12),
                          variant: KButtonVariant.secondary,
                          onPressed: () => update(() => recommended.remove(r)),
                        ),
                    ],
                  ),
                ]),
              ),
              KCatalogEditorSection(
                title: '',
                help:
                    'Nicht mehr buchbar. Bestehende Termine bleiben erhalten.',
                child: card([
                  KButton(
                    label:
                        '${widget.product ? 'Produkt' : 'Leistung'} archivieren',
                    content: Text(
                      '${widget.product ? 'Produkt' : 'Leistung'} archivieren',
                      style: TextStyle(color: tokens.colorStatusErrorAccent),
                    ),
                    leading: KIcon(
                      KIconName.archive,
                      color: tokens.colorStatusErrorAccent,
                    ),
                    variant: KButtonVariant.ghost,
                    onPressed: () async {
                      final yes = await KAlertDialog.show(
                        context: context,
                        title: const Text('Angebot archivieren?'),
                        description: const Text(
                          'Bestehende Termine bleiben erhalten.',
                        ),
                        cancelLabel: 'Abbrechen',
                        actionLabel: 'Archivieren',
                      );
                      if (yes == true) {
                        update(() {
                          active = false;
                          status = 'In dieser Demo archiviert';
                        });
                      }
                    },
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
