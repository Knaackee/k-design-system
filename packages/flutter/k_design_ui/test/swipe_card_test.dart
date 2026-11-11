import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

// Decision 0016: swipe actions on list rows and KCard border effects.
void main() {
  Widget app(
    Widget child, {
    KStyle style = KStyle.apple,
    bool reduced = false,
  }) => MaterialApp(
    home: KAdaptiveTheme(
      fontFamily: 'packages/k_design_tokens/Inter',
      overrides: KAdaptiveOverrides(style: style),
      child: KLocalization(
        locale: 'en',
        child: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 844),
            disableAnimations: reduced,
          ),
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    ),
  );

  Widget row(List<String> log) => SizedBox(
    width: 390,
    child: KListItem(
      title: 'Mara Feld',
      description: 'Termin verschoben',
      onPressed: () => log.add('tap'),
      leadingActions: [
        KSwipeAction(
          id: 'read',
          label: 'Read',
          icon: KIconName.mail,
          tone: KSwipeActionTone.info,
          onSelect: () => log.add('read'),
        ),
      ],
      trailingActions: [
        KSwipeAction(
          id: 'flag',
          label: 'Flag',
          icon: KIconName.flag,
          tone: KSwipeActionTone.warning,
          onSelect: () => log.add('flag'),
        ),
        KSwipeAction(
          id: 'delete',
          label: 'Delete',
          icon: KIconName.trash,
          tone: KSwipeActionTone.destructive,
          fullSwipe: true,
          onSelect: () => log.add('delete'),
        ),
      ],
    ),
  );

  testWidgets('Apple: a short swipe opens the buttons, a long one deletes', (
    tester,
  ) async {
    final log = <String>[];
    await tester.pumpWidget(app(row(log)));
    await tester.drag(find.text('Mara Feld'), const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(find.text('Flag'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    await tester.tap(find.text('Flag'));
    await tester.pumpAndSettle();
    expect(log, ['flag']);
    await tester.drag(find.text('Mara Feld'), const Offset(-330, 0));
    await tester.pumpAndSettle();
    expect(log, ['flag', 'delete']);
  });

  testWidgets('Material: past the threshold the first action runs', (
    tester,
  ) async {
    final log = <String>[];
    await tester.pumpWidget(app(row(log), style: KStyle.material));
    await tester.drag(find.text('Mara Feld'), const Offset(80, 0));
    await tester.pumpAndSettle();
    expect(log, isEmpty, reason: 'under the threshold the row springs back');
    await tester.drag(find.text('Mara Feld'), const Offset(200, 0));
    await tester.pumpAndSettle();
    expect(log, ['read']);
  });

  testWidgets('Linear: no swipe, the actions are inline and announced', (
    tester,
  ) async {
    final log = <String>[];
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(app(row(log), style: KStyle.linear));
    await tester.drag(find.text('Mara Feld'), const Offset(-330, 0));
    await tester.pumpAndSettle();
    expect(log, isEmpty);
    expect(find.byTooltip('Delete'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('KCard: header, menu and every border effect render', (
    tester,
  ) async {
    for (final border in KCardBorder.values) {
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 320,
            child: KCard(
              title: 'Rocky',
              description: 'Agent',
              menu: const [KMenuAction(id: 'edit', label: 'Edit')],
              border: border,
              borderDuration: const Duration(milliseconds: 600),
              actions: [KButton(label: 'Open', onPressed: () {})],
              child: const Text('Body'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: '$border');
      expect(find.text('Rocky'), findsOneWidget);
      expect(find.byType(KMenuButton), findsOneWidget);
    }
  });

  testWidgets('KCard: reduced motion keeps the border still', (tester) async {
    await tester.pumpWidget(
      app(
        const SizedBox(
          width: 320,
          child: KCard(border: KCardBorder.spin, child: Text('Body')),
        ),
        reduced: true,
      ),
    );
    // pumpAndSettle times out while an animation repeats.
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsOneWidget);
  });
}
