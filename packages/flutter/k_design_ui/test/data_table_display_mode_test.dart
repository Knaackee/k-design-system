import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';

typedef RowItem = ({String id, String title});
const rows = <RowItem>[(id: 'a', title: 'Atlas'), (id: 'b', title: 'Orbit')];
final columns = <KDataTableColumn<RowItem>>[
  KDataTableColumn(
    id: 'title',
    label: 'Title',
    cell: (r) => Text('Edit ${r.title}'),
  ),
  KDataTableColumn(id: 'other', label: 'Other', cell: (r) => Text(r.id)),
];

void main() {
  testWidgets('multi-column table scrolls horizontally by touch drag', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KDataTable<RowItem>(
            label: 'Projects',
            columns: [
              KDataTableColumn(
                id: 'title',
                label: 'Title',
                minWidth: 300,
                cell: (r) => Text(r.title),
              ),
              KDataTableColumn(
                id: 'other',
                label: 'Other',
                minWidth: 300,
                cell: (r) => Text(r.id),
              ),
            ],
            rows: rows,
            rowId: (r) => r.id,
            empty: const Text('Empty'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scroll.position.maxScrollExtent, greaterThan(0));
    await tester.drag(find.text('Atlas'), const Offset(-180, 0));
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, greaterThan(0));
  });
  for (final virtual in [false, true]) {
    testWidgets(
      'single column displays consumer content and invokes row action ($virtual)',
      (tester) async {
        String? opened;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 375,
                child: KDataTable<RowItem>(
                  label: 'Projects',
                  columns: columns,
                  rows: rows,
                  rowId: (r) => r.id,
                  empty: const Text('Empty'),
                  viewport: virtual
                      ? const KDataTableViewport(height: 300)
                      : null,
                  displayMode: KDataTableDisplayMode.singleColumn,
                  singleColumn: KDataTableSingleColumn<RowItem>(
                    columnLabel: 'Project',
                    title: (r) => Text(r.title),
                    leading: (_) => const Icon(Icons.folder),
                    trailing: (_) => const Text('Badge'),
                    semanticsLabel: (r) => 'Open ${r.title}',
                    onActivate: (r) => opened = r.id,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Atlas'), findsOneWidget);
        expect(find.text('Edit Atlas'), findsNothing);
        expect(find.text('Badge'), findsNWidgets(2));
        await tester.tap(find.text('Atlas'));
        await tester.pump();
        expect(opened, 'a');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
