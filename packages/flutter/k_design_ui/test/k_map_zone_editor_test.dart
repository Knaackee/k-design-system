import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/k_map_zone_editor.dart';
import 'package:k_design_ui/k_map.dart';

const zone = KMapZone(
  id: 'west',
  name: 'West',
  color: '#155dfc',
  coordinates: [
    KMapCenter(longitude: 13.382, latitude: 52.515),
    KMapCenter(longitude: 13.397, latitude: 52.515),
    KMapCenter(longitude: 13.397, latitude: 52.526),
    KMapCenter(longitude: 13.382, latitude: 52.526),
  ],
);
const options = KMapZonePropertyOptions(
  weekdayOptions: [
    KMapZonePropertyOption(value: 'MO', label: 'Montag', shortLabel: 'Mo'),
    KMapZonePropertyOption(value: 'TU', label: 'Dienstag', shortLabel: 'Di'),
  ],
  currency: 'EUR',
  timeZone: 'Europe/Berlin',
);

Future<ValueNotifier<KMapZoneUndoAction?>> mount(
  WidgetTester tester, {
  List<KMapZone> zones = const [zone],
  ValueChanged<List<KMapZone>>? changed,
  ValueChanged<bool>? pendingChanged,
  ValueChanged<String?>? selectedChanged,
  bool open = false,
  bool showZoomControls = true,
  VoidCallback? onExitRequested,
  Size size = const Size(1200, 850),
  List<KMapPostalArea> postalAreas = const [],
}) async {
  final undo = ValueNotifier<KMapZoneUndoAction?>(null);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: kDesignTheme(),
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => KMapZoneEditor(
            mapStyle: 'invalid',
            center: const KMapCenter(longitude: 13.397, latitude: 52.52),
            zones: zones,
            postalAreas: postalAreas,
            selectedZoneId: zones.isEmpty ? null : zones.first.id,
            showZoomControls: showZoomControls,
            onExitRequested: onExitRequested,
            defaultPanelOpen: open,
            propertyOptions: options,
            onPendingChangesChanged: pendingChanged,
            onUndoActionChange: (action) => undo.value = action,
            onChange: (value) {
              setState(() => zones = value);
              changed?.call(value);
            },
            onSelect: (id) => selectedChanged?.call(id),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return undo;
}

void main() {
  testWidgets('host edit request opens existing zone properties', (
    tester,
  ) async {
    final request = ValueNotifier<({String zoneId, int requestId})?>(null);
    addTearDown(request.dispose);
    await tester.binding.setSurfaceSize(const Size(1200, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: request,
            builder: (context, value, child) => KMapZoneEditor(
              mapStyle: 'invalid',
              center: const KMapCenter(longitude: 13.397, latitude: 52.52),
              zones: const [zone],
              editRequest: value,
              propertyOptions: options,
              onChange: (_) {},
              onSelect: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    request.value = (zoneId: zone.id, requestId: 1);
    await tester.pumpAndSettle();
    expect(find.text('Einsatzzeiten'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'postal code used as label is not duplicated in a new zone name',
    (tester) async {
      const area = KMapPostalArea(
        id: 'area-92449',
        country: 'DE',
        code: '92449',
        label: '92449',
        coordinates: [
          KMapCenter(longitude: 12.1, latitude: 49.2),
          KMapCenter(longitude: 12.2, latitude: 49.2),
          KMapCenter(longitude: 12.2, latitude: 49.3),
        ],
        sourceLabel: 'Synthetic',
        sourceVersion: 'v1',
      );
      final changes = <List<KMapZone>>[];
      await mount(
        tester,
        zones: const [],
        open: true,
        postalAreas: const [area],
        changed: changes.add,
      );
      await tester.tap(find.text('Postleitzahlen'));
      await tester.pumpAndSettle();
      expect(tester.widget<KMap>(find.byType(KMap)).zones.single.name, '92449');
      tester.widget<KMap>(find.byType(KMap)).onZoneClick!('area-92449');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gebiet übernehmen'));
      await tester.pumpAndSettle();
      expect(changes.single.single.name, '92449');
    },
  );

  testWidgets(
    'selecting an existing polygon never makes map taps add vertices',
    (tester) async {
      final changes = <List<KMapZone>>[];
      await mount(tester, changed: changes.add);
      tester.widget<KMap>(find.byType(KMap)).onZoneClick!('west');
      await tester.pumpAndSettle();
      final map = tester.widget<KMap>(find.byType(KMap));
      map.onMapTap!(const KMapCenter(longitude: 13.4, latitude: 52.53));
      await tester.pumpAndSettle();
      expect(
        tester.widget<KMap>(find.byType(KMap)).zones.single.coordinates,
        zone.coordinates,
      );
      expect(changes, isEmpty);
      expect(find.text('Übernehmen'), findsNothing);
    },
  );
  for (final action in ['Speichern', 'Verwerfen']) {
    testWidgets(
      'dirty properties close via $action restores bar and geometry interaction',
      (tester) async {
        await mount(tester, size: const Size(390, 700));
        await tester.tap(find.byTooltip('Zoneneigenschaften bearbeiten'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'Edited');
        await tester.tap(find.byTooltip('Zonen schließen'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(action));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('zone-selection-bar')),
          findsOneWidget,
        );
        final map = tester.widget<KMap>(find.byType(KMap));
        expect(map.pins, isNotEmpty);
        expect(
          await map.onPinMove!(
            const KMapPinMove(
              id: 'zone-vertex-0-0-0',
              position: KMapCenter(longitude: 13.384, latitude: 52.515),
              source: KMapPinMoveSource.drag,
            ),
          ),
          isTrue,
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('zone-dirty-feedback')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'oversized consumer inset keeps selection bar within map viewport',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 350));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: KMapZoneEditor(
              mapStyle: 'invalid',
              bottomOverlayInset: 9999,
              center: const KMapCenter(longitude: 13.397, latitude: 52.52),
              zones: const [zone],
              onChange: (_) {},
              onSelect: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rect = tester.getRect(
        find.byKey(const ValueKey('zone-selection-bar')),
      );
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(350));
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [const Size(390, 700), const Size(1200, 850)]) {
    testWidgets(
      'zone bar survives async sync, selection and clean properties close at $size',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final zones = ValueNotifier<List<KMapZone>>([]);
        addTearDown(zones.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(),
            home: Scaffold(
              body: ValueListenableBuilder<List<KMapZone>>(
                valueListenable: zones,
                builder: (context, value, _) => KMapZoneEditor(
                  mapStyle: 'invalid',
                  center: const KMapCenter(longitude: 13.397, latitude: 52.52),
                  zones: value,
                  onChange: (value) => zones.value = value,
                  onSelect: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final bar = find.byKey(const ValueKey('zone-selection-bar'));
        expect(bar, findsNothing);
        zones.value = [zone];
        await tester.pumpAndSettle();
        expect(bar, findsOneWidget);
        final asynchronouslyLoadedMap = tester.widget<KMap>(find.byType(KMap));
        expect(asynchronouslyLoadedMap.fitContentOnLoad, isTrue);
        expect(asynchronouslyLoadedMap.zones.single.id, zone.id);
        expect(
          asynchronouslyLoadedMap.zones.single.coordinates,
          zone.coordinates,
        );
        tester.widget<KMap>(find.byType(KMap)).onZoneClick!(zone.id);
        await tester.pumpAndSettle();
        expect(bar, findsOneWidget);
        const move = KMapPinMove(
          id: 'zone-vertex-0-0-0',
          position: KMapCenter(longitude: 13.383, latitude: 52.515),
          source: KMapPinMoveSource.keyboard,
        );
        await tester.widget<KMap>(find.byType(KMap)).onPinMove!(move);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('zone-dirty-feedback')),
          findsOneWidget,
        );
        expect(bar, findsNothing);
        await tester.tap(find.byTooltip('Verwerfen'));
        await tester.pumpAndSettle();
        expect(bar, findsOneWidget);
        await tester.widget<KMap>(find.byType(KMap)).onPinMove!(move);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Übernehmen'));
        await tester.pumpAndSettle();
        expect(zones.value, hasLength(1));
        expect(bar, findsOneWidget);
        await tester.tap(find.byTooltip('Zoneneigenschaften bearbeiten'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Zonen schließen'));
        await tester.pumpAndSettle();
        expect(bar, findsOneWidget);
        expect(find.byTooltip('Zone hinzufügen'), findsOneWidget);
        final activeMap = tester.widget<KMap>(find.byType(KMap));
        expect(activeMap.pins, isNotEmpty);
        expect(
          await activeMap.onPinMove!(
            const KMapPinMove(
              id: 'zone-vertex-0-0-0',
              position: KMapCenter(longitude: 13.384, latitude: 52.515),
              source: KMapPinMoveSource.drag,
            ),
          ),
          isTrue,
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('zone-dirty-feedback')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'phone properties stays anchored above the pill without autofocus',
    (tester) async {
      await mount(tester, size: const Size(390, 700));
      await tester.tap(find.byTooltip('Zoneneigenschaften bearbeiten'));
      await tester.pumpAndSettle();
      expect(find.text('Zoneneigenschaften'), findsNothing);
      expect(find.text('West'), findsWidgets);
      expect(find.byKey(const ValueKey('zone-selection-bar')), findsOneWidget);
      expect(find.text('Fertig'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).autofocus,
        isFalse,
      );
      final panel = find
          .ancestor(
            of: find.byKey(const ValueKey('zone-panel-properties')),
            matching: find.byType(AnimatedContainer),
          )
          .first;
      expect(tester.getSize(panel), const Size(366, 600));
      expect(tester.getRect(panel).bottom, 620);
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(const Size(390, 280));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(panel).height, 180);
    },
  );

  testWidgets('direct properties back closes the surface and returns to map', (
    tester,
  ) async {
    await mount(tester, size: const Size(390, 700));
    await tester.tap(find.byTooltip('Zoneneigenschaften bearbeiten'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('zone-panel-properties')), findsOneWidget);
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('zone-panel-properties')), findsNothing);
    expect(find.byKey(const ValueKey('zone-panel-list')), findsNothing);
    expect(find.byKey(const ValueKey('zone-selection-bar')), findsOneWidget);
    expect(tester.widget<KMap>(find.byType(KMap)).pins, isNotEmpty);
  });

  testWidgets('properties opened from the list returns to the list on back', (
    tester,
  ) async {
    await mount(tester, open: true, size: const Size(390, 700));
    await tester.tap(find.byTooltip('Zone bearbeiten: West'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('zone-panel-properties')), findsOneWidget);
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('zone-panel-properties')), findsNothing);
    expect(find.byKey(const ValueKey('zone-panel-list')), findsOneWidget);
    expect(find.text('Meine Gebiete'), findsOneWidget);
    expect(find.byKey(const ValueKey('zone-selection-bar')), findsOneWidget);
  });

  testWidgets(
    'floating and dirty pills share exact geometry and animate consumer overlay lift together',
    (tester) async {
      final lift = ValueNotifier(0.0);
      addTearDown(lift.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: ValueListenableBuilder<double>(
              valueListenable: lift,
              builder: (context, value, _) => KMapZoneEditor(
                mapStyle: 'invalid',
                center: const KMapCenter(longitude: 13.397, latitude: 52.52),
                zones: const [zone],
                selectedZoneId: zone.id,
                bottomOverlayInset: value,
                onChange: (_) {},
                onSelect: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final selection = find.byKey(const ValueKey('zone-selection-bar'));
      final dirty = find.byKey(const ValueKey('zone-dirty-feedback'));
      final before = tester.getRect(selection);
      final selectionSurface = tester.widget<Material>(
        find.ancestor(of: selection, matching: find.byType(Material)).first,
      );
      final map = tester.widget<KMap>(find.byType(KMap));
      await map.onPinMove!(
        const KMapPinMove(
          id: 'zone-vertex-0-0-0',
          position: KMapCenter(longitude: 13.383, latitude: 52.515),
          source: KMapPinMoveSource.keyboard,
        ),
      );
      await tester.pump();
      expect(
        tester
            .widget<IgnorePointer>(
              find
                  .ancestor(of: selection, matching: find.byType(IgnorePointer))
                  .first,
            )
            .ignoring,
        isTrue,
      );
      expect(
        tester
            .widget<ExcludeSemantics>(
              find
                  .ancestor(
                    of: selection,
                    matching: find.byType(ExcludeSemantics),
                  )
                  .first,
            )
            .excluding,
        isTrue,
      );
      await tester.pumpAndSettle();
      expect(selection, findsNothing);
      final beforeDirty = tester.getRect(dirty);
      expect(beforeDirty, before);
      final dirtySurface = tester.widget<Material>(
        find.descendant(of: dirty, matching: find.byType(Material)).first,
      );
      expect(dirtySurface.borderRadius, selectionSurface.borderRadius);
      expect(
        tester.getSize(find.byTooltip('Rückgängig')).height,
        greaterThanOrEqualTo(44),
      );
      lift.value = 72;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 70));
      expect(tester.getRect(dirty).top, lessThan(before.top));
      expect(tester.getRect(dirty).top, greaterThan(before.top - 72));
      await tester.pumpAndSettle();
      expect(tester.getRect(dirty).top, closeTo(before.top - 72, .001));
      expect(tester.getRect(dirty).top, closeTo(beforeDirty.top - 72, .001));
      expect(tester.getRect(dirty).size, before.size);
      await tester.tap(find.byTooltip('Verwerfen'));
      await tester.pump();
      expect(
        tester
            .widget<IgnorePointer>(
              find
                  .ancestor(of: dirty, matching: find.byType(IgnorePointer))
                  .first,
            )
            .ignoring,
        isTrue,
      );
      await tester.pumpAndSettle();
      expect(dirty, findsNothing);
      expect(tester.getRect(selection).top, closeTo(before.top - 72, .001));
      expect(tester.getRect(selection).size, before.size);
    },
  );

  testWidgets(
    'disabling during a drag cancels only that drag and preserves earlier undo',
    (tester) async {
      final disabled = ValueNotifier(false);
      addTearDown(disabled.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: disabled,
              builder: (context, value, _) => KMapZoneEditor(
                mapStyle: 'invalid',
                center: const KMapCenter(longitude: 13.397, latitude: 52.52),
                zones: const [zone],
                selectedZoneId: zone.id,
                disabled: value,
                onChange: (_) {},
                onSelect: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      KMap map() => tester.widget<KMap>(find.byType(KMap));
      const earlier = KMapPinMove(
        id: 'zone-vertex-0-0-0',
        position: KMapCenter(longitude: 13.383, latitude: 52.515),
        source: KMapPinMoveSource.keyboard,
      );
      await map().onPinMove!(earlier);
      await tester.pump();
      final before = map().zones.single.coordinates.toList();
      const dragging = KMapPinMove(
        id: 'zone-midpoint-0-0-1',
        position: KMapCenter(longitude: 13.399, latitude: 52.521),
        source: KMapPinMoveSource.drag,
      );
      map().onPinDragStart!(dragging);
      map().onPinDrag!(dragging);
      await tester.pump();
      expect(map().zones.single.coordinates, hasLength(5));
      disabled.value = true;
      await tester.pump();
      expect(map().zones.single.coordinates, before);
      disabled.value = false;
      await tester.pump();
      await tester.tap(find.byTooltip('Rückgängig'));
      await tester.pumpAndSettle();
      expect(map().zones.single.coordinates, zone.coordinates);
    },
  );

  testWidgets(
    'consumer Undo action invalidates on a new draft and cannot undo a newer commit',
    (tester) async {
      final changes = <List<KMapZone>>[];
      final undo = await mount(tester, changed: changes.add);
      KMap map() => tester.widget<KMap>(find.byType(KMap));
      KMapPinMove move(double longitude) => KMapPinMove(
        id: 'zone-vertex-0-0-0',
        position: KMapCenter(longitude: longitude, latitude: 52.515),
        source: KMapPinMoveSource.keyboard,
      );
      await map().onPinMove!(move(13.383));
      await tester.pump();
      await tester.tap(find.text('Übernehmen'));
      await tester.pumpAndSettle();
      final firstAction = undo.value!;
      expect(firstAction.label, 'Rückgängig');
      expect(find.text(firstAction.message), findsNothing);
      await map().onPinMove!(move(13.384));
      await tester.pump();
      expect(undo.value, isNull);
      firstAction.undo();
      await tester.pump();
      expect(map().zones.single.coordinates.first.longitude, 13.384);
      expect(changes, hasLength(1));
      await tester.tap(find.text('Übernehmen'));
      await tester.pumpAndSettle();
      final secondAction = undo.value!;
      firstAction.undo();
      await tester.pump();
      expect(changes, hasLength(2));
      secondAction.undo();
      await tester.pumpAndSettle();
      expect(changes, hasLength(3));
      expect(changes.last.single.coordinates.first.longitude, 13.383);
      expect(undo.value, isNull);
    },
  );

  testWidgets(
    'drag previews a midpoint live, records one undo and preserves earlier edits',
    (tester) async {
      await mount(tester, size: const Size(390, 650));
      KMap map() => tester.widget<KMap>(find.byType(KMap));
      KMapPinMove move(String id, double longitude, double latitude) =>
          KMapPinMove(
            id: id,
            position: KMapCenter(longitude: longitude, latitude: latitude),
            source: KMapPinMoveSource.drag,
          );
      final first = move('zone-vertex-0-0-0', 13.383, 52.515);
      await map().onPinMove!(first);
      await tester.pump();
      final earlier = map().zones.single.coordinates.toList();
      final start = move('zone-midpoint-0-0-1', 13.397, 52.52);
      map().onPinDragStart!(start);
      for (final latitude in [52.519, 52.520, 52.521]) {
        map().onPinDrag!(move(start.id, 13.399, latitude));
        await tester.pump();
        expect(map().zones.single.coordinates, hasLength(5));
        expect(map().zones.single.coordinates[2].longitude, 13.399);
        expect(map().zones.single.coordinates[2].latitude, latitude);
      }
      final end = move(start.id, 13.399, 52.521);
      await map().onPinMove!(end);
      map().onPinDragEnd!(end);
      await tester.pump();
      expect(find.byTooltip('Rückgängig'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('zone-selection-bar')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Rückgängig'));
      await tester.pump();
      expect(map().zones.single.coordinates, earlier);
      await tester.tap(find.byTooltip('Rückgängig'));
      await tester.pump();
      expect(map().zones.single.coordinates, zone.coordinates);
      await tester.pump(const Duration(milliseconds: 110));
    },
  );

  testWidgets(
    'cancel restores the drag snapshot without losing an earlier dirty edit',
    (tester) async {
      await mount(tester);
      KMap map() => tester.widget<KMap>(find.byType(KMap));
      const first = KMapPinMove(
        id: 'zone-vertex-0-0-0',
        position: KMapCenter(longitude: 13.383, latitude: 52.515),
        source: KMapPinMoveSource.keyboard,
      );
      await map().onPinMove!(first);
      await tester.pump();
      final earlier = map().zones.single.coordinates.toList();
      const drag = KMapPinMove(
        id: 'zone-vertex-0-0-1',
        position: KMapCenter(longitude: 13.401, latitude: 52.515),
        source: KMapPinMoveSource.drag,
      );
      map().onPinDragStart!(drag);
      map().onPinDrag!(drag);
      await tester.pump();
      expect(map().zones.single.coordinates, isNot(earlier));
      map().onPinDragCancel!(drag);
      await tester.pump();
      expect(map().zones.single.coordinates, earlier);
      await tester.tap(find.byTooltip('Rückgängig'));
      await tester.pump();
      expect(map().zones.single.coordinates, zone.coordinates);
      await tester.pump(const Duration(milliseconds: 110));
    },
  );

  testWidgets(
    'list properties edit preserves current map selection and exposes Add footer',
    (tester) async {
      final east = KMapZone(
        id: 'east',
        name: 'Ost',
        coordinates: [
          for (final point in zone.coordinates)
            KMapCenter(
              longitude: point.longitude + .03,
              latitude: point.latitude,
            ),
        ],
      );
      final selections = <String?>[];
      final changes = <List<KMapZone>>[];
      await mount(
        tester,
        zones: [zone, east],
        open: true,
        selectedChanged: selections.add,
        changed: changes.add,
      );
      expect(find.text('Zone hinzufügen'), findsOneWidget);
      await tester.tap(find.byTooltip('Zone bearbeiten: Ost'));
      await tester.pumpAndSettle();
      expect(tester.widget<KMap>(find.byType(KMap)).selectedZoneId, 'west');
      expect(selections, isEmpty);
      await tester.enterText(find.byType(TextField).first, 'Ost neu');
      await tester.pump();
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();
      expect(changes.single.last.name, 'Ost neu');
      expect(tester.widget<KMap>(find.byType(KMap)).selectedZoneId, 'west');
      expect(selections, isEmpty);
    },
  );

  testWidgets(
    'editing a hole preserves every other ring and disconnected part',
    (tester) async {
      List<KMapCenter> rectangle(
        double left,
        double bottom,
        double right,
        double top,
      ) => [
        KMapCenter(longitude: left, latitude: bottom),
        KMapCenter(longitude: right, latitude: bottom),
        KMapCenter(longitude: right, latitude: top),
        KMapCenter(longitude: left, latitude: top),
      ];
      final outer = rectangle(0, 0, 10, 10),
          hole = rectangle(2, 2, 4, 4),
          island = rectangle(12, 0, 14, 2);
      final complex = KMapZone(
        id: 'complex',
        name: 'Mehrere Flächen',
        coordinates: outer,
        polygons: [
          KMapPolygon(outer: outer, holes: [hole]),
          KMapPolygon(outer: island),
        ],
      );
      final changes = <List<KMapZone>>[];
      await mount(tester, zones: [complex], changed: changes.add);
      final map = tester.widget<KMap>(find.byType(KMap));
      expect(
        await map.onPinMove!(
          const KMapPinMove(
            id: 'zone-vertex-0-1-0',
            position: KMapCenter(longitude: 2.1, latitude: 2.1),
            source: KMapPinMoveSource.drag,
          ),
        ),
        isTrue,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Übernehmen'));
      await tester.pumpAndSettle();
      expect(changes.single.single.polygons, hasLength(2));
      expect(changes.single.single.polygons!.first.outer, outer);
      expect(changes.single.single.polygons!.last.outer, island);
      expect(
        changes.single.single.polygons!.first.holes.single.first,
        const KMapCenter(longitude: 2.1, latitude: 2.1),
      );
    },
  );
  testWidgets(
    'pending callback exposes internal edits before onChange and clears after apply',
    (tester) async {
      final pending = <bool>[];
      var commits = 0;
      await mount(
        tester,
        pendingChanged: pending.add,
        changed: (_) => commits++,
      );
      expect(pending.last, isFalse);
      await tester.tap(find.byTooltip('Zoneneigenschaften bearbeiten'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Noch lokal');
      await tester.pumpAndSettle();
      expect(pending.last, isTrue);
      expect(commits, 0);
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();
      expect(pending.last, isFalse);
      expect(commits, 1);
    },
  );
  testWidgets(
    'request-only booking switch defaults false and survives commit and undo',
    (tester) async {
      final changes = <List<KMapZone>>[];
      final undo = await mount(tester, changed: changes.add);
      await tester.tap(find.byTooltip('Zoneneigenschaften bearbeiten'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buchungen nur auf Anfrage'));
      await tester.pump();
      expect(changes, isEmpty);
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();
      expect(changes.single.single.settings!.requestRequired, isTrue);
      expect(undo.value, isNotNull);
      undo.value!.undo();
      await tester.pumpAndSettle();
      expect(changes.last.single.settings?.requestRequired ?? false, isFalse);
    },
  );
  testWidgets('paid travel cost stays inline and accepts zero', (tester) async {
    final paidZero = zone.copyWith(
      settings: const KMapZoneSettings(
        travelCost: KMapZoneTravelCost(
          kind: 'per-kilometer',
          amount: 1,
          currency: 'EUR',
        ),
      ),
    );
    final changes = <List<KMapZone>>[];
    await mount(tester, zones: [paidZero], changed: changes.add);

    await tester.tap(find.byTooltip('Zoneneigenschaften bearbeiten'));
    await tester.pumpAndSettle();

    expect(find.text('Betrag (EUR)'), findsOneWidget);
    expect(find.text('Kosten festlegen'), findsNothing);
    final amount = find.descendant(
      of: find.byWidgetPredicate(
        (widget) => widget is KInput && widget.label == 'Betrag',
      ),
      matching: find.byType(TextField),
    );
    await tester.enterText(amount, '0');
    await tester.pump();
    await tester.ensureVisible(find.text('Fertig'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fertig'));
    await tester.pumpAndSettle();

    final cost = changes.single.single.settings!.travelCost!;
    expect(cost.kind, 'per-kilometer');
    expect(cost.amount, 0);
    expect(cost.currency, 'EUR');
  });

  testWidgets(
    'travel cost copies once from another zone and remains independently editable',
    (tester) async {
      final target = zone.copyWith(
        settings: const KMapZoneSettings(
          travelCost: KMapZoneTravelCost(
            kind: 'per-kilometer',
            amount: 1,
            currency: 'EUR',
          ),
        ),
      );
      final source = KMapZone(
        id: 'center',
        name: 'Mitte',
        coordinates: [
          for (final point in zone.coordinates)
            KMapCenter(
              longitude: point.longitude + .03,
              latitude: point.latitude,
            ),
        ],
        settings: const KMapZoneSettings(
          travelCost: KMapZoneTravelCost(
            kind: 'flat-rate',
            amount: 12.5,
            currency: 'EUR',
          ),
        ),
      );
      final changes = <List<KMapZone>>[];
      await mount(tester, zones: [target, source], changed: changes.add);

      await tester.tap(find.byTooltip('Zoneneigenschaften bearbeiten'));
      await tester.pumpAndSettle();
      final copySelect = find.descendant(
        of: find.byWidgetPredicate(
          (widget) =>
              widget is KSelect &&
              widget.label == 'Anfahrtskosten aus anderer Zone übernehmen',
        ),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(copySelect);
      await tester.pumpAndSettle();
      await tester.tap(copySelect);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Mitte · Pauschal pro Buchung'));
      await tester.pumpAndSettle();

      expect(find.text('Betrag (EUR)'), findsOneWidget);
      expect(find.text('Zone auswählen'), findsOneWidget);
      final amount = find.descendant(
        of: find.byWidgetPredicate(
          (widget) => widget is KInput && widget.label == 'Betrag',
        ),
        matching: find.byType(TextField),
      );
      await tester.enterText(amount, '14,00');
      await tester.pump();
      await tester.ensureVisible(find.text('Fertig'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();

      final copied = changes.single.first.settings!.travelCost!;
      expect(copied.kind, 'flat-rate');
      expect(copied.amount, 14);
      expect(copied.currency, 'EUR');
      expect(source.settings!.travelCost!.amount, 12.5);
    },
  );
  testWidgets(
    'map fills viewport and one floating surface morphs list to properties',
    (tester) async {
      await mount(tester, open: true);
      expect(tester.getSize(find.byType(KMap)), const Size(1200, 850));
      expect(find.text('Meine Gebiete'), findsOneWidget);
      await tester.tap(find.byTooltip('Zone bearbeiten: West'));
      await tester.pumpAndSettle();
      expect(find.text('Zoneneigenschaften'), findsNothing);
      expect(find.text('Meine Gebiete'), findsNothing);
      expect(find.text('Farbe'), findsNothing);
      await tester.tap(find.byTooltip('Farbe'));
      await tester.pumpAndSettle();
      expect(find.text('Farbe'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'West'), findsOneWidget);
    },
  );

  testWidgets(
    'properties draft blocks blank names; Done commits once; undo restores',
    (tester) async {
      final changes = <List<KMapZone>>[];
      final undo = await mount(tester, changed: changes.add);
      await tester.tap(find.byTooltip('Zoneneigenschaften bearbeiten'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '');
      await tester.pump();
      expect(changes, isEmpty);
      final done = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Fertig'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(done.onPressed, isNull);
      await tester.enterText(find.byType(TextField).first, 'Mitte');
      await tester.pump();
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();
      expect(changes, hasLength(1));
      expect(changes.single.single.name, 'Mitte');
      expect(undo.value, isNotNull);
      undo.value!.undo();
      await tester.pumpAndSettle();
      expect(changes, hasLength(2));
      expect(changes.last.single.name, 'West');
    },
  );

  testWidgets('dirty close offers continue discard save and preserves edits', (
    tester,
  ) async {
    final changes = <List<KMapZone>>[];
    await mount(tester, changed: changes.add);
    await tester.tap(find.byTooltip('Zoneneigenschaften bearbeiten'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Draft');
    await tester.tap(find.byTooltip('Zonen schließen'));
    await tester.pumpAndSettle();
    expect(find.text('Änderungen speichern?'), findsOneWidget);
    await tester.tap(find.text('Weiter bearbeiten'));
    await tester.pumpAndSettle();
    expect(find.text('Draft'), findsWidgets);
    expect(changes, isEmpty);
    await tester.tap(find.byTooltip('Zonen schließen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verwerfen'));
    await tester.pumpAndSettle();
    expect(find.text('Zoneneigenschaften'), findsNothing);
    expect(changes, isEmpty);
  });

  testWidgets(
    'radius overlap confirmation is atomic and undo restores removed zone',
    (tester) async {
      final changes = <List<KMapZone>>[];
      final undo = await mount(tester, changed: changes.add);
      await tester.tap(find.byTooltip('Zone hinzufügen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Umkreis'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Übernehmen'));
      await tester.pumpAndSettle();
      expect(find.text('Überlappung übernehmen?'), findsOneWidget);
      expect(changes, isEmpty);
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(changes, isEmpty);
      await tester.tap(find.text('Übernehmen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anpassen und übernehmen'));
      await tester.pumpAndSettle();
      expect(changes, hasLength(1));
      expect(changes.single.single.kind, 'circle');
      expect(undo.value, isNotNull);
      undo.value!.undo();
      await tester.pumpAndSettle();
      expect(changes.last.single.id, 'west');
    },
  );

  testWidgets(
    'empty mobile editor has three starts and no dock before creation',
    (tester) async {
      await mount(tester, zones: [], size: const Size(390, 844));
      expect(find.text('Erstelle deine erste Zone'), findsOneWidget);
      expect(find.textContaining('Lege fest, wo du arbeitest'), findsOneWidget);
      expect(find.byTooltip('Zone hinzufügen'), findsNothing);
      await tester.tap(find.text('Freie Grenze'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tippe in die Karte'), findsNothing);
      expect(tester.widget<KMap>(find.byType(KMap)).onMapTap, isNotNull);
      expect(find.byTooltip('Zone hinzufügen'), findsNothing);
      expect(find.byKey(const ValueKey('zone-dirty-feedback')), findsOneWidget);
      expect(find.text('Übernehmen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('host can hide map zoom controls for a fullscreen composition', (
    tester,
  ) async {
    await mount(tester, showZoomControls: false);

    expect(tester.widget<KMap>(find.byType(KMap)).showZoomControls, isFalse);
  });

  testWidgets(
    'fullscreen back closes the editor panel before requesting exit',
    (tester) async {
      var exitRequests = 0;
      await mount(tester, open: true, onExitRequested: () => exitRequests++);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(exitRequests, 0);
      expect(find.byTooltip('Zone hinzufügen'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(exitRequests, 1);
    },
  );
}
