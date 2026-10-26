import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_map.dart';
import 'package:k_design_ui/k_map_zone_editor.dart';
import 'package:k_design_widgetbook/map_zone_editor_fixture.dart';

Widget fixture({bool empty = false}) => MaterialApp(
  theme: kDesignTheme(),
  home: Scaffold(
    body: MapZoneEditorFixture(
      fullscreen: true,
      empty: empty,
      mapStyleOverride: 'invalid',
    ),
  ),
);

void main() {
  testWidgets('fullscreen fixture fills the map and guards unsaved exit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(fixture());
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(KMap)), const Size(390, 844));
    expect(tester.widget<KMap>(find.byType(KMap)).showZoomControls, isFalse);
    expect(find.bySemanticsLabel('Zurück zur Verwaltung'), findsOneWidget);

    tester.widget<KMapZoneEditor>(find.byType(KMapZoneEditor)).onChange([
      mapZoneEditorZones.first.copyWith(name: 'Geändert'),
      ...mapZoneEditorZones.skip(1),
    ]);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Gebiete speichern'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Änderungen speichern?'), findsOneWidget);
    expect(find.text('Weiter bearbeiten'), findsOneWidget);
    expect(find.text('Verwerfen'), findsOneWidget);
    expect(find.text('Speichern'), findsOneWidget);

    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Zurück zur Verwaltung'), findsOneWidget);
    expect(find.bySemanticsLabel('Gebiete speichern'), findsNothing);
  });

  testWidgets('fullscreen empty fixture keeps the first-zone entry points', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(fixture(empty: true));
    await tester.pumpAndSettle();

    expect(find.text('Erstelle deine erste Zone'), findsOneWidget);
    expect(find.bySemanticsLabel('Zurück zur Verwaltung'), findsOneWidget);
  });
}
