import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/k_map.dart';
import 'package:k_design_ui/k_map_style.dart';

import 'settings_grouped_parts.dart';
import 'settings_overhaul_dialogs.dart';

const _pages = [
  (
    'times',
    'Standorte & Zeiten',
    'Wo dein Tag beginnt und wann du nicht buchbar bist.',
    KIconName.mapPin,
  ),
  (
    'zones',
    'Zonen & Buchungsregeln',
    'Wo und wann man dich buchen kann.',
    KIconName.hexagon,
  ),
  (
    'history',
    'Änderungsverlauf',
    'Wer was wann geändert hat – nur echte Änderungen.',
    KIconName.rotateCcw,
  ),
];

class DeploymentOverhaulFixture extends StatefulWidget {
  const DeploymentOverhaulFixture({
    this.initialPage = 'times',
    this.initialSheet,
    this.empty = false,
    super.key,
  });
  final String initialPage;
  final String? initialSheet;
  final bool empty;

  @override
  State<DeploymentOverhaulFixture> createState() =>
      _DeploymentOverhaulFixtureState();
}

class _DeploymentOverhaulFixtureState extends State<DeploymentOverhaulFixture> {
  late String page = widget.initialPage;
  bool detail = true, sameAddress = true, past = false;
  String historyFilter = 'Alle';
  late String address = widget.empty
      ? ''
      : 'Seestraße 17, 92449 Steinberg am See';
  String endAddress = '', mode = 'Auto', notice = '';
  late final exceptions = widget.empty
      ? <(String, String, String)>[]
      : [
          ('private', 'Zahnarzt', '9. Nov · 12:00–13:00'),
          ('transport', 'Zu Fuß weiter', '9. Nov · 13:15'),
          ('absence', 'Fortbildung Balayage', '16.–17. Nov · Ganztägig'),
          ('absence', 'Elternabend', '19. Nov · 17:00–19:30'),
          ('absence', 'Weihnachtsurlaub', '24. Dez–3. Jan · Ganztägig'),
          ('absence', 'Krank', '30. Okt · Ganztägig'),
        ];
  late final zones = widget.empty
      ? <(String, String)>[]
      : [
          ('Steinberg & Umgebung', '15 km Umkreis · Mo–Fr · 09:00–18:00'),
          (
            'Regensburg Innenstadt',
            '4 Postleitzahlen · Di, Do · 10:00–19:00 · +8 € Anfahrt',
          ),
          ('Schwandorf Nord', 'Eigene Fläche · Sa · 09:00–14:00 · Pausiert'),
        ];
  late final history = widget.empty
      ? <(String, String)>[]
      : [
          ('Angebot gespeichert', 'Heute · Denis Knaack · Preis und Dauer'),
          ('Privater Termin hinzugefügt', 'Heute · Denis Knaack · Zahnarzt'),
          ('Zone geändert', 'Gestern · Denis Knaack · Regensburg Innenstadt'),
          (
            'Buchungsseite veröffentlicht',
            '2. Nov · Denis Knaack · Veröffentlichung',
          ),
        ];
  static const holidays = [
    '1. Weihnachtstag',
    '2. Weihnachtstag',
    'Neujahr',
    'Heilige Drei Könige',
    'Karfreitag',
    'Ostermontag',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialSheet case final sheet?) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          open(
            sheet,
            title: sheet == 'zone' && zones.isNotEmpty ? zones.first.$1 : null,
            index: sheet == 'zone' && zones.isNotEmpty ? 0 : null,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = settingsGroupedTokens(
      theme.extension<KDesignTokens>()!,
      theme.brightness == Brightness.dark,
    );
    final selected = _pages.firstWhere((item) => item.$1 == page);
    return Theme(
      data: theme.copyWith(
        extensions: [
          ...theme.extensions.values.where((e) => e is! KDesignTokens),
          tokens,
        ],
      ),
      child: KSettingsPage(
        title: selected.$2,
        description: selected.$3,
        backLabel: 'Einsatzplanung',
        onBack: () => setState(() => detail = false),
        detailVisible: detail,
        navigation: SingleChildScrollView(
          padding: EdgeInsets.all(tokens.spaceLayoutGutter),
          child: SgGroup(
            title: 'Einsatzplanung',
            children: [
              for (final item in _pages)
                SgRow(
                  item.$2,
                  icon: item.$4,
                  selected: page == item.$1,
                  navigation: true,
                  onTap: () => setState(() {
                    page = item.$1;
                    detail = true;
                    notice = '';
                  }),
                ),
            ],
          ),
        ),
        breadcrumb: KBreadcrumb(
          label: 'Brotkrümelnavigation',
          items: [
            KBreadcrumbItem(
              id: 'deployment',
              label: 'Einsatzplanung',
              onSelect: () => setState(() => detail = false),
            ),
            KBreadcrumbItem(id: page, label: selected.$2),
          ],
        ),
        content: KStack(
          gap: KLayoutGap.section,
          align: KLayoutAlign.stretch,
          children: [
            if (notice.isNotEmpty) SgMuted(notice),
            ...switch (page) {
              'zones' => zoneView(context),
              'history' => historyView(),
              _ => timesView(),
            },
          ],
        ),
      ),
    );
  }

  List<Widget> timesView() => [
    SgGroup(
      title: 'Tagesstart',
      children: [
        SgRow(
          address.isEmpty ? 'Startadresse festlegen' : address,
          icon: KIconName.mapPin,
          onTap: () => open('start'),
        ),
        SgInset(
          child: KSwitch(
            label: 'Am Startort enden',
            value: sameAddress,
            onChanged: (value) => setState(() => sameAddress = value),
          ),
        ),
        if (!sameAddress)
          SgRow(
            endAddress.isEmpty ? 'Endadresse festlegen' : endAddress,
            onTap: () => open('end'),
          ),
        SgRow(
          'Unterwegs mit',
          value: mode,
          icon: KIconName.car,
          onTap: () => open('mode'),
        ),
      ],
    ),
    SgGroup(
      title: 'Einsatzzeiten',
      children: [
        SgRow(
          'Wochenzeiten je Zone',
          description: 'Wo und wann man dich buchen kann.',
          onTap: () => setState(() => page = 'zones'),
        ),
      ],
    ),
    SgGroup(
      title: 'Ausnahmen & Termine',
      children: [
        if (exceptions.isEmpty)
          const SgInset(
            child: SgMuted(
              'Keine Ausnahmen. Füge Termine, Abwesenheiten und Feiertage hinzu.',
            ),
          ),
        if (exceptions.isNotEmpty)
          SgInset(
            child: KInline(
              wrap: true,
              children: [
                KButton(
                  label: 'Kommend',
                  variant: !past
                      ? KButtonVariant.primary
                      : KButtonVariant.ghost,
                  onPressed: () => setState(() => past = false),
                ),
                KButton(
                  label: 'Vergangen',
                  variant: past ? KButtonVariant.primary : KButtonVariant.ghost,
                  onPressed: () => setState(() => past = true),
                ),
              ],
            ),
          ),
        for (final item in exceptions.where(
          (item) => (item.$2 == 'Krank') == past,
        ))
          SgRow(
            item.$2,
            description: item.$3,
            icon: item.$1 == 'transport' ? KIconName.car : KIconName.calendar,
            onTap: () => open(item.$1, title: item.$2),
          ),
        SgRow('Hinzufügen', icon: KIconName.plus, onTap: () => open('add')),
      ],
    ),
  ];

  List<Widget> zoneView(BuildContext context) => [
    KMediaCard(
      media: Builder(
        builder: (context) {
          final t = Theme.of(context).extension<KDesignTokens>()!;
          const centers = [
            KMapCenter(longitude: 12.173, latitude: 49.286),
            KMapCenter(longitude: 12.102, latitude: 49.013),
            KMapCenter(longitude: 12.122, latitude: 49.34),
          ];
          const colors = ['#0ea5e9', '#8b5cf6', '#f59e0b'];
          return KMap(
            mapStyle: jsonEncode(createKMapStyle(tokens: t)),
            center: centers.first,
            zoom: 9,
            interactive: false,
            showZoomControls: false,
            fitContent: zones.isNotEmpty,
            fitPadding: 28,
            label: 'Beispielgebiete in der Oberpfalz',
            zones: [
              for (var i = 0; i < zones.length; i++)
                KMapZone(
                  id: 'gallery-zone-$i',
                  name: zones[i].$1,
                  color: colors[i % colors.length],
                  coordinates: List.generate(i == 0 ? 64 : 6, (point) {
                    final center = centers[i % centers.length];
                    final angle = 2 * math.pi * point / (i == 0 ? 64 : 6);
                    final radius = i == 0 ? 15 : 3;
                    return KMapCenter(
                      longitude:
                          center.longitude + math.cos(angle) * radius / 73,
                      latitude:
                          center.latitude + math.sin(angle) * radius / 111.32,
                    );
                  }),
                ),
            ],
          );
        },
      ),
      child: const SgMuted(
        'Gebiete, Zeiten und Buchungsregeln gelten gemeinsam.',
      ),
    ),
    SgGroup(
      title: 'Deine Zonen',
      children: [
        if (zones.isEmpty)
          const SgInset(
            child: SgMuted(
              'Noch keine Zonen. Lege fest, wo und wann man dich buchen kann.',
            ),
          ),
        for (var i = 0; i < zones.length; i++)
          SgRow(
            zones[i].$1,
            description: zones[i].$2,
            icon: KIconName.mapPin,
            onTap: () => open('zone', title: zones[i].$1, index: i),
          ),
        SgRow('Neue Zone', icon: KIconName.plus, onTap: () => open('zone')),
      ],
    ),
  ];

  String historyArea(String title) {
    if (title.startsWith('Angebot')) return 'Angebot';
    if (title.startsWith('Zone')) return 'Zonen';
    if (title.startsWith('Buchungsseite')) return 'Buchungsseite';
    return 'Zeiten';
  }

  List<Widget> historyView() => [
    if (history.isNotEmpty)
      KInline(
        wrap: true,
        children: [
          for (final label in [
            'Alle',
            'Angebot',
            'Zeiten',
            'Zonen',
            'Buchungsseite',
          ])
            KButton(
              label: label,
              variant: historyFilter == label
                  ? KButtonVariant.primary
                  : KButtonVariant.ghost,
              onPressed: () => setState(() => historyFilter = label),
            ),
        ],
      ),
    SgGroup(
      title: 'Letzte Änderungen',
      children: [
        if (history.isEmpty)
          const SgInset(
            child: SgMuted(
              'Noch keine Änderungen. Gespeicherte Änderungen erscheinen hier.',
            ),
          ),
        for (final item in history.where(
          (item) =>
              historyFilter == 'Alle' || historyArea(item.$1) == historyFilter,
        ))
          SgRow(
            item.$1,
            description: item.$2,
            icon: KIconName.rotateCcw,
            onTap: () => open('history', title: item.$1),
          ),
      ],
    ),
  ];

  Future<void> open(String sheet, {String? title, int? index}) async {
    final pageSheet = reviewPageSheetPreference.value && sheet != 'undo';
    Widget builder(BuildContext c) => _DeploymentReviewSheet(
      sheet: sheet,
      title: title,
      pageSheet: pageSheet,
      address: sheet == 'start' ? address : endAddress,
      mode: mode,
      holidays: holidays,
    );
    final result = await (pageSheet
        ? KPageSheet.show<(String, String)>(context: context, builder: builder)
        : KAdaptiveDialog.show<(String, String)>(
            context: context,
            builder: builder,
          ));
    if (!mounted || result == null) return;
    if (sheet == 'add' || sheet == 'history') {
      await open(result.$1, title: title);
      return;
    }
    setState(() {
      switch (sheet) {
        case 'start':
          address = result.$1;
        case 'end':
          endAddress = result.$1;
        case 'mode':
          mode = result.$1;
        case 'zone':
          if (index == null) {
            zones.add(result);
          } else {
            zones[index] = result;
          }
        case 'holidays':
          for (final holiday in result.$1.split('|')) {
            exceptions.add(('absence', holiday, 'Feiertag · Ganztägig'));
          }
        case 'undo':
          history.insert(0, ('Änderung rückgängig gemacht', 'Heute · Galerie'));
        default:
          exceptions.add((sheet, result.$1, result.$2));
      }
      notice = 'In dieser Vorschau übernommen.';
    });
  }
}

class _DeploymentReviewSheet extends StatefulWidget {
  const _DeploymentReviewSheet({
    required this.sheet,
    required this.pageSheet,
    required this.address,
    required this.mode,
    required this.holidays,
    this.title,
  });
  final String sheet, address, mode;
  final String? title;
  final bool pageSheet;
  final List<String> holidays;

  @override
  State<_DeploymentReviewSheet> createState() => _DeploymentReviewSheetState();
}

class _DeploymentReviewSheetState extends State<_DeploymentReviewSheet> {
  late final name = TextEditingController(text: widget.title);
  late final location = TextEditingController(text: widget.address);
  final date = TextEditingController(text: '2026-11-09');
  final endDate = TextEditingController(text: '2026-11-09');
  final start = TextEditingController(text: '12:00');
  final end = TextEditingController(text: '13:00');
  final fee = TextEditingController(text: '0');
  late String mode = widget.mode;
  String region = 'Bayern',
      zoneType = 'Umkreis',
      country = 'Deutschland',
      lead = '24 Stunden';
  bool allDay = false, zoneActive = true;
  double radius = 15;
  final days = {'Mo', 'Di', 'Mi', 'Do', 'Fr'};
  final selected = <String>{};

  @override
  void dispose() {
    for (final c in [name, location, date, endDate, start, end, fee]) {
      c.dispose();
    }
    super.dispose();
  }

  void close([(String, String)? result]) => Navigator.of(context).pop(result);

  Widget field(String label, TextEditingController controller) => KField(
    label: label,
    child: KInput(controller: controller, onChanged: (_) => setState(() {})),
  );
  Widget choice(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> change,
  ) => KField(
    label: label,
    child: KSelect(
      value: value,
      options: [
        for (final option in options)
          KSelectOption(value: option, label: option),
      ],
      onChanged: (value) {
        if (value != null) setState(() => change(value));
      },
    ),
  );
  Widget save(VoidCallback? onPressed, [String label = 'Übernehmen']) =>
      KButton(label: label, onPressed: onPressed);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final title = switch (widget.sheet) {
      'start' => 'Startadresse festlegen',
      'end' => 'Endadresse festlegen',
      'mode' => 'Verkehrsmittel',
      'add' => 'Ausnahme hinzufügen',
      'private' => 'Privater Termin',
      'transport' => 'Verkehrsmittel wechseln',
      'absence' => 'Abwesenheit',
      'holidays' => 'Feiertage übernehmen',
      'zone' => widget.title == null ? 'Neue Zone' : 'Zone bearbeiten',
      'history' => 'Änderung im Detail',
      'historyPreview' => 'Historische Vorschau',
      _ => 'Änderung rückgängig machen?',
    };
    final zoneDescription = zoneType == 'Umkreis'
        ? '${radius.round()} km Umkreis'
        : zoneType;
    final validTime = RegExp(r'^([01][0-9]|2[0-3]):[0-5][0-9]$');
    final validRange =
        allDay ||
        validTime.hasMatch(start.text) &&
            validTime.hasMatch(end.text) &&
            start.text.compareTo(end.text) < 0;
    final body = Padding(
      padding: EdgeInsets.only(bottom: t.spaceContentActionGap),
      child: KStack(
        gap: KLayoutGap.action,
        align: KLayoutAlign.stretch,
        children: [
          ...switch (widget.sheet) {
            'start' || 'end' => [
              field('Adresse', location),
              save(
                location.text.trim().isEmpty
                    ? null
                    : () => close((location.text.trim(), '')),
              ),
            ],
            'mode' => [
              choice('Unterwegs mit', mode, [
                'Auto',
                'Fahrrad',
                'Zu Fuß',
              ], (v) => mode = v),
              save(() => close((mode, ''))),
            ],
            'add' => [
              for (final item in [
                ('absence', 'Abwesenheit'),
                ('private', 'Privater Termin'),
                ('transport', 'Verkehrsmittel wechseln'),
                ('holidays', 'Feiertage übernehmen'),
              ])
                KButton(
                  label: item.$2,
                  variant: KButtonVariant.secondary,
                  onPressed: () => close((item.$1, '')),
                ),
            ],
            'holidays' => [
              choice('Land', country, ['Deutschland', 'Österreich'], (v) {
                country = v;
                region = v == 'Deutschland' ? 'Bayern' : 'Wien';
                selected.clear();
              }),
              choice(
                'Bundesland',
                region,
                country == 'Deutschland'
                    ? ['Bayern', 'Sachsen', 'Berlin']
                    : ['Wien', 'Tirol'],
                (v) {
                  region = v;
                  selected.clear();
                },
              ),
              for (final name in widget.holidays.where(
                (n) => n != 'Heilige Drei Könige' || region == 'Bayern',
              ))
                KCheckbox(
                  label: name,
                  value: selected.contains(name),
                  onChanged: (value) => setState(() {
                    if (value == true) {
                      selected.add(name);
                    } else {
                      selected.remove(name);
                    }
                  }),
                ),
              save(
                selected.isEmpty ? null : () => close((selected.join('|'), '')),
                '${selected.length} übernehmen',
              ),
            ],
            'zone' => [
              field('Name', name),
              choice('Gebiet', zoneType, [
                'Umkreis',
                'Postleitzahlen',
                'Eigene Fläche',
              ], (v) => zoneType = v),
              if (zoneType == 'Umkreis')
                KStack(
                  gap: KLayoutGap.control,
                  align: KLayoutAlign.stretch,
                  children: [
                    KInline(
                      wrap: true,
                      children: [
                        const KText(
                          'Luftlinie um deine Startadresse',
                          variant: KTextVariant.label,
                        ),
                        KText(
                          '${radius.round()} km',
                          variant: KTextVariant.label,
                        ),
                      ],
                    ),
                    KSlider(
                      min: 3,
                      max: 40,
                      divisions: 37,
                      label: 'Luftlinie um deine Startadresse',
                      value: radius,
                      valueLabel: (value) => '${value.round()} km',
                      onChanged: (value) => setState(() => radius = value),
                    ),
                  ],
                )
              else
                field(
                  zoneType == 'Postleitzahlen'
                      ? 'Postleitzahlen'
                      : 'Gebietsbeschreibung',
                  location,
                ),
              const KText('Wochenzeiten', variant: KTextVariant.label),
              KInline(
                wrap: true,
                children: [
                  for (final d in ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'])
                    KButton(
                      label: d,
                      variant: days.contains(d)
                          ? KButtonVariant.primary
                          : KButtonVariant.secondary,
                      onPressed: () => setState(() {
                        if (!days.remove(d)) days.add(d);
                      }),
                    ),
                ],
              ),
              field('Von', start),
              field('Bis', end),
              choice('Vorlaufzeit', lead, [
                '2 Stunden',
                '12 Stunden',
                '24 Stunden',
                '48 Stunden',
              ], (v) => lead = v),
              field('Anfahrtspauschale (€)', fee),
              KSwitch(
                label: 'Zone aktiv',
                value: zoneActive,
                onChanged: (v) => setState(() => zoneActive = v),
              ),
              save(
                name.text.trim().isEmpty || days.isEmpty || !validRange
                    ? null
                    : () => close((
                        name.text.trim(),
                        '$zoneDescription · ${days.join(', ')} · ${start.text}–${end.text}${zoneActive ? '' : ' · Inaktiv'}',
                      )),
                'Zone speichern',
              ),
            ],
            'history' => [
              KText(
                widget.title ?? 'Angebot gespeichert',
                variant: KTextVariant.label,
              ),
              const SgMuted('Heute · Denis Knaack'),
              const SgGroup(
                title: 'Geänderte Felder',
                children: [
                  SgRow('Preis', description: '85 € → 95 €'),
                  SgRow('Dauer', description: '45 → 60 Min.'),
                ],
              ),
              KButton(
                label: 'Historische Vorschau',
                variant: KButtonVariant.secondary,
                onPressed: () => close(('historyPreview', '')),
              ),
              KButton(
                label: 'Änderung rückgängig machen',
                variant: KButtonVariant.ghost,
                onPressed: () => close(('undo', '')),
              ),
            ],
            'historyPreview' => [
              const SgMuted('Historischer Stand · schreibgeschützt'),
              KText(
                widget.title ?? 'Angebot gespeichert',
                variant: KTextVariant.label,
              ),
              const SgGroup(
                children: [
                  SgRow('Preis', value: '85 €'),
                  SgRow('Dauer', value: '45 Min.'),
                ],
              ),
            ],
            'undo' => [
              const SgMuted(
                'Der frühere Stand wird als neue Änderung gespeichert.',
              ),
              save(() => close(('undo', '')), 'Rückgängig machen'),
            ],
            _ => [
              if (widget.sheet != 'transport') field('Titel', name),
              field(widget.sheet == 'transport' ? 'Ab' : 'Datum', date),
              if (widget.sheet == 'absence') field('Bis Datum', endDate),
              if (widget.sheet != 'transport')
                KSwitch(
                  label: 'Ganztägig',
                  value: allDay,
                  onChanged: (v) => setState(() => allDay = v),
                ),
              if (!allDay) ...[
                field('Von', start),
                if (widget.sheet != 'transport') field('Bis', end),
              ],
              if (widget.sheet == 'transport')
                choice('Verkehrsmittel', mode, [
                  'Auto',
                  'Fahrrad',
                  'Zu Fuß',
                ], (v) => mode = v),
              if (widget.sheet != 'absence')
                field(
                  widget.sheet == 'private' ? 'Adresse' : 'Wo wechselst du?',
                  location,
                ),
              save(
                (widget.sheet == 'transport' || name.text.trim().isNotEmpty) &&
                        DateTime.tryParse(date.text) != null &&
                        validRange
                    ? () => close((
                        widget.sheet == 'transport'
                            ? 'Mit $mode weiter'
                            : name.text.trim(),
                        '${date.text} · ${allDay ? 'Ganztägig' : '${start.text}–${end.text}'}',
                      ))
                    : null,
                'Speichern',
              ),
            ],
          },
          KButton(
            label: 'Schließen',
            variant: KButtonVariant.ghost,
            onPressed: close,
          ),
        ],
      ),
    );
    final heading = KText(title, variant: KTextVariant.heading3);
    return widget.pageSheet
        ? KPageSheet(
            title: heading,
            onClose: close,
            closeLabel: 'Schließen',
            child: body,
          )
        : KAdaptiveDialog(
            title: heading,
            onClose: close,
            closeLabel: 'Schließen',
            expandBody: const [
              'zone',
              'holidays',
              'private',
              'absence',
              'transport',
            ].contains(widget.sheet),
            child: body,
          );
  }
}
