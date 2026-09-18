import 'dart:ui' show SemanticsRole;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

Widget frame(Widget table, {double width = 600, double scale = 1}) =>
    MaterialApp(
      theme: ThemeData(extensions: [KDesignTokens.orbitLight]),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Center(
          child: SizedBox(width: width, child: table),
        ),
      ),
    );
const columns = [
  KTableColumn(id: 'fixed', header: Text('Fixed'), width: 100),
  KTableColumn(id: 'a', header: Text('A'), minWidth: 100),
  KTableColumn(id: 'b', header: Text('B'), minWidth: 100, flex: 3),
];
const rows = [
  KTableRow(id: 'one', cells: [Text('one'), Text('two'), Text('three')]),
];

void main() {
  testWidgets('simple table keeps visible dividers by default', (tester) async {
    await tester.pumpWidget(
      frame(const KTable(label: 'Rows', columns: columns, rows: rows)),
    );
    for (final row in tester.widget<Table>(find.byType(Table)).children) {
      final border = (row.decoration! as BoxDecoration).border! as Border;
      expect(border.bottom.color, KDesignTokens.orbitLight.colorBorderDefault);
    }
  });

  testWidgets(
    'column padding overrides preserve track width and reject invalid values',
    (tester) async {
      for (final padding in [0.0, 7.0]) {
        await tester.pumpWidget(
          frame(
            KTable(
              label: 'Padding',
              columns: [
                KTableColumn(
                  id: 'a',
                  header: const Text('Head'),
                  width: 48,
                  paddingInline: padding,
                ),
              ],
              rows: const [
                KTableRow(id: 'row', cells: [Text('Cell')]),
              ],
            ),
          ),
        );
        final origin = tester.getTopLeft(find.byType(Table)).dx;
        expect(tester.getTopLeft(find.text('Head')).dx - origin, padding);
        expect(tester.getTopLeft(find.text('Cell')).dx - origin, padding);
        expect(tester.getSize(find.byType(Table)).width, 48);
      }
      for (final padding in [-1.0, double.infinity, double.nan]) {
        await tester.pumpWidget(
          frame(
            KTable(
              label: 'Invalid',
              columns: [
                KTableColumn(
                  id: 'a',
                  header: const Text('Head'),
                  paddingInline: padding,
                ),
              ],
              rows: const [],
            ),
          ),
        );
        expect(tester.takeException(), isArgumentError);
      }
    },
  );

  testWidgets('hidden header rows require labels and preserve cell semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      frame(
        const KTable(
          label: 'Hidden',
          showHeader: false,
          columns: [
            KTableColumn(
              id: 'a',
              header: Text('Project'),
              headerLabel: 'Project',
            ),
          ],
          rows: [
            KTableRow(id: 'a', cells: [Text('Atlas')]),
          ],
        ),
      ),
    );
    expect(find.text('Project'), findsNothing);
    expect(find.bySemanticsLabel('Project'), findsOneWidget);
    expect(tester.widget<Table>(find.byType(Table)).children.length, 1);
    final cell = tester.getSemantics(find.bySemanticsLabel('Project'));
    expect(cell.getSemanticsData().role, SemanticsRole.cell);
    semantics.dispose();
    await tester.pumpWidget(
      frame(
        const KTable(
          label: 'Invalid',
          showHeader: false,
          columns: [KTableColumn(id: 'a', header: Text('Project'))],
          rows: [],
        ),
      ),
    );
    expect(tester.takeException(), isArgumentError);
  });

  testWidgets('fixed and weighted tracks match headers and rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      frame(const KTable(label: 'Items', columns: columns, rows: rows)),
    );
    for (final table in tester.widgetList<Table>(find.byType(Table))) {
      expect((table.columnWidths![0] as FixedColumnWidth).value, 100);
      expect((table.columnWidths![1] as FixedColumnWidth).value, 175);
      expect((table.columnWidths![2] as FixedColumnWidth).value, 325);
    }
    expect(
      tester.getTopLeft(find.text('A')).dx,
      tester.getTopLeft(find.text('two')).dx,
    );
  });
  testWidgets('overflow preserves tracks and is horizontally scrollable', (
    tester,
  ) async {
    await tester.pumpWidget(
      frame(
        const KTable(label: 'Items', columns: columns, rows: rows),
        width: 200,
      ),
    );
    expect(tester.getSize(find.byType(Table).first).width, 300);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-150, 0),
    );
    await tester.pumpAndSettle();
    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      greaterThan(0),
    );
  });
  testWidgets(
    'fixed-only table does not stretch and empty table retains headers',
    (tester) async {
      await tester.pumpWidget(
        frame(
          const KTable(
            label: 'Empty',
            columns: [
              KTableColumn(id: 'a', header: Text('Header'), width: 100),
            ],
            rows: [],
          ),
        ),
      );
      expect(tester.getSize(find.byType(Table)).width, 100);
      expect(find.text('Header'), findsOneWidget);
    },
  );
  testWidgets('wrapping and scaling grow rows, controls remain operable', (
    tester,
  ) async {
    var tapped = false;
    Widget table() => KTable(
      label: 'Items',
      columns: const [
        KTableColumn(id: 'a', header: Text('Header'), width: 180),
        KTableColumn(
          id: 'b',
          header: Text('Action'),
          width: 180,
          align: KTableAlign.end,
        ),
      ],
      rows: [
        KTableRow(
          id: 'r',
          cells: [
            const Text(
              'A long text that should wrap onto several lines within the cell',
            ),
            KButton(label: 'Open', onPressed: () => tapped = true),
          ],
        ),
      ],
    );
    await tester.pumpWidget(frame(table()));
    final height = tester.getSize(find.byType(Table).last).height;
    await tester.tap(find.text('Open'));
    expect(tapped, isTrue);
    await tester.pumpWidget(frame(table(), scale: 2));
    expect(tester.getSize(find.byType(Table).last).height, greaterThan(height));
    expect(tester.takeException(), isNull);
  });
  testWidgets('alignment and density row minima follow tokens', (tester) async {
    for (final density in KDensity.values) {
      final tokens = kDesignTokens(
        configuration: KDesignConfiguration(density: density),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [tokens]),
          home: Center(
            child: SizedBox(
              width: 300,
              child: KTable(
                label: 'Items',
                columns: const [
                  KTableColumn(id: 'a', header: Text('A'), width: 100),
                  KTableColumn(
                    id: 'b',
                    header: Text('B'),
                    width: 100,
                    align: KTableAlign.center,
                  ),
                  KTableColumn(
                    id: 'c',
                    header: Text('C'),
                    width: 100,
                    align: KTableAlign.end,
                  ),
                ],
                rows: const [
                  KTableRow(
                    id: 'r',
                    cells: [
                      SizedBox(key: ValueKey('start'), width: 10, height: 10),
                      SizedBox(key: ValueKey('center'), width: 10, height: 10),
                      SizedBox(key: ValueKey('end'), width: 10, height: 10),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byType(Table).last);
      expect(
        rect.height / 2,
        tokens.sizeControl +
            2 * tokens.spaceControlGap +
            tokens.borderWidthDefault,
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('start'))).dx - rect.left,
        tokens.spaceControlInsetInline,
      );
      expect(
        tester.getCenter(find.byKey(const ValueKey('center'))).dx - rect.left,
        150,
      );
      expect(
        rect.right -
            tester.getBottomRight(find.byKey(const ValueKey('end'))).dx,
        tokens.spaceControlInsetInline,
      );
    }
  });
  testWidgets('invalid contracts fail at runtime', (tester) async {
    final invalid = [
      const KTable(label: '', columns: columns, rows: []),
      const KTable(label: 'Items', columns: [], rows: []),
      const KTable(
        label: 'Items',
        columns: [KTableColumn(id: 'a', header: Text('A'), width: -1)],
        rows: [],
      ),
      const KTable(
        label: 'Items',
        columns: [KTableColumn(id: 'a', header: Text('A'), flex: 0)],
        rows: [],
      ),
      const KTable(
        label: 'Items',
        columns: columns,
        rows: [KTableRow(id: 'r', cells: [])],
      ),
      const KTable(
        label: 'Items',
        columns: columns,
        rows: [
          KTableRow(id: 'r', cells: [Text('a'), Text('b'), Text('c')]),
          KTableRow(id: 'r', cells: [Text('a'), Text('b'), Text('c')]),
        ],
      ),
    ];
    for (final table in invalid) {
      await tester.pumpWidget(frame(table));
      expect(tester.takeException(), isArgumentError);
      await tester.pumpWidget(const SizedBox());
    }
  });
  testWidgets('semantic table, rows, and headers preserve button children', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      frame(
        KTable(
          label: 'Items',
          columns: const [KTableColumn(id: 'a', header: Text('Action'))],
          rows: [
            KTableRow(
              id: 'header',
              cells: [KButton(label: 'Open', onPressed: () {})],
            ),
          ],
        ),
      ),
    );
    expect(find.bySemanticsLabel('Items'), findsOneWidget);
    expect(find.bySemanticsLabel('Open'), findsOneWidget);
    final semantics = tester.widgetList<Semantics>(find.byType(Semantics));
    expect(
      tester.getSemantics(find.byType(Table)).getSemanticsData().role,
      SemanticsRole.table,
    );
    expect(
      semantics
          .where((s) => s.properties.role == SemanticsRole.columnHeader)
          .length,
      1,
    );
    handle.dispose();
  });
}
