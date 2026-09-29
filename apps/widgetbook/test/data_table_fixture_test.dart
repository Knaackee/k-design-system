import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/data_table_fixtures.dart';

Future<void> mount(
  WidgetTester tester, {
  bool grouped = false,
  DataTableFixture? fixture,
}) async {
  tester.view.physicalSize = const Size(1024, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: kDesignTheme(),
      home: Scaffold(body: fixture ?? DataTableFixture(grouped: grouped)),
    ),
  );
  await tester.pumpAndSettle();
}

Finder button(String label) => find.byWidgetPredicate(
  (widget) => widget is KButton && widget.label == label,
);
Finder titleField(String id) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is KInput && widget.label == 'Title for $id',
  ),
  matching: find.byType(TextField),
);
Finder titleValue(String value) => find.text(value);
Finder editTitle(String id) => find.byWidgetPredicate(
  (widget) => widget is KEditableCell && widget.label == 'Edit title for $id',
);
void main() {
  testWidgets('header text aligns with editable title and numeric cell edges', (
    tester,
  ) async {
    await mount(tester, fixture: const DataTableFixture(showHeader: true));
    expect(
      tester.getTopLeft(find.text('Project')).dx,
      closeTo(tester.getTopLeft(find.text('Atlas website')).dx, 1),
    );
    expect(
      tester.getTopRight(find.text('Budget')).dx,
      closeTo(
        tester
            .getTopRight(
              find.text(
                formatCurrencyMinorUnits(
                  12000,
                  currency: 'EUR',
                  locale: 'de-DE',
                  fractionDigits: 0,
                ),
              ),
            )
            .dx,
        1,
      ),
    );
    final header = tester.widget<KButton>(button('Project'));
    expect(header.leading, isNull);
    expect(header.trailing, isA<KIcon>());
  });
  Finder draftStatus() =>
      find.byWidgetPredicate((w) => w is KSelect && w.label == 'Status for ');
  testWidgets(
    'same row pointer transfer keeps draft and selected status survives row exit',
    (tester) async {
      await mount(tester);
      await tester.tap(button('Add project'));
      await tester.pumpAndSettle();
      await tester.tap(draftStatus());
      await tester.pumpAndSettle();
      expect(editTitle('new-1'), findsOneWidget);
      expect(titleField('new-1'), findsNothing);
      await tester.tap(find.text('Done').last);
      await tester.pumpAndSettle();
      expect(tester.widget<KSelect>(draftStatus()).value, 'done');
      await tester.tap(find.byType(KSearchField));
      await tester.pumpAndSettle();
      expect(editTitle('new-1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('popup Escape keeps unchanged row until pointer leaves row', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(button('Add project'));
    await tester.pumpAndSettle();
    await tester.tap(draftStatus());
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(editTitle('new-1'), findsOneWidget);
    await tester.tap(find.byType(KSearchField));
    await tester.pumpAndSettle();
    expect(editTitle('new-1'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Tab within row keeps draft and Tab outside removes unchanged row',
    (tester) async {
      await mount(tester);
      await tester.tap(button('Add project'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(editTitle('new-1'), findsOneWidget);
      final selectField = find.descendant(
        of: draftStatus(),
        matching: find.byType(TextField),
      );
      // KSelect's outer keyboard target and TextField both belong to this row.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(selectField).focusNode!.hasFocus, isTrue);
      expect(editTitle('new-1'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      // Budget is another focusable cell in the same row.
      expect(editTitle('new-1'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(editTitle('new-1'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'budget cell is inside row and later outside click removes draft',
    (tester) async {
      await mount(tester);
      await tester.tap(button('Add project'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is KEditableCell && w.label == 'Edit budget for new-1',
        ),
      );
      await tester.pumpAndSettle();
      expect(editTitle('new-1'), findsOneWidget);
      await tester.tap(find.text('Project workspace').first);
      await tester.pumpAndSettle();
      expect(editTitle('new-1'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  for (final grouped in [false, true]) {
    testWidgets(
      'new draft focuses empty title and Escape removes unchanged ($grouped)',
      (tester) async {
        await mount(tester, grouped: grouped);
        await tester.tap(button('Add project').first);
        await tester.pumpAndSettle();
        final field = tester.widget<TextField>(titleField('new-1'));
        expect(field.controller!.text, '');
        expect(field.focusNode!.hasFocus, isTrue);
        if (grouped) {
          expect(button('In progress (4)'), findsOneWidget);
          expect(button('Web (3)'), findsOneWidget);
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(editTitle('new-1'), findsNothing);
        if (grouped) expect(button('Web (2)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'blur removes unchanged draft but preserves changed draft ($grouped)',
      (tester) async {
        await mount(tester, grouped: grouped);
        await tester.tap(button('Add project').first);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(KSearchField));
        await tester.pumpAndSettle();
        expect(editTitle('new-1'), findsNothing);
        await tester.tap(button('Add project').first);
        await tester.pumpAndSettle();
        await tester.enterText(titleField('new-2'), 'Created by consumer');
        await tester.tap(find.byType(KSearchField));
        await tester.pumpAndSettle();
        expect(titleField('new-2'), findsNothing);
        expect(find.text('Created by consumer'), findsOneWidget);
        await tester.tap(button('Add project').first);
        await tester.pumpAndSettle();
        await tester.enterText(titleField('new-3'), 'Retained on Escape');
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('Retained on Escape'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('pending draft remains visible under an active search', (
    tester,
  ) async {
    await mount(tester);
    await tester.enterText(find.byType(TextField).first, 'Alex');
    await tester.pumpAndSettle();
    await tester.tap(button('Add project'));
    await tester.pumpAndSettle();
    expect(titleField('new-1'), findsOneWidget);
    expect(
      tester.widget<TextField>(titleField('new-1')).focusNode!.hasFocus,
      isTrue,
    );
  });
  testWidgets(
    'consumer configures add label and all defaults; non-title change retains row',
    (tester) async {
      await mount(
        tester,
        fixture: DataTableFixture(
          addLabel: 'Create task',
          createProject: (id, section) => (
            id: id,
            title: 'Template',
            owner: 'Consumer',
            budget: 123,
            status: 'planned',
            platform: 'Web',
          ),
        ),
      );
      expect(button('Add project'), findsNothing);
      await tester.tap(button('Create task'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(titleField('new-1')).controller!.text,
        'Template',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(editTitle('new-1'), findsNothing);
      await tester.tap(button('Create task'));
      await tester.pumpAndSettle();
      final status = tester.widget<KSelect>(
        find.byWidgetPredicate(
          (w) => w is KSelect && w.label == 'Status for Template',
        ),
      );
      status.onChanged!('active');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(editTitle('new-2'), findsNothing);
      expect(find.text('Template'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'title edits retain focus, selection and state across sorting filtering and collapse',
    (tester) async {
      await mount(tester, grouped: true);
      await tester.tap(find.byType(KMenuButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Project ascending'));
      await tester.pumpAndSettle();
      expect(titleField('atlas'), findsNothing);
      await tester.tap(editTitle('atlas'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(titleField('atlas')).focusNode!.hasFocus,
        isTrue,
      );
      for (final value in ['Z', 'Ze', 'Zeta website']) {
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: value,
            selection: TextSelection.collapsed(offset: value.length),
          ),
        );
        await tester.pumpAndSettle();
        final field = tester.widget<TextField>(titleField('atlas'));
        expect(field.focusNode!.hasFocus, isTrue);
        expect(field.controller!.selection.baseOffset, value.length);
      }
      expect(
        tester.widget<KTable>(find.byType(KTable).first).rows.first.id,
        'atlas',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(titleField('atlas'), findsNothing);
      final table = tester.widget<KTable>(find.byType(KTable).first);
      expect(table.rows.map((row) => row.id), ['docs', 'atlas']);
      final group = find.byWidgetPredicate(
        (widget) =>
            widget is KButton &&
            widget.label.startsWith('Web') &&
            widget.label.contains('2'),
      );
      await tester.tap(group);
      await tester.pumpAndSettle();
      expect(titleField('atlas'), findsNothing);
      await tester.tap(group);
      await tester.pumpAndSettle();
      expect(titleValue('Zeta website'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Zeta');
      await tester.pumpAndSettle();
      expect(editTitle('atlas'), findsOneWidget);
      expect(editTitle('docs'), findsNothing);
      await tester.tap(button('Reset all'));
      await tester.pumpAndSettle();
      expect(titleValue('Zeta website'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'first click edits, Escape cancels, blur commits and icon acts separately',
    (tester) async {
      await mount(tester);
      await tester.tap(editTitle('atlas'));
      await tester.pumpAndSettle();
      await tester.enterText(titleField('atlas'), 'Discarded');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(titleValue('Atlas website'), findsOneWidget);
      expect(titleValue('Discarded'), findsNothing);
      await tester.tap(editTitle('atlas'));
      await tester.pumpAndSettle();
      await tester.enterText(titleField('atlas'), 'Updated website');
      await tester.tap(find.byType(KSearchField));
      await tester.pumpAndSettle();
      expect(titleField('atlas'), findsNothing);
      expect(titleValue('Updated website'), findsOneWidget);
      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is KIconButton && widget.label == 'Open atlas',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Open: Updated website'), findsOneWidget);
      expect(titleField('atlas'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('filters combine and reset without reverting edited cells', (
    tester,
  ) async {
    await mount(tester);
    expect(tester.widget<KButton>(button('Reset all')).onPressed, isNull);
    await tester.enterText(find.byType(TextField).first, 'Alex');
    await tester.pumpAndSettle();
    expect(titleValue('Atlas website'), findsOneWidget);
    expect(titleValue('Customer portal'), findsOneWidget);
    expect(titleValue('Orbit mobile app'), findsNothing);
    await tester.tap(find.byType(KSelect).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done').last);
    await tester.pumpAndSettle();
    expect(find.text('No matching projects'), findsOneWidget);
    await tester.tap(button('Reset all'));
    await tester.pumpAndSettle();
    expect(titleValue('Orbit mobile app'), findsOneWidget);
    await tester.tap(find.byType(KSelect).at(1));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == 'Planned',
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'missing');
    await tester.pumpAndSettle();
    await tester.tap(button('Reset all'));
    await tester.pumpAndSettle();
    expect(tester.widget<KSelect>(find.byType(KSelect).at(1)).value, 'planned');
    expect(tester.takeException(), isNull);
  });
  testWidgets('sort cycles and nested groups collapse independently', (
    tester,
  ) async {
    await mount(tester);
    List<String> rowIds() => tester
        .widget<KTable>(find.byType(KTable).first)
        .rows
        .map((row) => row.id)
        .toList();
    await tester.tap(find.byType(KMenuButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Budget ascending'));
    await tester.pumpAndSettle();
    expect(rowIds().first, 'audit');
    await tester.tap(find.byType(KMenuButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Budget descending'));
    await tester.pumpAndSettle();
    expect(rowIds().first, 'atlas');
    await tester.tap(find.byType(KMenuButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Original order'));
    await tester.pumpAndSettle();
    expect(rowIds()[1], 'orbit');
    await tester.pumpWidget(const SizedBox.shrink());
    await mount(tester, grouped: true);
    final groupButton = find.byWidgetPredicate(
      (widget) =>
          widget is KButton &&
          widget.label.startsWith('Web') &&
          widget.label.contains('2'),
    );
    expect(groupButton, findsOneWidget);
    await tester.tap(groupButton);
    await tester.pumpAndSettle();
    expect(titleValue('Atlas website'), findsNothing);
    expect(titleValue('Offline sync'), findsOneWidget);
    expect(titleValue('Customer portal'), findsOneWidget);
    await tester.tap(groupButton);
    await tester.pumpAndSettle();
    expect(titleValue('Atlas website'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
