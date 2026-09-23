import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('opening builds only the visible emoji rows', (tester) async {
    final built = <String>{};
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: KEmojiPicker(
            onSelect: (_) {},
            itemBuilder: (_, item) {
              built.add(item.id);
              return const SizedBox(width: 24, height: 24);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    final prepared = tester.widget<TextField>(
      find.byType(TextField, skipOffstage: false),
    );
    expect(prepared.focusNode!.hasFocus, isFalse);
    expect(built, isNotEmpty);
    await tester.tap(find.bySemanticsLabel('Choose emoji').first);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // Six visible rows of seven cells plus the category thumbnails.
    expect(built.length, lessThanOrEqualTo(55));
    await tester.enterText(find.byType(TextField), 'smile');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(prepared.focusNode!.hasFocus, isFalse);
    await tester.tap(find.bySemanticsLabel('Choose emoji').first);
    await tester.pumpAndSettle();
    final reopened = tester.widget<TextField>(find.byType(TextField));
    expect(identical(prepared.controller, reopened.controller), isTrue);
    expect(reopened.controller!.text, 'smile');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'icon search filters and returns consumer item; disabled items cannot select',
    (tester) async {
      KSymbolItem? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: KIconPicker(
              onSelect: (item) => selected = item,
              items: const [
                KSymbolItem(
                  id: 'one',
                  label: 'Star',
                  category: 'Shapes',
                  icon: KIconName.star,
                ),
                KSymbolItem(
                  id: 'two',
                  label: 'Locked',
                  category: 'Shapes',
                  icon: KIconName.lock,
                  disabled: true,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Choose icon').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'star');
      await tester.pumpAndSettle();
      expect(find.byTooltip('Locked'), findsNothing);
      final starTarget = find.descendant(
        of: find.byTooltip('Star'),
        matching: find.byType(GestureDetector),
      );
      Focus.of(tester.element(starTarget)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(selected?.id, 'one');
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Choose icon').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'locked');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Locked'));
      expect(selected?.id, 'one');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'emoji selection returns chosen skin tone and recent IDs filter',
    (tester) async {
      final item = kEmojiCatalog.firstWhere((e) => e.tones.length == 5);
      KSymbolItem? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: KEmojiPicker(
              items: [item],
              skinTone: 3,
              recentIds: [item.id],
              onSelect: (value) => selected = value,
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Choose emoji').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Recent'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(item.label));
      expect(selected?.value, item.tones[2].value);
      expect(selected?.id, item.id);
      expect(tester.takeException(), isNull);
    },
  );
}
