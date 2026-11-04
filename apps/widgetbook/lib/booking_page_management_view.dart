part of 'booking_page_management_fixture.dart';

extension _BookingPageGalleryView on _BookingPageManagementFixtureState {
  Widget buildView(BuildContext context) {
    final source = Theme.of(context).extension<KDesignTokens>()!;
    final t = settingsGroupedTokens(source, widget.dark);
    return Theme(
      data: Theme.of(context).copyWith(
        brightness: widget.dark ? Brightness.dark : Brightness.light,
        extensions: [t],
      ),
      child: Builder(
        builder: (context) => ColoredBox(
          color: t.colorSurfaceCanvas,
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: widget.mobile ? 390 : 1280,
                ),
                child: Padding(
                  padding: EdgeInsets.all(t.spaceLayoutGutter),
                  child: KBookingPageLayout(
                    preview: image(design),
                    previewAction: KButton(
                      label: 'Öffnen',
                      variant: KButtonVariant.ghost,
                      onPressed: () => dialog(
                        context,
                        'Vorschau',
                        KBookingPagePhone(child: image(design)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Buchungsseite',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'So sehen dich Kund:innen, wenn sie bei dir buchen.',
                          style: TextStyle(
                            color: t.colorTextMuted,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: t.spaceLayoutGutter),
                        KBookingPageStatus(
                          online: online,
                          url: 'onzeit.com/u/${slug.text}',
                          thumbnail: widget.mobile ? image(design) : null,
                          addressAction: KButton(
                            label: 'Adresse ändern',
                            variant: KButtonVariant.ghost,
                            onPressed: () => dialog(
                              context,
                              'Adresse ändern',
                              KField(
                                label: 'Webadresse',
                                helperText:
                                    'Diese Galerie prüft keine echte Verfügbarkeit.',
                                child: KInput(controller: slug),
                              ),
                            ),
                          ),
                          actions: [
                            action(
                              'Teilen',
                              KIconName.share,
                              () => dialog(
                                context,
                                'QR-Code',
                                KQrCode(
                                  data: 'https://onzeit.com/u/${slug.text}',
                                  label: 'Buchungsseite öffnen',
                                ),
                              ),
                              primary: true,
                            ),
                            action(
                              'Kopieren',
                              KIconName.copy,
                              () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Galerie: Beispiel-Link'),
                                ),
                              ),
                            ),
                            action(
                              'QR-Code',
                              KIconName.qrCode,
                              () => dialog(
                                context,
                                'QR-Code',
                                KQrCode(
                                  data: 'https://onzeit.com/u/${slug.text}',
                                  label: 'Buchungsseite öffnen',
                                ),
                              ),
                            ),
                            action(
                              'Vorschau',
                              KIconName.eye,
                              () => dialog(
                                context,
                                'Vorschau',
                                KBookingPagePhone(child: image(design)),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: t.spaceLayoutSectionGap),
                        KBookingPageSection(
                          title: 'Aussehen',
                          subtitle: 'Design, Farbe, Bilder',
                          defaultOpen: true,
                          child: KStack(
                            gap: KLayoutGap.control,
                            align: KLayoutAlign.stretch,
                            children: [
                              card([
                                KField(
                                  label: 'Design',
                                  child: KBookingThemePicker(
                                    options: [
                                      for (final e in _designNames.entries)
                                        KBookingThemeChoice(
                                          id: e.key,
                                          label: e.value,
                                          image: image(e.key),
                                        ),
                                    ],
                                    value: design,
                                    onChanged: (v) => refresh(() {
                                      design = v;
                                      dirty = true;
                                    }),
                                  ),
                                ),
                                KField(
                                  label: 'Markenfarbe',
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final c in [
                                        0xff0c679f,
                                        0xff7c3aed,
                                        0xffdb2777,
                                        0xffea580c,
                                        0xff047857,
                                        0xff0f766e,
                                      ])
                                        KButton(
                                          label: 'Farbe',
                                          variant: KButtonVariant.ghost,
                                          onPressed: () =>
                                              refresh(() => dirty = true),
                                          content: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(c),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ]),
                              card([
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        round ? 32 : 14,
                                      ),
                                      child: SizedBox(
                                        width: 64,
                                        height: 64,
                                        child: portrait == null
                                            ? image('portrait')
                                            : Image.memory(
                                                portrait!,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Willkommensbild',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const Text(
                                            'Großes Bild oben auf der Seite',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                          Wrap(
                                            children: [
                                              KButton(
                                                label: 'Ändern',
                                                variant:
                                                    KButtonVariant.secondary,
                                                onPressed: () =>
                                                    showAvatarEditorFixture(
                                                      context,
                                                      onAvatarChange: (v) =>
                                                          refresh(() {
                                                            portrait = v;
                                                            dirty = true;
                                                          }),
                                                      data: avatarData,
                                                    ),
                                              ),
                                              KButton(
                                                label: round ? 'Rund' : 'Eckig',
                                                variant: KButtonVariant.ghost,
                                                onPressed: () => refresh(() {
                                                  round = !round;
                                                  dirty = true;
                                                }),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                KButton(
                                  label: 'Logo hinzufügen',
                                  variant: KButtonVariant.ghost,
                                  onPressed: () => showAvatarEditorFixture(
                                    context,
                                    onAvatarChange: (_) =>
                                        refresh(() => dirty = true),
                                    data: avatarData,
                                  ),
                                ),
                              ]),
                            ],
                          ),
                        ),
                        KBookingPageSection(
                          title: 'Willkommen',
                          subtitle: 'Begrüßung, Text, Knopf',
                          defaultOpen: true,
                          child: card([
                            field('Begrüßung'),
                            field('Willkommenstext', multiline: true),
                            field('Gruß am Ende (optional)'),
                            field('Text auf dem Knopf'),
                          ]),
                        ),
                        KBookingPageSection(
                          title: 'Betrieb',
                          subtitle: 'Name, Beschreibung, Kontakt',
                          child: card([
                            field('Name deines Betriebs'),
                            field('Kurzbeschreibung', multiline: true),
                            field('Kontakt-E-Mail (optional)'),
                          ]),
                        ),
                        KBookingPageSection(
                          title: 'Buchungsablauf',
                          subtitle: 'Auswahl, Angaben, Texte',
                          child: card([
                            KBookingFlowChoice(
                              value: flow,
                              onChanged: (v) => refresh(() {
                                flow = v;
                                dirty = true;
                              }),
                            ),
                            KSwitch(
                              label: 'Telefonnummer verlangen',
                              value: phone,
                              onChanged: (v) => refresh(() {
                                phone = v;
                                dirty = true;
                              }),
                            ),
                            KButton(
                              label: 'Texte beim Einsatzort',
                              trailing: const KIcon(KIconName.chevronRight),
                              variant: KButtonVariant.ghost,
                              onPressed: () => dialog(
                                context,
                                'Texte beim Einsatzort',
                                KStack(
                                  gap: KLayoutGap.control,
                                  children: [
                                    for (final title in [
                                      'Überschrift',
                                      'Beschreibung',
                                      'Adresse suchen',
                                      'Standort verwenden',
                                    ])
                                      KField(
                                        label: title,
                                        child: KInput(
                                          placeholder: 'Standardtext',
                                          onChanged: (_) =>
                                              refresh(() => dirty = true),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        ),
                        KBookingPageSection(
                          title: 'Sichtbarkeit',
                          defaultOpen: true,
                          child: card([
                            KButton(
                              label: online
                                  ? 'Seite offline nehmen'
                                  : 'Seite wieder online stellen',
                              leading: const KIcon(KIconName.power, size: 18),
                              variant: KButtonVariant.ghost,
                              onPressed: () async {
                                final accepted = await KAlertDialog.show(
                                  context: context,
                                  title: Text(
                                    online
                                        ? 'Seite offline nehmen?'
                                        : 'Seite online stellen?',
                                  ),
                                  description: const Text(
                                    'Diese Galerie ändert keine echten Daten. Bestehende Termine bleiben erhalten.',
                                  ),
                                  cancelLabel: 'Abbrechen',
                                  actionLabel: online
                                      ? 'Offline nehmen'
                                      : 'Online stellen',
                                  destructive: online,
                                );
                                if (accepted == true && mounted) {
                                  refresh(() => online = !online);
                                }
                              },
                            ),
                          ]),
                        ),
                        if (dirty)
                          card([
                            const Text('Unveröffentlichte Änderungen'),
                            KButton(
                              label: 'Demo veröffentlichen',
                              onPressed: () => refresh(() => dirty = false),
                            ),
                          ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
