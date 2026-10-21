import 'package:flutter/foundation.dart';
import 'k_map_controller.dart';
import '../pickers/picker_types.dart';

@immutable
class KMapPolygon {
  const KMapPolygon({required this.outer, this.holes = const []});
  final List<KMapCenter> outer;
  final List<List<KMapCenter>> holes;
}

@immutable
class KMapZoneCircle {
  const KMapZoneCircle({required this.center, required this.radiusKm});
  final KMapCenter center;
  final double radiusKm;
}

@immutable
class KMapPostalArea {
  const KMapPostalArea({
    required this.id,
    required this.country,
    required this.code,
    required this.label,
    required this.coordinates,
    required this.sourceLabel,
    this.sourceVersion,
    this.assignedZoneId,
    this.polygons,
  });
  final String id, country, code, label, sourceLabel;
  final String? sourceVersion, assignedZoneId;
  final List<KMapCenter> coordinates;
  final List<KMapPolygon>? polygons;
  List<KMapPolygon> get geometry =>
      polygons ?? [KMapPolygon(outer: coordinates)];
}

@immutable
class KMapZoneTravelCost {
  const KMapZoneTravelCost({
    this.kind = 'free',
    this.amount = 0,
    this.currency = 'EUR',
  });
  final String kind, currency;
  final double amount;
}

@immutable
class KMapZoneAvailability {
  const KMapZoneAvailability.recurring({
    required this.rrule,
    required this.startDate,
    required this.timeZone,
  }) : kind = 'recurring',
       from = '',
       to = '';
  const KMapZoneAvailability.dateRange({required this.from, required this.to})
    : kind = 'date-range',
      rrule = '',
      startDate = '',
      timeZone = '';
  final String kind, rrule, startDate, timeZone, from, to;
}

@immutable
class KMapZoneTimeInterval {
  const KMapZoneTimeInterval({required this.start, required this.end});
  final String start, end;
}

@immutable
class KMapZoneWorkingDay {
  const KMapZoneWorkingDay({required this.day, required this.intervals});
  final int day;
  final List<KMapZoneTimeInterval> intervals;
}

@immutable
class KMapZoneSettings {
  const KMapZoneSettings({
    this.workingHours,
    this.travelCost,
    this.surcharge,
    this.surchargeCurrency = 'EUR',
    this.availability,
    this.requestRequired = false,
  });
  final List<KMapZoneWorkingDay>? workingHours;
  final KMapZoneTravelCost? travelCost;
  final double? surcharge;
  final String surchargeCurrency;
  final KMapZoneAvailability? availability;
  final bool requestRequired;
  KMapZoneSettings copyWith({
    List<KMapZoneWorkingDay>? workingHours,
    KMapZoneTravelCost? travelCost,
    double? surcharge,
    String? surchargeCurrency,
    KMapZoneAvailability? availability,
    bool? requestRequired,
  }) => KMapZoneSettings(
    workingHours: workingHours ?? this.workingHours,
    travelCost: travelCost ?? this.travelCost,
    surcharge: surcharge ?? this.surcharge,
    surchargeCurrency: surchargeCurrency ?? this.surchargeCurrency,
    availability: availability ?? this.availability,
    requestRequired: requestRequired ?? this.requestRequired,
  );
}

@immutable
class KMapZonePropertyOption {
  const KMapZonePropertyOption({
    required this.value,
    required this.label,
    this.shortLabel,
    this.disabled = false,
  });
  final String value, label;
  final String? shortLabel;
  final bool disabled;
}

@immutable
class KMapZonePropertyOptions {
  const KMapZonePropertyOptions({
    required this.weekdayOptions,
    required this.currency,
    required this.timeZone,
    this.locale,
    this.formatDate,
    this.dateFormat,
    this.defaultWorkingHours,
    this.workingHoursLabels = const {},
  });
  final Map<String, String> workingHoursLabels;
  final List<KMapZoneWorkingDay>? defaultWorkingHours;
  final List<KMapZonePropertyOption> weekdayOptions;
  final String currency, timeZone;
  final String? locale;
  final KDateFormat? dateFormat;
  final String Function(String isoDate)? formatDate;
}

// Canonical values are the same Tailwind 600 families as the React editor.
const kMapZonePalette = <({String name, String light, String dark})>[
  (name: 'Rot', light: '#e7000b', dark: '#ff6467'),
  (name: 'Orange', light: '#f54900', dark: '#ff8904'),
  (name: 'Bernstein', light: '#e17100', dark: '#ffb900'),
  (name: 'Gelb', light: '#d08700', dark: '#fdc700'),
  (name: 'Limette', light: '#5ea500', dark: '#9ae600'),
  (name: 'Grün', light: '#00a63e', dark: '#05df72'),
  (name: 'Smaragd', light: '#009966', dark: '#00d492'),
  (name: 'Türkis', light: '#009689', dark: '#00d5be'),
  (name: 'Cyan', light: '#0092b8', dark: '#00d3f2'),
  (name: 'Himmelblau', light: '#0084d1', dark: '#00bcff'),
  (name: 'Blau', light: '#155dfc', dark: '#51a2ff'),
  (name: 'Indigo', light: '#4f39f6', dark: '#7c86ff'),
  (name: 'Violett', light: '#7f22fe', dark: '#a684ff'),
  (name: 'Lila', light: '#9810fa', dark: '#c27aff'),
  (name: 'Fuchsia', light: '#c800de', dark: '#ed6aff'),
  (name: 'Pink', light: '#e60076', dark: '#fb64b6'),
  (name: 'Rosé', light: '#ec003f', dark: '#ff637e'),
  (name: 'Schiefer', light: '#45556c', dark: '#90a1b9'),
  (name: 'Grau', light: '#4a5565', dark: '#99a1af'),
  (name: 'Zink', light: '#52525c', dark: '#9f9fa9'),
  (name: 'Neutral', light: '#525252', dark: '#a1a1a1'),
  (name: 'Stein', light: '#57534d', dark: '#a6a09b'),
];

String resolveKMapZoneColor(String value, bool dark) {
  for (final entry in kMapZonePalette) {
    if (entry.light == value.toLowerCase()) {
      return dark ? entry.dark : entry.light;
    }
  }
  return value;
}
