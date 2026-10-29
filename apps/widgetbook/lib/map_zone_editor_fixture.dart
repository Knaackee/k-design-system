import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/k_map_style.dart';
import 'package:k_design_ui/k_map_zone_editor.dart';

const mapZoneEditorFixtureId = 'map-zone-editor';

const mapZoneEditorZones = <KMapZone>[
  KMapZone(
    id: 'zone-berlin-west',
    name: 'Westliche Termine',
    color: '#155dfc',
    coordinates: [
      KMapCenter(longitude: 13.318, latitude: 52.49),
      KMapCenter(longitude: 13.332, latitude: 52.49),
      KMapCenter(longitude: 13.332, latitude: 52.5),
      KMapCenter(longitude: 13.318, latitude: 52.5),
    ],
    settings: KMapZoneSettings(
      travelCost: KMapZoneTravelCost(
        kind: 'per-kilometer',
        amount: 0.7,
        currency: 'EUR',
      ),
      surcharge: 5,
      surchargeCurrency: 'EUR',
    ),
  ),
  KMapZone(
    id: 'zone-berlin-center',
    name: 'Mitte',
    color: '#00a63e',
    coordinates: [
      KMapCenter(longitude: 13.382, latitude: 52.515),
      KMapCenter(longitude: 13.397, latitude: 52.515),
      KMapCenter(longitude: 13.397, latitude: 52.526),
      KMapCenter(longitude: 13.382, latitude: 52.526),
    ],
    settings: KMapZoneSettings(
      travelCost: KMapZoneTravelCost(
        kind: 'flat-rate',
        amount: 12,
        currency: 'EUR',
      ),
      availability: KMapZoneAvailability.recurring(
        rrule: 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR;BYMONTH=10,11,12',
        startDate: '2026-10-19',
        timeZone: 'Europe/Berlin',
      ),
    ),
  ),
  KMapZone(
    id: 'zone-berlin-east',
    name: 'Östliche Termine',
    color: '#e7000b',
    coordinates: [
      KMapCenter(longitude: 13.43, latitude: 52.525),
      KMapCenter(longitude: 13.446, latitude: 52.525),
      KMapCenter(longitude: 13.446, latitude: 52.536),
      KMapCenter(longitude: 13.43, latitude: 52.536),
    ],
    settings: KMapZoneSettings(
      travelCost: KMapZoneTravelCost(
        kind: 'per-kilometer',
        amount: 0,
        currency: 'EUR',
      ),
    ),
  ),
];
const mapZoneEditorPostalAreas = <KMapPostalArea>[
  KMapPostalArea(
    id: '10115',
    country: 'DE',
    code: '10115',
    label: 'Berlin-Mitte',
    sourceLabel: 'Storybook-Beispieldaten · keine amtlichen Grenzen',
    sourceVersion: 'Fixture 2026-10',
    coordinates: [
      KMapCenter(longitude: 13.382, latitude: 52.526),
      KMapCenter(longitude: 13.397, latitude: 52.526),
      KMapCenter(longitude: 13.397, latitude: 52.538),
      KMapCenter(longitude: 13.382, latitude: 52.538),
    ],
  ),
  KMapPostalArea(
    id: '10117',
    country: 'DE',
    code: '10117',
    label: 'Berlin-Mitte',
    sourceLabel: 'Storybook-Beispieldaten · keine amtlichen Grenzen',
    sourceVersion: 'Fixture 2026-10',
    coordinates: [
      KMapCenter(longitude: 13.397, latitude: 52.515),
      KMapCenter(longitude: 13.412, latitude: 52.515),
      KMapCenter(longitude: 13.412, latitude: 52.526),
      KMapCenter(longitude: 13.397, latitude: 52.526),
    ],
  ),
  KMapPostalArea(
    id: '10119',
    country: 'DE',
    code: '10119',
    label: 'Prenzlauer Berg',
    sourceLabel: 'Storybook-Beispieldaten · keine amtlichen Grenzen',
    sourceVersion: 'Fixture 2026-10',
    coordinates: [
      KMapCenter(longitude: 13.397, latitude: 52.526),
      KMapCenter(longitude: 13.412, latitude: 52.526),
      KMapCenter(longitude: 13.412, latitude: 52.538),
      KMapCenter(longitude: 13.397, latitude: 52.538),
    ],
  ),
];
const mapZoneEditorPropertyOptions = KMapZonePropertyOptions(
  currency: 'EUR',
  timeZone: 'Europe/Berlin',
  defaultWorkingHours: [
    KMapZoneWorkingDay(
      day: 1,
      intervals: [KMapZoneTimeInterval(start: '09:00', end: '17:00')],
    ),
    KMapZoneWorkingDay(
      day: 2,
      intervals: [KMapZoneTimeInterval(start: '09:00', end: '17:00')],
    ),
    KMapZoneWorkingDay(
      day: 3,
      intervals: [KMapZoneTimeInterval(start: '09:00', end: '17:00')],
    ),
    KMapZoneWorkingDay(
      day: 4,
      intervals: [KMapZoneTimeInterval(start: '09:00', end: '17:00')],
    ),
    KMapZoneWorkingDay(
      day: 5,
      intervals: [KMapZoneTimeInterval(start: '09:00', end: '17:00')],
    ),
    KMapZoneWorkingDay(day: 6, intervals: []),
    KMapZoneWorkingDay(day: 7, intervals: []),
  ],
  weekdayOptions: [
    KMapZonePropertyOption(value: 'MO', label: 'Montag', shortLabel: 'Mo'),
    KMapZonePropertyOption(value: 'TU', label: 'Dienstag', shortLabel: 'Di'),
    KMapZonePropertyOption(value: 'WE', label: 'Mittwoch', shortLabel: 'Mi'),
    KMapZonePropertyOption(value: 'TH', label: 'Donnerstag', shortLabel: 'Do'),
    KMapZonePropertyOption(value: 'FR', label: 'Freitag', shortLabel: 'Fr'),
    KMapZonePropertyOption(value: 'SA', label: 'Samstag', shortLabel: 'Sa'),
    KMapZonePropertyOption(value: 'SU', label: 'Sonntag', shortLabel: 'So'),
  ],
);

String _zonesFingerprint(List<KMapZone> zones) => jsonEncode([
  for (final zone in zones)
    {
      'id': zone.id,
      'name': zone.name,
      'color': zone.color,
      'kind': zone.kind,
      'coordinates': [
        for (final point in zone.coordinates) [point.longitude, point.latitude],
      ],
      'polygons': zone.polygons == null
          ? null
          : [
              for (final polygon in zone.polygons!)
                {
                  'outer': [
                    for (final point in polygon.outer)
                      [point.longitude, point.latitude],
                  ],
                  'holes': [
                    for (final hole in polygon.holes)
                      [
                        for (final point in hole)
                          [point.longitude, point.latitude],
                      ],
                  ],
                },
            ],
      'circle': zone.circle == null
          ? null
          : {
              'center': [
                zone.circle!.center.longitude,
                zone.circle!.center.latitude,
              ],
              'radiusKm': zone.circle!.radiusKm,
            },
      'source': zone.source?.id,
      'settings': zone.settings == null
          ? null
          : {
              'workingHours': zone.settings!.workingHours == null
                  ? null
                  : [
                      for (final day in zone.settings!.workingHours!)
                        {
                          'day': day.day,
                          'intervals': [
                            for (final interval in day.intervals)
                              [interval.start, interval.end],
                          ],
                        },
                    ],
              'travelCost': zone.settings!.travelCost == null
                  ? null
                  : {
                      'kind': zone.settings!.travelCost!.kind,
                      'amount': zone.settings!.travelCost!.amount,
                      'currency': zone.settings!.travelCost!.currency,
                    },
              'surcharge': zone.settings!.surcharge,
              'surchargeCurrency': zone.settings!.surchargeCurrency,
              'requestRequired': zone.settings!.requestRequired,
              'availability': zone.settings!.availability == null
                  ? null
                  : {
                      'kind': zone.settings!.availability!.kind,
                      'rrule': zone.settings!.availability!.rrule,
                      'startDate': zone.settings!.availability!.startDate,
                      'timeZone': zone.settings!.availability!.timeZone,
                      'from': zone.settings!.availability!.from,
                      'to': zone.settings!.availability!.to,
                    },
            },
    },
]);

Widget buildMapZoneEditorDesktop(BuildContext context) =>
    const MapZoneEditorFixture();

Widget buildMapZoneEditorMobile(BuildContext context) =>
    const Center(child: SizedBox(width: 390, child: MapZoneEditorFixture()));

Widget buildMapZoneEditorFullscreenDesktop(BuildContext context) =>
    const MapZoneEditorFixture(fullscreen: true);

Widget buildMapZoneEditorFullscreenMobile(BuildContext context) => const Center(
  child: SizedBox(
    width: 390,
    height: 844,
    child: MapZoneEditorFixture(fullscreen: true),
  ),
);

Widget buildMapZoneEditorFullscreenEmpty(BuildContext context) => const Center(
  child: SizedBox(
    width: 390,
    height: 844,
    child: MapZoneEditorFixture(fullscreen: true, empty: true),
  ),
);

class MapZoneEditorFixture extends StatefulWidget {
  const MapZoneEditorFixture({
    this.fullscreen = false,
    this.empty = false,
    this.showScheduling = true,
    this.mapStyleOverride,
    super.key,
  });

  final bool fullscreen, empty, showScheduling;
  final String? mapStyleOverride;

  @override
  State<MapZoneEditorFixture> createState() => _MapZoneEditorFixtureState();
}

class _MapZoneEditorFixtureState extends State<MapZoneEditorFixture> {
  late List<KMapZone> zones;
  late List<KMapZone> savedZones;
  late String savedFingerprint;
  String? selectedZoneId;
  bool editorPending = false;
  String? notice;

  @override
  void initState() {
    super.initState();
    zones = widget.empty ? const [] : mapZoneEditorZones;
    savedZones = zones;
    savedFingerprint = _zonesFingerprint(zones);
    selectedZoneId = widget.fullscreen || zones.isEmpty ? null : zones.first.id;
  }

  Widget _editor(KDesignTokens tokens) => KMapZoneEditor(
    mapStyle:
        widget.mapStyleOverride ?? jsonEncode(createKMapStyle(tokens: tokens)),
    center: const KMapCenter(longitude: 13.397, latitude: 52.5205),
    zoom: 13.6,
    showZoomControls: !widget.fullscreen,
    defaultRadiusKm: 2.5,
    postalAreas: mapZoneEditorPostalAreas,
    propertyOptions: KMapZonePropertyOptions(
      weekdayOptions: mapZoneEditorPropertyOptions.weekdayOptions,
      currency: mapZoneEditorPropertyOptions.currency,
      timeZone: mapZoneEditorPropertyOptions.timeZone,
      defaultWorkingHours: mapZoneEditorPropertyOptions.defaultWorkingHours,
      showScheduling: widget.showScheduling,
    ),
    defaultZoneSettings: const KMapZoneSettings(
      travelCost: KMapZoneTravelCost(kind: 'per-kilometer', amount: .7),
    ),
    zones: zones,
    selectedZoneId: selectedZoneId,
    onSelect: (id) => setState(() => selectedZoneId = id),
    onChange: (value) => setState(() => zones = value),
    onPendingChangesChanged: (value) {
      if (mounted && value != editorPending) {
        setState(() => editorPending = value);
      }
    },
    onExitRequested: widget.fullscreen ? _requestExit : null,
    onValidationError: (_) {},
  );

  void _save() => setState(() {
    savedZones = zones;
    savedFingerprint = _zonesFingerprint(zones);
    notice = 'Gebiete gespeichert';
  });

  void _exitNotice() => setState(() {
    notice = 'Zurück zur Verwaltung · Navigation im Widgetbook-Beispiel';
  });

  Future<void> _requestExit() async {
    if (_zonesFingerprint(zones) == savedFingerprint) {
      _exitNotice();
      return;
    }
    final choice = await KAdaptiveDialog.show<String>(
      context: context,
      builder: (dialogContext) => KAdaptiveDialog(
        title: const Text('Änderungen speichern?'),
        onClose: () => Navigator.of(dialogContext).pop(),
        actions: KInline(
          gap: KLayoutGap.action,
          wrap: true,
          children: [
            KButton(
              label: 'Weiter bearbeiten',
              variant: KButtonVariant.ghost,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            KButton(
              label: 'Verwerfen',
              variant: KButtonVariant.secondary,
              onPressed: () => Navigator.of(dialogContext).pop('discard'),
            ),
            KButton(
              label: 'Speichern',
              onPressed: () => Navigator.of(dialogContext).pop('save'),
            ),
          ],
        ),
        child: const Text(
          'Deine Änderungen gelten nach dem Speichern direkt für neue Buchungen.',
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'discard') {
      setState(() {
        zones = savedZones;
        selectedZoneId = null;
      });
    } else {
      _save();
    }
    _exitNotice();
  }

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    if (widget.fullscreen) {
      final changed = _zonesFingerprint(zones) != savedFingerprint;
      return Stack(
        fit: StackFit.expand,
        children: [
          _editor(tokens),
          PositionedDirectional(
            top: MediaQuery.paddingOf(context).top + tokens.spaceCardPadding,
            start: tokens.spaceCardPadding,
            child: KIconButton(
              label: 'Zurück zur Verwaltung',
              icon: KIconName.arrowLeft,
              variant: KButtonVariant.secondary,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          if (changed && !editorPending)
            PositionedDirectional(
              top: MediaQuery.paddingOf(context).top + tokens.spaceCardPadding,
              end: tokens.spaceCardPadding,
              child: KIconButton(
                label: 'Gebiete speichern',
                icon: KIconName.cloudUpload,
                variant: KButtonVariant.secondary,
                onPressed: _save,
              ),
            ),
          if (notice != null)
            PositionedDirectional(
              start: tokens.spaceCardPadding,
              end: tokens.spaceCardPadding,
              bottom: tokens.spaceCardPadding,
              child: Center(
                child: KSnackbar(
                  message: Text(notice!),
                  dismissLabel: 'Hinweis schließen',
                  onDismiss: () => setState(() => notice = null),
                ),
              ),
            ),
        ],
      );
    }

    final viewportHeight = MediaQuery.sizeOf(context).height;
    final fixtureHeight = (viewportHeight * .75).clamp(
      480.0,
      viewportHeight - tokens.spaceLayoutGutter * 2,
    );
    return SizedBox(height: fixtureHeight, child: _editor(tokens));
  }
}

Widget buildMapZoneEditorAreasOnly(BuildContext context) =>
    const MapZoneEditorFixture(showScheduling: false);
