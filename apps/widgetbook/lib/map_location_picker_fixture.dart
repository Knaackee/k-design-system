import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart' show KIcon, KIconName, KText;
import 'package:k_design_ui/k_map_location_picker.dart';
import 'package:k_design_ui/k_map_style.dart';
import 'package:widgetbook/widgetbook.dart';

const mapLocationPickerFixtureId = 'map-location-picker';

const mapLocationPickerAddresses = <KMapLocation>[
  KMapLocation(
    id: 'berlin-1',
    label: 'Invalidenstraße 44',
    detail: '10115 Berlin · Deutschland',
    position: KMapCenter(longitude: 13.387, latitude: 52.53),
  ),
  KMapLocation(
    id: 'berlin-2',
    label: 'Friedrichstraße 100',
    detail: '10117 Berlin · Deutschland',
    position: KMapCenter(longitude: 13.388, latitude: 52.52),
  ),
  KMapLocation(
    id: 'berlin-3',
    label: 'Torstraße 120',
    detail: '10119 Berlin · Deutschland',
    position: KMapCenter(longitude: 13.399, latitude: 52.529),
  ),
];

Widget buildMapLocationPickerDesktop(BuildContext context) =>
    _buildFixture(context);

Widget buildMapLocationPickerMobile(BuildContext context) =>
    _buildFixture(context, width: 390);

Widget buildMapLocationPickerCustomLeading(BuildContext context) =>
    _buildFixture(context, customLeading: true);

Widget buildMapLocationPickerBarePin(BuildContext context) =>
    _buildFixture(context, customMarker: true);

Widget _buildFixture(
  BuildContext context, {
  double? width,
  bool customLeading = false,
  bool customMarker = false,
}) {
  final transitionMs = context.knobs.int.slider(
    label: 'Übergang (ms)',
    initialValue: 700,
    min: 0,
    max: 1800,
  );
  final blur = context.knobs.double.slider(
    label: 'Kartenunschärfe',
    initialValue: 8,
    min: 0,
    max: 16,
  );
  final bounce = context.knobs.boolean(label: 'Pin-Bounce', initialValue: true);
  final reducedMotion = context.knobs.boolean(
    label: 'Reduced Motion',
    initialValue: false,
  );
  final locationFailure = context.knobs.boolean(
    label: 'Standortfehler simulieren',
    initialValue: false,
  );
  final hint = context.knobs.string(
    label: 'Hinweis',
    initialValue: 'Verschiebe den Pin, um deine Position zu präzisieren.',
  );
  return Center(
    child: SizedBox(
      width: width ?? double.infinity,
      height: 720,
      child: _LocationPickerFixture(
        overlayInsets: EdgeInsets.only(
          top: context.knobs.double.slider(
            label: 'Overlay top inset',
            initialValue: 0,
            min: 0,
            max: 200,
          ),
          bottom: context.knobs.double.slider(
            label: 'Overlay bottom inset',
            initialValue: 0,
            min: 0,
            max: 160,
          ),
        ),
        transitionDuration: Duration(milliseconds: transitionMs),
        blur: blur,
        bounce: bounce,
        reducedMotion: reducedMotion,
        locationFailure: locationFailure,
        hint: hint,
        customLeading: customLeading,
        customMarker: customMarker,
      ),
    ),
  );
}

class _LocationPickerFixture extends StatefulWidget {
  const _LocationPickerFixture({
    required this.overlayInsets,
    required this.transitionDuration,
    required this.blur,
    required this.bounce,
    required this.reducedMotion,
    required this.locationFailure,
    required this.hint,
    required this.customLeading,
    required this.customMarker,
  });

  final EdgeInsets overlayInsets;
  final Duration transitionDuration;
  final double blur;
  final bool bounce;
  final bool reducedMotion;
  final bool locationFailure;
  final String hint;
  final bool customLeading;
  final bool customMarker;

  @override
  State<_LocationPickerFixture> createState() => _LocationPickerFixtureState();
}

class _LocationPickerFixtureState extends State<_LocationPickerFixture> {
  KMapLocation? _selection;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final style = jsonEncode(createKMapStyle(tokens: tokens));
    return KMapLocationPicker(
      mapStyle: style,
      overlayInsets: widget.overlayInsets,
      center: const KMapCenter(longitude: 13.39, latitude: 52.525),
      value: _selection,
      onChanged: (value) => setState(() => _selection = value),
      transitionDuration: widget.transitionDuration,
      blur: widget.blur,
      bounce: widget.bounce,
      reducedMotion: widget.reducedMotion,
      leading: widget.customLeading
          ? Semantics(
              image: true,
              label: 'Beispiel-Logo',
              child: SizedBox.square(
                dimension: 28,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: tokens.colorBrandPrimaryAccent,
                      width: 6,
                    ),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            )
          : null,
      marker: widget.customMarker
          ? const KIcon(KIconName.mapPin, size: 44)
          : null,
      markerAppearance: widget.customMarker
          ? KMapLocationPickerMarkerAppearance.bare
          : KMapLocationPickerMarkerAppearance.defaultStyle,
      hint: KText(widget.hint, align: TextAlign.center),
      onSearch: (query) async {
        final needle = query.toLowerCase();
        return mapLocationPickerAddresses.where(
          (entry) =>
              '${entry.label} ${entry.detail}'.toLowerCase().contains(needle),
        );
      },
      onLocate: () async {
        if (widget.locationFailure) {
          throw StateError('Fixture: Standortzugriff verweigert');
        }
        return mapLocationPickerAddresses.first;
      },
      onReverseGeocode: (position) async {
        double distance(KMapLocation location) {
          final longitude = location.position.longitude - position.longitude;
          final latitude = location.position.latitude - position.latitude;
          return longitude * longitude + latitude * latitude;
        }

        final nearest = mapLocationPickerAddresses.reduce(
          (current, candidate) =>
              distance(current) <= distance(candidate) ? current : candidate,
        );
        return nearest.copyWith(position: position);
      },
    );
  }
}
