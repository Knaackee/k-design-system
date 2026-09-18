import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/forms/selection_popup.dart';
import 'package:k_design_widgetbook/data_table_fixtures.dart';
import 'data_table_fixture_test.dart' as helpers;

void main() {
  Finder status() =>
      find.byWidgetPredicate((w) => w is KSelect && w.label == 'Status for ');
  testWidgets(
    'group change is pinned until Enter confirms then Escape cannot delete saved row',
    (tester) async {
      await helpers.mount(tester, grouped: true);
      await tester.tap(helpers.button('Add project').first);
      await tester.pumpAndSettle();
      await tester.tap(status());
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(KSelectionPopup),
          matching: find.text('Done'),
        ),
      );
      await tester.pumpAndSettle();
      expect(helpers.button('In progress (4)'), findsOneWidget);
      expect(helpers.button('Done (1)'), findsOneWidget);
      expect(find.text('new-1: dirty'), findsOneWidget);
      await tester.tap(helpers.editTitle('new-1'));
      await tester.pumpAndSettle();
      await tester.enterText(helpers.titleField('new-1'), 'New saved project');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(helpers.button('In progress (3)'), findsOneWidget);
      expect(helpers.button('Done (2)'), findsOneWidget);
      expect(find.text('New saved project'), findsOneWidget);
      await tester.tap(helpers.editTitle('new-1'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(helpers.editTitle('new-1'), findsOneWidget);
    },
  );
  testWidgets(
    'save is coalesced, pending cannot cancel, failure retains and retry succeeds',
    (tester) async {
      var calls = 0;
      var pending = Completer<DataTableProject>();
      await helpers.mount(
        tester,
        fixture: DataTableFixture(
          saveProject: (row) {
            calls++;
            return pending.future;
          },
        ),
      );
      await tester.tap(helpers.button('Add project'));
      await tester.pumpAndSettle();
      await tester.enterText(helpers.titleField('new-1'), 'Retained');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.text('new-1: saving'), findsOneWidget);
      expect(
        tester.widget<KButton>(helpers.button('Cancel new-1')).onPressed,
        isNull,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(helpers.editTitle('new-1'), findsOneWidget);
      pending.completeError(StateError('Offline'));
      await tester.pumpAndSettle();
      expect(find.text('new-1: error'), findsOneWidget);
      expect(find.text('Retained'), findsOneWidget);
      pending = Completer<DataTableProject>();
      await tester.tap(helpers.button('Save new-1'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      pending.complete((
        id: 'new-1',
        title: 'Retained',
        owner: 'You',
        budget: 0,
        status: 'planned',
        platform: 'Web',
      ));
      await tester.pumpAndSettle();
      expect(helpers.button('Save new-1'), findsNothing);
      expect(find.text('Retained'), findsOneWidget);
    },
  );
  testWidgets('save action belongs to row and can commit pristine defaults', (
    tester,
  ) async {
    await helpers.mount(tester);
    await tester.tap(helpers.button('Add project'));
    await tester.pumpAndSettle();
    await tester.tap(helpers.button('Save new-1'));
    await tester.pumpAndSettle();
    expect(helpers.editTitle('new-1'), findsOneWidget);
    expect(helpers.button('Save new-1'), findsNothing);
    expect(find.text('committed: new-1 (action)'), findsOneWidget);
  });
  testWidgets(
    'consumer chooses status as initial focused cell and can omit Add action',
    (tester) async {
      await helpers.mount(
        tester,
        fixture: const DataTableFixture(initialEditColumn: 'status'),
      );
      await tester.tap(helpers.button('Add project'));
      await tester.pumpAndSettle();
      expect(helpers.titleField('new-1'), findsNothing);
      final focused = FocusManager.instance.primaryFocus;
      expect(focused, isNotNull);
      final statusElement = tester.element(status());
      var inside = false;
      focused!.context?.visitAncestorElements((e) {
        if (e == statusElement) inside = true;
        return true;
      });
      expect(inside, true);
      await helpers.mount(
        tester,
        fixture: const DataTableFixture(allowAdd: false),
      );
      await tester.pumpAndSettle();
      expect(helpers.button('Add project'), findsNothing);
    },
  );
}
