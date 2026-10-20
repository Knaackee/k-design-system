import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/k_map_day_view.dart';

void main() {
  testWidgets('uses a right sidebar on wide viewports', (tester) async {
    await tester.pumpWidget(_app(width: 900));

    expect(find.byKey(const ValueKey('k-map-day-sheet')), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('k-map-day-panel'))).width,
      404,
    );
    expect(find.byKey(const ValueKey('k-map-day-timeline')), findsOneWidget);
    expect(find.textContaining('10:15 · Jetzt laut Plan'), findsOneWidget);
  });

  testWidgets('uses a persistent resizable sheet on narrow viewports', (
    tester,
  ) async {
    KMapDayPanelState? changed;
    await tester.pumpWidget(
      _app(
        width: 390,
        height: 800,
        onPanelStateChanged: (value) => changed = value,
      ),
    );

    expect(find.byKey(const ValueKey('k-map-day-sheet')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('k-map-day-sheet'))).height,
      372,
    );

    await tester.tap(find.bySemanticsLabel('Ansicht verkleinern'));
    await tester.pumpAndSettle();

    expect(changed, KMapDayPanelState.compact);
  });

  testWidgets('reports list and map selection through separate callbacks', (
    tester,
  ) async {
    final selections = <String>[];
    final listTaps = <String>[];
    final mapTaps = <String>[];
    await tester.pumpWidget(
      _app(
        width: 900,
        defaultSelectedItemId: 'travel',
        onSelectionChanged: selections.add,
        onItemTap: listTaps.add,
        onMapItemTap: mapTaps.add,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('k-map-day-item-stop')));
    await tester.pump();
    expect(selections, ['stop']);
    expect(listTaps, ['stop']);
    expect(mapTaps, isEmpty);

    await tester.tap(find.byKey(const ValueKey('map-select-travel')));
    await tester.pump();
    expect(selections, ['stop', 'travel']);
    expect(mapTaps, ['travel']);
  });

  testWidgets('renders forecast and dispatches item actions', (tester) async {
    KMapDayActionEvent? event;
    await tester.pumpWidget(
      _app(width: 900, onAction: (value) => event = value),
    );

    expect(find.text('Erwartet 10:35 · 5 Min. später'), findsOneWidget);
    await tester.ensureVisible(find.text('Details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Details'));
    await tester.pump();

    expect(event?.itemId, 'stop');
    expect(event?.actionId, 'details');
  });

  testWidgets('controller reports actual extent without controlled snapback', (
    tester,
  ) async {
    final controller = KMapDaySheetController();
    final fractions = <double>[];
    final states = <KMapDayPanelState>[];

    await tester.pumpWidget(
      _app(
        width: 390,
        panelState: KMapDayPanelState.medium,
        sheetController: controller,
        onSheetFractionChanged: fractions.add,
        onPanelStateChanged: states.add,
      ),
    );
    await tester.pump();

    expect(controller.isSheet, isTrue);
    expect(controller.fraction, closeTo(.62, .001));
    expect(controller.state, KMapDayPanelState.medium);

    final first = controller.animateTo(.91);
    await tester.pump(const Duration(milliseconds: 20));
    final second = controller.animateTo(.45);
    await tester.pumpAndSettle();
    await Future.wait([first, second]);

    // The test surface is 600 px high, so the 360 px content minimum wins.
    expect(controller.fraction, closeTo(.6, .001));
    expect(controller.state, isNull);
    expect(fractions.last, closeTo(controller.fraction, .001));

    await tester.pumpWidget(
      _app(
        width: 390,
        panelState: KMapDayPanelState.medium,
        sheetController: controller,
        onSheetFractionChanged: fractions.add,
        onPanelStateChanged: states.add,
      ),
    );
    await tester.pump();
    expect(controller.fraction, closeTo(.6, .001));

    final compact = controller.snapTo(KMapDayPanelState.compact);
    await tester.pumpAndSettle();
    await compact;
    expect(states.last, KMapDayPanelState.compact);
    expect(controller.fraction, closeTo(230 / 600, .001));
    expect(controller.state, KMapDayPanelState.compact);

    await tester.drag(
      find.byKey(const ValueKey('k-map-day-handle')),
      const Offset(0, -80),
    );
    await tester.pumpAndSettle();
    expect(fractions.last, closeTo(controller.fraction, .001));
  });

  testWidgets('keeps the selected row visible after shrinking the sheet', (
    tester,
  ) async {
    final controller = KMapDaySheetController();
    await tester.pumpWidget(
      _app(
        width: 390,
        defaultSelectedItemId: 'stop',
        sheetController: controller,
      ),
    );
    await tester.pump();

    final shrink = controller.animateTo(.45);
    await tester.pumpAndSettle();
    await shrink;

    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const ValueKey('k-map-day-timeline')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.pixels, greaterThan(0));
    expect(find.byKey(const ValueKey('k-map-day-item-stop')), findsOneWidget);
  });
}

Widget _app({
  required double width,
  double height = 800,
  String? defaultSelectedItemId,
  ValueChanged<String>? onSelectionChanged,
  ValueChanged<String>? onItemTap,
  ValueChanged<String>? onMapItemTap,
  ValueChanged<KMapDayActionEvent>? onAction,
  ValueChanged<KMapDayPanelState>? onPanelStateChanged,
  KMapDayPanelState? panelState,
  KMapDaySheetController? sheetController,
  ValueChanged<double>? onSheetFractionChanged,
}) => MaterialApp(
  theme: ThemeData(extensions: const [KDesignTokens.orbitLight]),
  home: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: width,
      height: height,
      child: KMapDayView(
        items: _items,
        currentTime: 615,
        title: 'Dein Tag unterwegs',
        dayLabel: 'Dienstag, 20. Oktober',
        defaultSelectedItemId: defaultSelectedItemId,
        summary: const Text('2 Kunden · 09:00 – 12:35'),
        description: const Text('Planposition, kein Live-Standort.'),
        footer: const Text('Tagesende 12:35'),
        onSelectionChanged: onSelectionChanged,
        onItemTap: onItemTap,
        onMapItemTap: onMapItemTap,
        onAction: onAction,
        onPanelStateChanged: onPanelStateChanged,
        panelState: panelState,
        sheetController: sheetController,
        onSheetFractionChanged: onSheetFractionChanged,
        mapBuilder: (context, mapContext) => ColoredBox(
          color: Colors.blueGrey,
          child: Align(
            alignment: Alignment.topLeft,
            child: TextButton(
              key: const ValueKey('map-select-travel'),
              onPressed: () => mapContext.onItemTap('travel'),
              child: const Text('Select travel on map'),
            ),
          ),
        ),
      ),
    ),
  ),
);

const _items = [
  KMapDayItem(
    id: 'travel',
    start: 600,
    end: 620,
    title: 'Mit dem Auto',
    detail: '20 Min. · 6,4 km',
    icon: KIconName.car,
    kind: KMapDayItemKind.travel,
  ),
  KMapDayItem(
    id: 'stop',
    start: 630,
    end: 675,
    expectedStart: 635,
    title: 'Anna Becker',
    detail: 'Kollwitzstraße 30 · 45 Min.',
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
];
