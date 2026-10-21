import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
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

Widget buildMapZoneEditorDesktop(BuildContext context) =>
    const _MapZoneEditorFixture();

Widget buildMapZoneEditorMobile(BuildContext context) =>
    const Center(child: SizedBox(width: 390, child: _MapZoneEditorFixture()));

class _MapZoneEditorFixture extends StatefulWidget {
  const _MapZoneEditorFixture();

  @override
  State<_MapZoneEditorFixture> createState() => _MapZoneEditorFixtureState();
}

class _MapZoneEditorFixtureState extends State<_MapZoneEditorFixture> {
  List<KMapZone> zones = mapZoneEditorZones;
  String? selectedZoneId = mapZoneEditorZones.first.id;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final fixtureHeight = (viewportHeight * .75).clamp(
      480.0,
      viewportHeight - tokens.spaceLayoutGutter * 2,
    );
    return SizedBox(
      height: fixtureHeight,
      child: KMapZoneEditor(
        mapStyle: jsonEncode(createKMapStyle(tokens: tokens)),
        center: const KMapCenter(longitude: 13.397, latitude: 52.5205),
        zoom: 13.6,
        defaultRadiusKm: 2.5,
        postalAreas: mapZoneEditorPostalAreas,
        propertyOptions: mapZoneEditorPropertyOptions,
        defaultZoneSettings: const KMapZoneSettings(
          travelCost: KMapZoneTravelCost(kind: 'per-kilometer', amount: .7),
        ),
        zones: zones,
        selectedZoneId: selectedZoneId,
        onSelect: (id) => setState(() => selectedZoneId = id),
        onChange: (value) => setState(() => zones = value),
        onValidationError: (_) {},
      ),
    );
  }
}
