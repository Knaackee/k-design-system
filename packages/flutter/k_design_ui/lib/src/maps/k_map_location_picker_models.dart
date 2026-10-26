import 'package:flutter/foundation.dart';

import 'k_map_controller.dart';

/// A consumer-owned location result displayed by [KMapLocationPicker].
@immutable
class KMapLocation {
  const KMapLocation({
    required this.id,
    required this.label,
    required this.position,
    this.detail,
  });

  final String id;
  final String label;
  final String? detail;
  final KMapCenter position;

  KMapLocation copyWith({
    String? id,
    String? label,
    String? detail,
    KMapCenter? position,
  }) => KMapLocation(
    id: id ?? this.id,
    label: label ?? this.label,
    detail: detail ?? this.detail,
    position: position ?? this.position,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KMapLocation &&
          id == other.id &&
          label == other.label &&
          detail == other.detail &&
          position == other.position;

  @override
  int get hashCode => Object.hash(id, label, detail, position);
}

typedef KMapLocationSearch =
    Future<Iterable<KMapLocation>> Function(String query);
typedef KMapCurrentLocation = Future<KMapLocation> Function();
typedef KMapReverseGeocoder =
    Future<KMapLocation> Function(KMapCenter position);

/// Consumer-overridable copy for all user-facing picker strings.
@immutable
class KMapLocationPickerLabels {
  const KMapLocationPickerLabels({
    this.title = 'Wo dürfen wir dich besuchen?',
    this.description =
        'Suche eine Adresse oder verwende deinen aktuellen Standort.',
    this.search = 'Adresse suchen',
    this.locate = 'Aktuellen Standort verwenden',
    this.placeholder = 'Straße, Hausnummer und Ort',
    this.back = 'Zurück',
    this.searching = 'Adressen werden gesucht …',
    this.empty = 'Keine passende Adresse gefunden.',
    this.error =
        'Das hat nicht geklappt. Bitte versuche es erneut oder suche eine Adresse.',
    this.adjusted = 'Position angepasst',
    this.edit = 'Adresse ändern',
    this.hint = 'Verschiebe den Pin, um deine Position zu präzisieren.',
    this.confirm = 'Position übernehmen',
  });

  final String title;
  final String description;
  final String search;
  final String locate;
  final String placeholder;
  final String back;
  final String searching;
  final String empty;
  final String error;
  final String adjusted;
  final String edit;
  final String hint;
  final String confirm;
}
