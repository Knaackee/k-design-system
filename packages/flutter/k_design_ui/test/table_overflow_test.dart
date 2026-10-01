import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';

Widget frame(Widget child) => MaterialApp(
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 220, child: child),
    ),
  ),
);
const longText = 'Wohnquartier Am Sonnenhang mit langem Namen';

void main() {
  testWidgets(
    'virtual visible overrides inherited ellipsis while wrap stays one line',
    (tester) async {
      for (final overflow in [
        KTableTextOverflow.visible,
        KTableTextOverflow.wrap,
      ]) {
        await tester.pumpWidget(
          frame(
            KDataTable<int>(
              label: 'Virtual overflow',
              columns: [
                KDataTableColumn(
                  id: 'name',
                  label: 'Name',
                  width: 220,
                  overflow: overflow,
                  cell: (_) => const Text(longText),
                ),
              ],
              rows: const [1],
              rowId: (value) => '$value',
              empty: const Text('Empty'),
              viewport: const KDataTableViewport(height: 120, rowHeight: 48),
            ),
          ),
        );
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(longText),
        );
        expect(paragraph.maxLines, 1);
        expect(paragraph.softWrap, isFalse);
        expect(
          paragraph.overflow,
          overflow == KTableTextOverflow.visible
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
        );
        expect(
          find.byTooltip(longText),
          overflow == KTableTextOverflow.visible
              ? findsNothing
              : findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'button tooltip follows its existing keyboard focus without another stop',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        frame(KButton(label: longText, onPressed: () => taps++)),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(find.text(longText), findsNWidgets(2));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'text truncates, retains semantics and reveals on focus, hover and touch',
    (tester) async {
      await tester.pumpWidget(
        frame(
          const KTable(
            label: 'Properties',
            columns: [
              KTableColumn(id: 'name', header: Text('Name'), width: 220),
            ],
            rows: [
              KTableRow(id: '1', cells: [Text(longText)]),
            ],
          ),
        ),
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text(longText),
      );
      expect(paragraph.maxLines, 1);
      expect(paragraph.overflow, TextOverflow.ellipsis);
      expect(paragraph.didExceedMaxLines, isTrue);
      expect(find.byTooltip(longText), findsOneWidget);
      expect(find.byTooltip('Name'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(find.text(longText), findsNWidgets(2));
      FocusManager.instance.primaryFocus?.unfocus();
      Tooltip.dismissAllToolTips();
      await tester.pumpAndSettle();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text(longText)));
      await tester.pumpAndSettle();
      expect(find.text(longText), findsNWidgets(2));
      await mouse.removePointer();
      Tooltip.dismissAllToolTips();
      await tester.pumpAndSettle();
      await tester.longPress(find.text(longText));
      await tester.pumpAndSettle();
      expect(find.text(longText), findsNWidgets(2));
    },
  );

  testWidgets(
    'column wrap grows rows, visible preserves text and custom controls',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        frame(
          KTable(
            label: 'Properties',
            columns: const [
              KTableColumn(
                id: 'name',
                header: Text('Long header always one line'),
                width: 100,
                overflow: KTableTextOverflow.wrap,
              ),
              KTableColumn(
                id: 'action',
                header: Text('Action'),
                width: 120,
                overflow: KTableTextOverflow.visible,
              ),
            ],
            rows: [
              KTableRow(
                id: '1',
                cells: [
                  const Text(longText),
                  TextButton(
                    onPressed: () => taps++,
                    child: const Text('Open'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text(longText),
      );
      expect(paragraph.maxLines, isNull);
      expect(paragraph.size.height, greaterThan(40));
      expect(
        tester
            .renderObject<RenderParagraph>(
              find.text('Long header always one line'),
            )
            .maxLines,
        1,
      );
      await tester.tap(find.text('Open'));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('button label truncates and leaves icons and loading intact', (
    tester,
  ) async {
    for (final loading in [false, true]) {
      await tester.pumpWidget(
        frame(
          KButton(
            label: longText,
            loading: loading,
            leading: const Icon(Icons.home),
            trailing: const Icon(Icons.arrow_forward),
            onPressed: () {},
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester
            .renderObject<RenderParagraph>(find.text(longText))
            .didExceedMaxLines,
        isTrue,
      );
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(
        find.byType(CircularProgressIndicator),
        loading ? findsOneWidget : findsNothing,
      );
    }
  });
}
