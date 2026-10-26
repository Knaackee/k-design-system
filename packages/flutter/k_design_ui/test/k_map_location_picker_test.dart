import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart' show KButton, KIcon, KIconName;
import 'package:k_design_ui/k_map.dart';
import 'package:k_design_ui/k_map_location_picker.dart';

const _selected = KMapLocation(
  id: 'berlin-1',
  label: 'Invalidenstraße 44',
  detail: '10115 Berlin · Deutschland',
  position: KMapCenter(longitude: 13.387, latitude: 52.53),
);

Widget _host({
  KMapLocation? defaultValue = _selected,
  KMapLocationSearch? onSearch,
  KMapReverseGeocoder? onReverseGeocode,
  ValueChanged<KMapLocation>? onChanged,
  ValueChanged<KMapLocation>? onConfirm,
  Widget? leading,
  Widget? marker,
  KMapLocationPickerMarkerAppearance markerAppearance =
      KMapLocationPickerMarkerAppearance.defaultStyle,
  double selectedZoom = 16,
  bool reducedMotion = true,
  Duration? transitionDuration,
}) => MaterialApp(
  theme: ThemeData(extensions: const [KDesignTokens.orbitLight]),
  home: Scaffold(
    body: SizedBox(
      width: 800,
      height: 700,
      child: KMapLocationPicker(
        mapStyle: 'not-json',
        center: const KMapCenter(longitude: 13.39, latitude: 52.525),
        defaultValue: defaultValue,
        reducedMotion: reducedMotion,
        transitionDuration: transitionDuration,
        onSearch: onSearch ?? (_) async => const [],
        onReverseGeocode: onReverseGeocode,
        onChanged: onChanged,
        onConfirm: onConfirm,
        leading: leading,
        marker: marker,
        markerAppearance: markerAppearance,
        selectedZoom: selectedZoom,
      ),
    ),
  ),
);

void main() {
  testWidgets('custom leading replaces the default choice icon', (
    tester,
  ) async {
    await tester.pumpWidget(_host(defaultValue: null));

    final choice = find.byKey(const ValueKey('k-map-location-choice'));
    expect(
      tester
          .widgetList<KIcon>(
            find.descendant(of: choice, matching: find.byType(KIcon)),
          )
          .map((icon) => icon.name),
      contains(KIconName.mapPin),
    );

    await tester.pumpWidget(
      _host(
        defaultValue: null,
        leading: const SizedBox(key: ValueKey('custom-leading')),
      ),
    );

    expect(find.byKey(const ValueKey('custom-leading')), findsOneWidget);
    expect(
      tester
          .widgetList<KIcon>(
            find.descendant(of: choice, matching: find.byType(KIcon)),
          )
          .map((icon) => icon.name),
      isNot(contains(KIconName.mapPin)),
    );
  });

  testWidgets('pill opens search directly with selected previous label', (
    tester,
  ) async {
    await tester.pumpWidget(_host());

    await tester.tap(find.byKey(const ValueKey('k-map-location-pill')));
    await tester.pump();

    expect(find.byKey(const ValueKey('k-map-location-search')), findsOneWidget);
    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('k-map-location-search-input')),
        matching: find.byType(TextField),
      ),
    );
    expect(field.controller!.text, _selected.label);
    expect(field.focusNode!.hasFocus, isTrue);
    expect(
      field.controller!.selection,
      TextSelection(baseOffset: 0, extentOffset: _selected.label.length),
    );
  });

  testWidgets('custom marker keeps decoration by default and can render bare', (
    tester,
  ) async {
    const customMarker = SizedBox(
      key: ValueKey('custom-marker'),
      width: 30,
      height: 48,
    );

    await tester.pumpWidget(_host(marker: customMarker));
    var map = tester.widget<KMap>(find.byType(KMap));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [KDesignTokens.orbitLight]),
        home: map.pins.single.child,
      ),
    );

    expect(find.byKey(const ValueKey('custom-marker')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('k-map-location-marker-decoration')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      _host(
        marker: customMarker,
        markerAppearance: KMapLocationPickerMarkerAppearance.bare,
      ),
    );
    map = tester.widget<KMap>(find.byType(KMap));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [KDesignTokens.orbitLight]),
        home: map.pins.single.child,
      ),
    );

    expect(find.byKey(const ValueKey('custom-marker')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('k-map-location-marker-decoration')),
      findsNothing,
    );
  });

  testWidgets('pin refinement preserves the chosen camera target and zoom', (
    tester,
  ) async {
    await tester.pumpWidget(_host(selectedZoom: 17));

    var map = tester.widget<KMap>(find.byType(KMap));
    const adjusted = KMapCenter(longitude: 13.4, latitude: 52.52);
    await Future<bool?>.value(
      map.onPinMove!(
        const KMapPinMove(
          id: 'location',
          position: adjusted,
          source: KMapPinMoveSource.drag,
        ),
      ),
    );
    await tester.pump();

    map = tester.widget<KMap>(find.byType(KMap));
    expect(map.center, _selected.position);
    expect(map.zoom, 17);
    expect(map.pins.single.position, adjusted);
  });

  testWidgets('a newly chosen address flies to the selected zoom', (
    tester,
  ) async {
    const next = KMapLocation(
      id: 'berlin-3',
      label: 'Torstraße 120',
      position: KMapCenter(longitude: 13.399, latitude: 52.529),
    );
    await tester.pumpWidget(
      _host(
        defaultValue: null,
        selectedZoom: 17,
        onSearch: (_) async => const [next],
      ),
    );

    await tester.tap(find.text('Adresse suchen'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Tor');
    await tester.pump(const Duration(milliseconds: 251));
    await tester.pump();
    await tester.tap(find.text(next.label));
    await tester.pump();

    final map = tester.widget<KMap>(find.byType(KMap));
    expect(map.center, next.position);
    expect(map.zoom, 17);
  });

  testWidgets('closing the picker delivers zero blur to the map', (
    tester,
  ) async {
    const next = KMapLocation(
      id: 'berlin-3',
      label: 'Torstraße 120',
      position: KMapCenter(longitude: 13.399, latitude: 52.529),
    );
    await tester.pumpWidget(
      _host(
        defaultValue: null,
        reducedMotion: false,
        transitionDuration: const Duration(milliseconds: 100),
        onSearch: (_) async => const [next],
      ),
    );

    expect(tester.widget<KMap>(find.byType(KMap)).blurSigma, 8);
    await tester.tap(find.text('Adresse suchen'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Tor');
    await tester.pump(const Duration(milliseconds: 251));
    await tester.pump();
    await tester.tap(find.text(next.label));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 101));

    expect(tester.widget<KMap>(find.byType(KMap)).blurSigma, 0);
  });

  testWidgets('late reverse lookup cannot overwrite a newer pin move', (
    tester,
  ) async {
    final first = Completer<KMapLocation>();
    final second = Completer<KMapLocation>();
    final changes = <KMapLocation>[];
    var calls = 0;
    await tester.pumpWidget(
      _host(
        onChanged: changes.add,
        onReverseGeocode: (_) => calls++ == 0 ? first.future : second.future,
      ),
    );

    final map = tester.widget<KMap>(find.byType(KMap));
    const firstPosition = KMapCenter(longitude: 13.4, latitude: 52.52);
    const secondPosition = KMapCenter(longitude: 13.41, latitude: 52.51);
    await Future<bool?>.value(
      map.onPinMove!(
        const KMapPinMove(
          id: 'location',
          position: firstPosition,
          source: KMapPinMoveSource.drag,
        ),
      ),
    );
    await Future<bool?>.value(
      map.onPinMove!(
        const KMapPinMove(
          id: 'location',
          position: secondPosition,
          source: KMapPinMoveSource.drag,
        ),
      ),
    );

    second.complete(
      const KMapLocation(
        id: 'second',
        label: 'Zweite Position',
        position: secondPosition,
      ),
    );
    await tester.pump();
    first.complete(
      const KMapLocation(
        id: 'first',
        label: 'Veraltete Position',
        position: firstPosition,
      ),
    );
    await tester.pump();

    expect(changes.last.label, 'Zweite Position');
    expect(changes.last.position, secondPosition);
    expect(changes.where((value) => value.id == 'first'), isEmpty);
  });

  testWidgets(
    'reverse lookup exposes progress and blocks failed confirmation',
    (tester) async {
      final reverse = Completer<KMapLocation>();
      await tester.pumpWidget(
        _host(onReverseGeocode: (_) => reverse.future, onConfirm: (_) {}),
      );

      final map = tester.widget<KMap>(find.byType(KMap));
      await Future<bool?>.value(
        map.onPinMove!(
          const KMapPinMove(
            id: 'location',
            position: KMapCenter(longitude: 13.4, latitude: 52.52),
            source: KMapPinMoveSource.drag,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Adressen werden gesucht …'), findsOneWidget);
      final spinner = find.byType(CircularProgressIndicator);
      expect(spinner, findsOneWidget);
      final spinnerSize = tester.getSize(spinner);
      expect(spinnerSize.width, spinnerSize.height);
      expect(spinnerSize.width, lessThanOrEqualTo(24));
      expect(
        tester
            .widget<KButton>(
              find.widgetWithText(KButton, 'Position übernehmen'),
            )
            .onPressed,
        isNull,
      );

      reverse.completeError(StateError('fixture reverse lookup failed'));
      await tester.pump();

      expect(find.textContaining('Das hat nicht geklappt.'), findsOneWidget);
      expect(
        tester
            .widget<KButton>(
              find.widgetWithText(KButton, 'Position übernehmen'),
            )
            .onPressed,
        isNull,
      );
    },
  );
}
