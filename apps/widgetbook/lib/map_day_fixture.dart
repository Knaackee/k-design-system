import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/k_map.dart';
import 'package:k_design_ui/k_map_day_view.dart';
import 'package:k_design_ui/k_map_style.dart';
import 'package:widgetbook/widgetbook.dart';

Widget buildMapDayDesktop(BuildContext context) =>
    _buildMapDayFixture(context, presentation: KMapDayPresentation.auto);

Widget buildMapDayTablet(BuildContext context) => _buildMapDayFixture(
  context,
  frameWidth: 1024,
  presentation: KMapDayPresentation.sidebar,
);

Widget buildMapDayMobile(BuildContext context) => _buildMapDayFixture(
  context,
  frameWidth: 390,
  presentation: KMapDayPresentation.sheet,
);

Widget _buildMapDayFixture(
  BuildContext context, {
  double? frameWidth,
  required KMapDayPresentation presentation,
}) => _MapDayFixture(
  frameWidth: frameWidth,
  now: context.knobs.int.slider(
    label: 'Aktuelle Zeit · Minuten ab Mitternacht',
    initialValue: 560,
    min: 535,
    max: 760,
  ),
  delay: context.knobs.int.slider(
    label: 'Erwartete Verspätung in Minuten',
    initialValue: 5,
    min: 0,
    max: 60,
    divisions: 12,
  ),
  showCurrentTime: context.knobs.boolean(
    label: 'Aktuelle Zeit anzeigen',
    initialValue: true,
  ),
  customPanel: context.knobs.boolean(
    label: 'Custom docked panel',
    initialValue: false,
  ),
  showForecasts: context.knobs.boolean(
    label: 'Prognosen anzeigen',
    initialValue: true,
  ),
  panelWidth: context.knobs.double.slider(
    label: 'Panelbreite',
    initialValue: 404,
    min: 280,
    max: 460,
    divisions: 45,
  ),
  presentation: context.knobs.object.dropdown<KMapDayPresentation>(
    label: 'Darstellung',
    initialOption: presentation,
    options: const [
      KMapDayPresentation.auto,
      KMapDayPresentation.sidebar,
      KMapDayPresentation.sheet,
    ],
    labelBuilder: (value) => value.name,
  ),
);

class _MapDayFixture extends StatefulWidget {
  const _MapDayFixture({
    this.frameWidth,
    required this.now,
    required this.delay,
    required this.showCurrentTime,
    required this.showForecasts,
    required this.panelWidth,
    this.presentation = KMapDayPresentation.auto,
    this.customPanel = false,
  });

  final double? frameWidth;
  final int now;
  final int delay;
  final bool showCurrentTime;
  final bool showForecasts;
  final double panelWidth;
  final KMapDayPresentation presentation;
  final bool customPanel;

  @override
  State<_MapDayFixture> createState() => _MapDayFixtureState();
}

class _MapDayFixtureState extends State<_MapDayFixture> {
  final _sheetController = KMapDaySheetController();
  String? _selected = 'drive-1';
  String _event = 'Wähle einen Eintrag oder eine Kartenposition.';

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(_showSheetPosition);
  }

  @override
  void dispose() {
    _sheetController
      ..removeListener(_showSheetPosition)
      ..dispose();
    super.dispose();
  }

  void _showSheetPosition() {
    if (mounted) setState(() {});
  }

  void _focusItem(String id) {
    if (!_sheetController.isSheet) return;
    unawaited(_sheetController.animateTo(.45));
    setState(() => _event = 'Fokus: $id');
  }

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final style = jsonEncode(createKMapStyle(tokens: tokens));
    final items = _entriesFor(widget.now, widget.delay);
    final sidebar =
        widget.presentation == KMapDayPresentation.sidebar ||
        (widget.presentation == KMapDayPresentation.auto &&
            (widget.frameWidth ?? MediaQuery.sizeOf(context).width) > 700);
    final fixture = KMapDayView(
      items: items,
      currentTime: widget.now,
      title: 'Dein Tag unterwegs',
      dayLabel: 'Dienstag, 20. Oktober',
      selectedItemId: _selected,
      selectionControlled: true,
      sheetController: _sheetController,
      presentation: widget.presentation,
      panelWidth: widget.panelWidth,
      panelLayout: widget.customPanel
          ? KMapDayPanelLayout.docked
          : KMapDayPanelLayout.floating,
      panelHeaderBuilder: widget.customPanel
          ? (context, panel) => panel.isSheet
                ? KButton(
                    label: panel.expanded ? 'Karte zeigen' : 'Ganzer Tag',
                    onPressed: panel.toggleExpanded,
                  )
                : null
          : null,
      panelBodyBuilder: widget.customPanel
          ? (context, panel) => KList(
              title: 'Tagesablauf',
              children: [
                for (final item in items)
                  KListItem(
                    title: item.title,
                    description: item.detail,
                    selected: panel.selectedItemId == item.id,
                    disclosure: false,
                    onPressed: () => panel.onItemTap(item.id),
                  ),
              ],
            )
          : null,
      showCurrentTime: widget.showCurrentTime,
      showForecasts: widget.showForecasts,
      summary: const Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          Text('2 Kunden'),
          Text('1 privater Termin'),
          Text('09:00 – 12:35'),
        ],
      ),
      description: const Text(
        'Planposition, kein Live-Standort. Die Prognose verändert keine bestätigten Zeiten.',
      ),
      footer: Row(
        children: [
          const KIcon(KIconName.house),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tagesende 12:40 · $_event · '
              '${(_sheetController.fraction * 100).round()} %',
            ),
          ),
        ],
      ),
      onSelectionChanged: (id) => setState(() {
        _selected = id;
        _event = 'Ausgewählt: $id';
      }),
      onItemTap: _focusItem,
      onMapItemTap: _focusItem,
      onPanelStateChanged: (state) =>
          setState(() => _event = 'Sheet: ${state.name}'),
      onAction: (event) => setState(
        () => _event = 'Aktion: ${event.actionId} · ${event.itemId}',
      ),
      mapBuilder: (context, mapContext) {
        final selected = _dayStops
            .where((entry) => entry.item.id == mapContext.selectedItemId)
            .firstOrNull;
        return KMap(
          mapStyle: style,
          center:
              selected?.center ??
              const KMapCenter(longitude: 13.399, latitude: 52.535),
          zoom: 13.5,
          label: 'Karte deines Tages',
          controlsPadding: EdgeInsetsDirectional.only(
            top: 108,
            end: sidebar ? widget.panelWidth + 40 : 16,
            bottom: 16,
            start: 16,
          ),
        );
      },
    );
    return ColoredBox(
      color: tokens.colorSurfaceCanvas,
      child: Center(
        child: SizedBox(
          width: widget.frameWidth,
          height: widget.frameWidth == 390 ? 780 : 720,
          child: fixture,
        ),
      ),
    );
  }
}

class _DayStop {
  const _DayStop(this.item, this.center);

  final KMapDayItem item;
  final KMapCenter center;
}

const _dayStops = <_DayStop>[
  _DayStop(
    KMapDayItem(
      id: 'start',
      start: 540,
      end: 545,
      title: 'Start · Zuhause',
      detail: 'Invalidenstraße 44, Berlin',
      icon: KIconName.house,
      kind: KMapDayItemKind.stop,
    ),
    KMapCenter(longitude: 13.377, latitude: 52.529),
  ),
  _DayStop(
    KMapDayItem(
      id: 'walk-car',
      start: 545,
      end: 550,
      title: 'Zu deinem Auto',
      detail: '5 Min. zu Fuß · 350 m · Parkplatz am Museum',
      icon: KIconName.footprints,
      kind: KMapDayItemKind.travel,
    ),
    KMapCenter(longitude: 13.377, latitude: 52.529),
  ),
  _DayStop(
    KMapDayItem(
      id: 'drive-1',
      start: 550,
      end: 570,
      title: 'Mit dem Auto',
      detail: '20 Min. · 6,4 km · zum Parkplatz am Ziel',
      routeDescription:
          'Von: Parkplatz am Museum\nInvalidenstraße 44, 10115 Berlin\n\n'
          'Nach: Parkplatz am Ziel\nKollwitzplatz, 10405 Berlin',
      icon: KIconName.car,
      kind: KMapDayItemKind.travel,
    ),
    KMapCenter(longitude: 13.399, latitude: 52.535),
  ),
  _DayStop(
    KMapDayItem(
      id: 'park-1',
      start: 570,
      end: 575,
      title: 'Parken & ankommen',
      detail: '5 Min. Parkpuffer · Parkplatz Kollwitzplatz',
      icon: KIconName.mapPin,
      kind: KMapDayItemKind.travel,
    ),
    KMapCenter(longitude: 13.418, latitude: 52.536),
  ),
  _DayStop(
    KMapDayItem(
      id: 'walk-1',
      start: 575,
      end: 580,
      title: 'Zum Hauseingang',
      detail: '5 Min. zu Fuß · 280 m',
      icon: KIconName.footprints,
      kind: KMapDayItemKind.travel,
    ),
    KMapCenter(longitude: 13.418, latitude: 52.536),
  ),
  _DayStop(
    KMapDayItem(
      id: 'anna',
      start: 580,
      end: 625,
      expectedStart: 585,
      title: 'Anna Becker',
      detail: 'Kollwitzstraße 30 · Haarschnitt & Pflege · 45 Min.',
      icon: KIconName.mapPin,
      kind: KMapDayItemKind.stop,
      actions: [
        KMapDayAction(
          id: 'details',
          label: 'Details',
          icon: KIconName.arrowRight,
        ),
      ],
    ),
    KMapCenter(longitude: 13.418, latitude: 52.536),
  ),
  _DayStop(
    KMapDayItem(
      id: 'return-car',
      start: 625,
      end: 630,
      title: 'Zurück zum Auto',
      detail: '5 Min. zu Fuß · zum abgestellten Fahrzeug',
      icon: KIconName.footprints,
      kind: KMapDayItemKind.travel,
    ),
    KMapCenter(longitude: 13.418, latitude: 52.536),
  ),
  _DayStop(
    KMapDayItem(
      id: 'drive-2',
      start: 630,
      end: 655,
      title: 'Fahrt & Zugang',
      detail: '15 Min. Auto · 5 Min. Parken · 5 Min. Fußweg',
      icon: KIconName.car,
      kind: KMapDayItemKind.travel,
    ),
    KMapCenter(longitude: 13.405, latitude: 52.520),
  ),
  _DayStop(
    KMapDayItem(
      id: 'leo',
      start: 655,
      end: 685,
      expectedStart: 660,
      title: 'Leo Wagner',
      detail: 'Rochstraße 8 · Haarschnitt · 30 Min.',
      icon: KIconName.mapPin,
      kind: KMapDayItemKind.stop,
      actions: [
        KMapDayAction(
          id: 'details',
          label: 'Details',
          icon: KIconName.arrowRight,
        ),
      ],
    ),
    KMapCenter(longitude: 13.405, latitude: 52.520),
  ),
  _DayStop(
    KMapDayItem(
      id: 'walk-private',
      start: 685,
      end: 695,
      title: 'Zu Fuß zum privaten Termin',
      detail: '10 Min. · 650 m · Auto bleibt am Parkplatz',
      icon: KIconName.footprints,
      kind: KMapDayItemKind.travel,
    ),
    KMapCenter(longitude: 13.397, latitude: 52.519),
  ),
  _DayStop(
    KMapDayItem(
      id: 'private',
      start: 695,
      end: 725,
      expectedStart: 700,
      title: 'Privater Termin',
      detail: 'Friedrichstraße 96 · fester Zeitblock · 30 Min.',
      icon: KIconName.calendarDays,
      kind: KMapDayItemKind.stop,
    ),
    KMapCenter(longitude: 13.389, latitude: 52.520),
  ),
  _DayStop(
    KMapDayItem(
      id: 'home-leg',
      start: 725,
      end: 755,
      title: 'Zurück nach Hause',
      detail: '10 Min. zum Auto · 15 Min. Fahrt · 5 Min. Zugang',
      icon: KIconName.car,
      kind: KMapDayItemKind.travel,
    ),
    KMapCenter(longitude: 13.377, latitude: 52.529),
  ),
  _DayStop(
    KMapDayItem(
      id: 'end',
      start: 755,
      end: 755,
      title: 'Tagesende · Zuhause',
      detail: 'Invalidenstraße 44, Berlin',
      icon: KIconName.house,
      kind: KMapDayItemKind.stop,
    ),
    KMapCenter(longitude: 13.377, latitude: 52.529),
  ),
];

List<KMapDayItem> _entriesFor(int now, int delay) => [
  for (final entry in _dayStops)
    if (entry.item.start > now && entry.item.kind == KMapDayItemKind.stop)
      KMapDayItem(
        id: entry.item.id,
        start: entry.item.start,
        end: entry.item.end,
        expectedStart: entry.item.start + delay,
        title: entry.item.title,
        detail: entry.item.detail,
        icon: entry.item.icon,
        kind: entry.item.kind,
        actions: entry.item.actions,
      )
    else
      entry.item,
];
