import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/src/data/k_data_table.dart';
import 'package:k_design_ui/src/data/k_data_table_virtual_types.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/src/data/k_data_table_semantics.dart';
import 'package:k_design_ui/src/data/k_editable_cell.dart';
import 'virtual_data_table_test.dart' show frame, table;

Rect globalBounds(SemanticsNode node) {
  var rect = node.rect;
  SemanticsNode? current = node;
  while (current != null) {
    if (current.transform != null) {
      rect = MatrixUtils.transformRect(current.transform!, rect);
    }
    current = current.parent;
  }
  return rect;
}

void main() {
  testWidgets(
    'semantic hit bounds match painted cells before and after both-axis scroll',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        frame(
          Padding(
            padding: const EdgeInsets.only(left: 19, top: 73),
            child: table(
              columns: List.generate(
                8,
                (c) => KDataTableColumn(
                  id: '$c',
                  label: 'Column $c',
                  width: 180,
                  cell: (r) => KEditableCell(
                    label: 'Edit $r/$c',
                    display: Text('Item $r/$c'),
                    editor: const SizedBox(),
                    onEdit: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      void check(String id) {
        final finder = find.byWidgetPredicate(
          (w) => w is KEditableCell && w.label == 'Edit $id',
        );
        final painted = tester.getRect(finder);
        final physical = globalBounds(tester.getSemantics(finder));
        final scale = tester.view.devicePixelRatio;
        final semantic = Rect.fromLTRB(
          physical.left / scale,
          physical.top / scale,
          physical.right / scale,
          physical.bottom / scale,
        );
        expect(semantic.left, closeTo(painted.left, .01));
        expect(semantic.top, closeTo(painted.top, .01));
        expect(semantic.width, closeTo(painted.width, .01));
        expect(semantic.height, closeTo(painted.height, .01));
      }

      check('1/1');
      check('3/1');
      final config = tester
          .widget<KSemanticTableView>(find.byType(KSemanticTableView))
          .configuration;
      config.verticalDetails.controller!.jumpTo(4800);
      config.horizontalDetails.controller!.jumpTo(720);
      await tester.pumpAndSettle();
      check('101/5');
      check('103/5');
      // Repeat semantics assembly without a layout change to catch accumulation.
      await tester.pump();
      check('103/5');
      semantics.dispose();
    },
  );
  testWidgets(
    'default virtual extent preserves scaled editable-cell intrinsic height',
    (tester) async {
      final tokens = kDesignTokens(
        configuration: const KDesignConfiguration(density: KDensity.dense),
      );
      Widget editor(String id) => KEditableCell(
        label: id,
        display: const Text('Project'),
        editor: const SizedBox(),
        onEdit: () {},
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [tokens]),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: Column(
                children: [
                  SizedBox(width: 300, child: editor('Standalone')),
                  SizedBox(
                    width: 300,
                    child: KDataTable<int>(
                      label: 'Items',
                      rows: const [1],
                      rowId: (n) => '$n',
                      columns: [
                        KDataTableColumn(
                          id: 'title',
                          label: 'Title',
                          cell: (_) => editor('Virtual'),
                        ),
                      ],
                      empty: const Text('Empty'),
                      viewport: const KDataTableViewport(height: 200),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final standalone = tester.getSize(
        find.byWidgetPredicate(
          (w) => w is KEditableCell && w.label == 'Standalone',
        ),
      );
      final virtual = tester.getSize(
        find.byWidgetPredicate(
          (w) => w is KEditableCell && w.label == 'Virtual',
        ),
      );
      expect(virtual.height, standalone.height);
    },
  );
}
