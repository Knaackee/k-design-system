import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('empty group labels reserve no header space', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: KRadioGroup<String>(
            label: '',
            value: 'a',
            onChanged: (_) {},
            items: const [KRadioOption(value: 'a', label: 'A')],
          ),
        ),
      ),
    );
    final group = tester.getRect(find.byType(KRadioGroup<String>));
    final option = tester.getRect(find.byType(RawRadio<String>));
    expect(group.top, option.top);
    expect(group.height, option.height);
  });

  testWidgets('radio labels select and disabled choices do not', (
    tester,
  ) async {
    String? selected = 'email';
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => KRadioGroup<String>(
              label: 'Notifications',
              value: selected,
              onChanged: (value) => setState(() => selected = value),
              items: const [
                KRadioOption(value: 'email', label: 'Email'),
                KRadioOption(value: 'push', label: 'Push'),
                KRadioOption(value: 'sms', label: 'SMS', disabled: true),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Push'));
    await tester.pump();
    expect(selected, 'push');
    await tester.tap(find.text('SMS'));
    await tester.pump();
    expect(selected, 'push');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(selected, 'email');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(selected, 'push');
  });

  testWidgets('controlled null and disabled group retain consumer value', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const Scaffold(
          body: KRadioGroup<String>(
            label: 'Read only',
            value: null,
            onChanged: null,
            horizontal: true,
            items: [
              KRadioOption(value: 'a', label: 'A'),
              KRadioOption(value: 'b', label: 'B'),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('A'));
    await tester.pump();
    final radios = tester.widgetList<RawRadio<String>>(
      find.byType(RawRadio<String>),
    );
    expect(radios.every((radio) => !radio.enabled), isTrue);
    expect(tester.takeException(), isNull);
  });
}
