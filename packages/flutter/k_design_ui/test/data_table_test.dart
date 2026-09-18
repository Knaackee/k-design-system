import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

typedef Item = ({String id, String group, String sub, int score});
const items = <Item>[
  (id: 'a', group: 'B', sub: 'x', score: 2),
  (id: 'b', group: 'A', sub: 'x', score: 1),
  (id: 'c', group: 'B', sub: 'y', score: 2),
  (id: 'd', group: 'B', sub: 'x', score: 1),
];
final columns = <KDataTableColumn<Item>>[
  KDataTableColumn(
    id: 'id',
    label: 'Name',
    cell: (r) => Text(r.id),
    compare: (a, b) => a.score.compareTo(b.score),
  ),
];
Widget frame(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
List<String> rowIds(WidgetTester tester) => tester
    .widgetList<KTable>(find.byType(KTable))
    .expand((t) => t.rows.map((r) => r.id))
    .toList();
KDataTable<Item> table({
  List<Item> rows = items,
  KDataTableSort? sort,
  double? groupIndent,
  bool Function(Item)? filter,
  List<KDataTableGroup<Item>> groups = const [],
  Set<String> collapsed = const {},
  ValueChanged<Set<String>>? onCollapse,
}) => KDataTable<Item>(
  label: 'Items',
  columns: columns,
  rows: rows,
  rowId: (r) => r.id,
  empty: const Text('No matches'),
  sort: sort,
  groupIndent: groupIndent,
  filter: filter,
  groups: groups,
  collapsedGroups: collapsed,
  onCollapsedGroupsChanged: onCollapse,
);

void main() {
  testWidgets(
    'optional leaf footer gets immutable sorted filtered rows and full path',
    (tester) async {
      final sections = <KDataTableSection<Item>>[];
      await tester.pumpWidget(
        frame(
          KDataTable<Item>(
            label: 'Items',
            columns: columns,
            rows: items,
            rowId: (r) => r.id,
            empty: const Text('Empty'),
            sort: const KDataTableSort(
              columnId: 'id',
              direction: KDataTableSortDirection.ascending,
            ),
            filter: (r) => r.id != 'b',
            groups: [
              KDataTableGroup(
                id: 'group',
                value: (r) => r.group,
                label: (value) => 'Group $value',
              ),
              KDataTableGroup(id: 'sub', value: (r) => r.sub),
            ],
            footerBuilder: (section) {
              sections.add(section);
              return Text('Add ${section.path.map((p) => p.value).join('/')}');
            },
          ),
        ),
      );
      expect(sections.length, 2);
      expect(sections.first.rows.map((r) => r.id), ['d', 'a']);
      expect(sections.first.path.map((p) => (p.id, p.value, p.label)), [
        ('group', 'B', 'Group B'),
        ('sub', 'x', 'x'),
      ]);
      expect(() => sections.first.rows.clear(), throwsUnsupportedError);
      expect(() => sections.first.path.clear(), throwsUnsupportedError);
      expect(find.text('Add B/x'), findsOneWidget);
      expect(find.text('Add B/y'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Add B/x')).dy,
        greaterThan(tester.getBottomLeft(find.byType(KTable).first).dy),
      );
      sections.clear();
      await tester.pumpWidget(
        frame(
          KDataTable<Item>(
            label: 'Items',
            columns: columns,
            rows: items,
            rowId: (r) => r.id,
            empty: const Text('Empty'),
            groups: [KDataTableGroup(id: 'group', value: (r) => r.group)],
            collapsedGroups: {
              jsonEncode([
                ['group', 'B'],
              ]),
            },
            footerBuilder: (section) {
              sections.add(section);
              return const Text('Add');
            },
          ),
        ),
      );
      expect(sections.length, 1);
      expect(sections.single.path.single.value, 'A');
      await tester.pumpWidget(frame(table()));
      expect(find.text('Add'), findsNothing);
    },
  );
  testWidgets('empty table gets one root footer even with group definitions', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      frame(
        KDataTable<Item>(
          label: 'Items',
          columns: columns,
          rows: const [],
          rowId: (r) => r.id,
          empty: const Text('Empty'),
          groups: [KDataTableGroup(id: 'group', value: (r) => r.group)],
          footerBuilder: (section) {
            calls++;
            expect(section.rows, isEmpty);
            expect(section.path, isEmpty);
            return const Text('Create first');
          },
        ),
      ),
    );
    expect(calls, 1);
    expect(find.text('Empty'), findsOneWidget);
    expect(find.text('Create first'), findsOneWidget);
    expect(find.byType(KTable), findsNothing);
  });
  testWidgets('data table dividers are optional without changing geometry', (
    tester,
  ) async {
    double? height;
    for (final dividers in [false, true]) {
      await tester.pumpWidget(
        frame(
          KDataTable<Item>(
            label: 'Rows',
            columns: columns,
            rows: items,
            rowId: (r) => r.id,
            empty: const SizedBox(),
            showRowDividers: dividers,
          ),
        ),
      );
      final native = tester.widget<Table>(find.byType(Table));
      final border =
          (native.children.first.decoration! as BoxDecoration).border!
              as Border;
      expect(
        border.bottom.color,
        dividers
            ? KDesignTokens.orbitLight.colorBorderDefault
            : Colors.transparent,
      );
      expect(border.bottom.width, KDesignTokens.orbitLight.borderWidthDefault);
      final current = tester.getSize(find.byType(Table)).height;
      if (height != null) expect(current, height);
      height = current;
    }
    await tester.pumpWidget(frame(table()));
    expect(tester.widget<KTable>(find.byType(KTable)).showRowDividers, isFalse);
  });

  testWidgets('column padding forwards to leaves and validates empty data', (
    tester,
  ) async {
    Widget padded(double padding, List<Item> rows) => frame(
      KDataTable<Item>(
        label: 'Items',
        columns: [
          KDataTableColumn(
            id: 'id',
            label: 'Name',
            cell: (r) => Text(r.id),
            paddingInline: padding,
          ),
        ],
        rows: rows,
        rowId: (r) => r.id,
        empty: const Text('Empty'),
      ),
    );
    await tester.pumpWidget(padded(0, items));
    expect(
      tester.widget<KTable>(find.byType(KTable)).columns.single.paddingInline,
      0,
    );
    for (final padding in [-1.0, double.infinity, double.nan]) {
      await tester.pumpWidget(padded(padding, []));
      expect(tester.takeException(), isArgumentError);
    }
  });

  testWidgets('group headings and leaves indent by absolute nesting depth', (
    tester,
  ) async {
    final groups = [
      KDataTableGroup<Item>(id: 'group', value: (r) => r.group),
      KDataTableGroup<Item>(id: 'sub', value: (r) => r.sub),
    ];
    for (final custom in <double?>[null, 24, 0]) {
      await tester.pumpWidget(
        frame(table(rows: [items.first], groups: groups, groupIndent: custom)),
      );
      final indent = custom ?? KDesignTokens.orbitLight.spaceControlInsetInline;
      final origin = tester.getTopLeft(find.byType(KDataTable<Item>)).dx;
      expect(tester.getTopLeft(find.text('B (1)')).dx - origin, 0);
      expect(tester.getTopLeft(find.text('x (1)')).dx - origin, indent);
      expect(tester.getTopLeft(find.byType(KTable)).dx - origin, 2 * indent);
      expect(
        tester.getSize(find.byType(KTable)).width,
        tester.getSize(find.byType(KDataTable<Item>)).width - 2 * indent,
      );
    }
    await tester.pumpWidget(frame(table(rows: [items.first], groupIndent: 24)));
    expect(
      tester.getTopLeft(find.byType(KTable)).dx,
      tester.getTopLeft(find.byType(KDataTable<Item>)).dx,
    );
  });
  testWidgets('invalid indent fails even without groups', (tester) async {
    for (final invalid in [-1.0, double.infinity, double.nan]) {
      await tester.pumpWidget(frame(table(groupIndent: invalid)));
      expect(tester.takeException(), isArgumentError);
    }
  });
  testWidgets('narrow indented leaves retain internal horizontal scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(
      frame(
        SizedBox(
          width: 120,
          child: table(
            rows: [items.first],
            groupIndent: 24,
            groups: [
              KDataTableGroup(id: 'group', value: (r) => r.group),
              KDataTableGroup(id: 'sub', value: (r) => r.sub),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(KTable)).width, 72);
    final horizontal = find.byWidgetPredicate(
      (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
    );
    expect(tester.getSize(horizontal).width, 72);
    expect(tester.getSize(find.byType(Table)).width, 160);
    expect(
      tester.getBottomRight(horizontal).dx,
      tester.getBottomRight(find.byType(KDataTable<Item>)).dx,
    );
  });

  testWidgets('stable sorting and filtering preserve source', (tester) async {
    await tester.pumpWidget(
      frame(
        table(
          sort: const KDataTableSort(
            columnId: 'id',
            direction: KDataTableSortDirection.ascending,
          ),
        ),
      ),
    );
    expect(rowIds(tester), ['b', 'd', 'a', 'c']);
    await tester.pumpWidget(
      frame(
        table(
          sort: const KDataTableSort(
            columnId: 'id',
            direction: KDataTableSortDirection.descending,
          ),
          filter: (r) => r.id != 'a',
        ),
      ),
    );
    expect(rowIds(tester), ['c', 'b', 'd']);
    expect(items.map((r) => r.id), ['a', 'b', 'c', 'd']);
  });
  testWidgets('controlled sorting updates without visible headers', (
    tester,
  ) async {
    await tester.pumpWidget(
      frame(
        table(
          sort: const KDataTableSort(
            columnId: 'id',
            direction: KDataTableSortDirection.ascending,
          ),
        ),
      ),
    );
    expect(rowIds(tester), ['b', 'd', 'a', 'c']);
    await tester.pumpWidget(
      frame(
        table(
          sort: const KDataTableSort(
            columnId: 'id',
            direction: KDataTableSortDirection.descending,
          ),
        ),
      ),
    );
    expect(rowIds(tester), ['a', 'c', 'b', 'd']);
    await tester.pumpWidget(frame(table()));
    expect(rowIds(tester), ['a', 'b', 'c', 'd']);
    expect(find.text('Name'), findsNothing);
    expect(find.byType(KButton), findsNothing);
  });
  testWidgets('nested grouping preserves insertion order and sorts leaves', (
    tester,
  ) async {
    await tester.pumpWidget(
      frame(
        table(
          groups: [
            KDataTableGroup(id: 'group', value: (r) => r.group),
            KDataTableGroup(id: 'sub', value: (r) => r.sub),
          ],
          sort: const KDataTableSort(
            columnId: 'id',
            direction: KDataTableSortDirection.ascending,
          ),
        ),
      ),
    );
    expect(rowIds(tester), ['d', 'a', 'c', 'b']);
    expect(find.text('B (3)'), findsOneWidget);
    expect(find.text('x (2)'), findsOneWidget);
    expect(tester.widgetList<KTable>(find.byType(KTable)).map((t) => t.label), [
      'Items / B / x',
      'Items / B / y',
      'Items / A / x',
    ]);
    expect(find.byType(KButton), findsNothing);
  });
  testWidgets('collapse keys include path and callback is controlled', (
    tester,
  ) async {
    Set<String>? requested;
    final original = <String>{};
    final groups = [KDataTableGroup<Item>(id: 'group', value: (r) => r.group)];
    await tester.pumpWidget(
      frame(
        table(
          groups: groups,
          collapsed: original,
          onCollapse: (next) => requested = next,
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    final key = jsonEncode([
      ['group', 'B'],
    ]);
    expect(requested, {key});
    expect(original, isEmpty);
    expect(rowIds(tester), ['a', 'c', 'd', 'b']);
    await tester.pumpWidget(
      frame(
        table(
          groups: groups,
          collapsed: requested!,
          onCollapse: (next) => requested = next,
        ),
      ),
    );
    expect(rowIds(tester), ['b']);
    await tester.tap(find.text('B (3)'));
    expect(requested, isEmpty);
  });
  testWidgets('empty filter keeps external toolbar', (tester) async {
    await tester.pumpWidget(
      frame(
        KDataTable<Item>(
          label: 'Items',
          columns: columns,
          rows: items,
          rowId: (r) => r.id,
          filter: (_) => false,
          empty: const Text('No matches'),
          toolbar: const Text('Filter controls'),
        ),
      ),
    );
    expect(find.text('No matches'), findsOneWidget);
    expect(find.text('Filter controls'), findsOneWidget);
    expect(find.byType(KTable), findsNothing);
  });
  testWidgets('validates duplicate IDs before filtering and invalid sort', (
    tester,
  ) async {
    await tester.pumpWidget(
      frame(table(rows: [items.first, items.first], filter: (_) => false)),
    );
    expect(tester.takeException(), isArgumentError);
    await tester.pumpWidget(
      frame(
        table(
          sort: const KDataTableSort(
            columnId: 'missing',
            direction: KDataTableSortDirection.ascending,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isArgumentError);
  });
  testWidgets(
    'hidden headers preserve accessible cell labels at double scale',
    (tester) async {
      await tester.pumpWidget(
        frame(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: SizedBox(
              width: 120,
              child: KDataTable<Item>(
                label: 'Budget table',
                columns: [
                  KDataTableColumn<Item>(
                    id: 'budget',
                    label: 'Budget',
                    width: 120,
                    cell: (r) => Text('${r.score}'),
                    compare: (a, b) => a.score.compareTo(b.score),
                  ),
                ],
                rows: [items.first],
                rowId: (r) => r.id,
                empty: const SizedBox(),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Budget'), findsNothing);
      final semantics = tester.ensureSemantics();
      await tester.pump();
      expect(find.bySemanticsLabel('Budget'), findsOneWidget);
      semantics.dispose();
    },
  );
  testWidgets('leading button icon keeps a single accessible label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var pressed = false;
    await tester.pumpWidget(
      frame(
        KButton(
          label: 'Action',
          leading: const KIcon(KIconName.arrowUp),
          onPressed: () => pressed = true,
        ),
      ),
    );
    expect(find.bySemanticsLabel('Action'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(KIcon)).dx,
      lessThan(tester.getTopLeft(find.text('Action')).dx),
    );
    await tester.tap(find.text('Action'));
    expect(pressed, isTrue);
    semantics.dispose();
  });
}
