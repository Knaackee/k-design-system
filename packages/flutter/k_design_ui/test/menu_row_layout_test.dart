import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final contextMenu in [false, true]) {
    testWidgets(
      '${contextMenu ? 'context' : 'button'} rows align labels, indicators and full highlight width',
      (tester) async {
        tester.view.physicalSize = const Size(390, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final actions = [
          KMenuAction(
            id: 'copy',
            label: 'Issue-ID kopieren',
            iconContent: const Icon(Icons.copy, size: 48),
            onSelect: () {},
          ),
          KMenuAction(
            id: 'checked',
            label: 'Hoch',
            checked: true,
            icon: KIconName.copy,
            onSelect: () {},
          ),
          KMenuAction(
            id: 'unchecked',
            label: 'Niedrig',
            checked: false,
            onSelect: () {},
          ),
          KMenuAction(
            id: 'properties',
            label: 'Weitere Eigenschaften',
            children: [
              KMenuAction(id: 'child', label: 'Projekt', onSelect: () {}),
            ],
          ),
        ];
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(),
            home: Scaffold(
              body: contextMenu
                  ? KContextMenu(
                      label: 'Actions',
                      actions: actions,
                      child: const SizedBox(
                        width: 100,
                        height: 60,
                        child: Text('Target'),
                      ),
                    )
                  : KMenuButton(label: 'Actions', actions: actions),
            ),
          ),
        );
        if (contextMenu) {
          await tester.longPress(find.text('Target'));
        } else {
          await tester.tap(find.text('Actions'));
        }
        await tester.pumpAndSettle();
        final rects = [
          for (final id in ['copy', 'checked', 'unchecked', 'properties'])
            tester.getRect(find.byKey(ValueKey(id))),
        ];
        for (final rect in rects) {
          expect(rect.left, closeTo(rects.first.left, .1));
          expect(rect.width, closeTo(rects.first.width, .1));
          expect(rect.right, lessThanOrEqualTo(390));
        }
        final labelLeft = tester.getRect(find.text('Hoch')).left;
        for (final text in [
          'Issue-ID kopieren',
          'Niedrig',
          'Weitere Eigenschaften',
        ]) {
          expect(tester.getRect(find.text(text)).left, closeTo(labelLeft, .1));
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(text),
          );
          expect(
            paragraph.getBoxesForSelection(
              TextSelection(baseOffset: 0, extentOffset: text.length),
            ),
            hasLength(1),
          );
        }
        final check = find.byWidgetPredicate(
          (widget) => widget is KIcon && widget.name == KIconName.check,
        );
        final arrow = find.byWidgetPredicate(
          (widget) => widget is KIcon && widget.name == KIconName.chevronRight,
        );
        expect(
          tester.getRect(check).left,
          closeTo(tester.getRect(arrow).left, .1),
        );
        expect(tester.getRect(check).size, tester.getRect(arrow).size);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
