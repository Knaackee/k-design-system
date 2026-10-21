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
  testWidgets('wide conversation popup at 360dp and 1.15 text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const title =
        'Ein sehr langes Gespräch über alle offenen Aufgaben und Fehler';
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(configuration: KDesignConfiguration.mobileApp),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.15)),
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 80,
              child: KSelect(
                label: 'Gespräch',
                value: 'one',
                truncateLabel: true,
                expandedPopup: true,
                presentation: KSelectPresentation.inline,
                onChanged: (value) => selected = value,
                options: const [
                  KSelectOption(
                    value: 'one',
                    label: title,
                    description: '21.10.2026 · 17:30',
                  ),
                  KSelectOption(
                    value: 'two',
                    label: 'Zweites Gespräch',
                    description: '20.10.2026 · 10:00',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
    final popup = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == 'KSelectionPopup',
    );
    expect(tester.getRect(popup).width, 344);
    expect(tester.getRect(popup).left, 8);
    final option = tester.widget<Text>(
      find.descendant(of: popup, matching: find.text(title)),
    );
    expect(option.maxLines, 1);
    expect(option.overflow, TextOverflow.ellipsis);
    expect(find.text('21.10.2026 · 17:30'), findsOneWidget);
    await tester.tap(find.text('Zweites Gespräch'));
    await tester.pumpAndSettle();
    expect(selected, 'two');
    expect(popup, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
