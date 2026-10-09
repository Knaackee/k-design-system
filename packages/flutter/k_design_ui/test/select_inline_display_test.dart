import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets(
    'compact inline select ellipsizes full label with visible dropdown and keyboard selection',
    (tester) async {
      const longTitle = 'Ein sehr langes privates Gespräch mit meinem Agenten';
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 170,
              child: KSelect(
                label: 'Gespräch',
                presentation: KSelectPresentation.inline,
                truncateLabel: true,
                showInlineIndicator: true,
                value: 'first',
                onChanged: (id) => selected = id,
                options: const [
                  KSelectOption(value: 'first', label: longTitle),
                  KSelectOption(value: 'second', label: 'Zweites Gespräch'),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.byType(TextField), findsNothing);
      expect(
        tester.widget<Text>(find.text(longTitle)).overflow,
        TextOverflow.ellipsis,
      );
      final arrow = find.descendant(
        of: find.byType(KSelect),
        matching: find.byWidgetPredicate(
          (widget) => widget is KIcon && widget.name == KIconName.chevronDown,
        ),
      );
      expect(arrow, findsOneWidget);
      expect(
        tester
            .widget<Opacity>(
              find.ancestor(of: arrow, matching: find.byType(Opacity)).first,
            )
            .opacity,
        1,
      );
      await tester.tap(find.text(longTitle));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selected, 'second');
      await tester.tap(find.text('Zweites Gespräch'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(longTitle));
      await tester.pumpAndSettle();
      expect(selected, 'first');
      expect(tester.takeException(), null);
    },
  );
}
