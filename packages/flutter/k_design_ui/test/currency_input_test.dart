import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/src/forms/currency_value.dart';
import 'package:k_design_ui/src/forms/k_currency_input.dart';

void main() {
  test('shared symbols spacing and ISO fallback Unicode goldens', () {
    final examples = [
      (123456, 'EUR', 'de-DE', 2, '1.234,56\u00a0€'),
      (0, 'EUR', 'de-DE', 2, '0,00\u00a0€'),
      (-12345, 'USD', 'en-US', 2, '-\$123.45'),
      (1234, 'JPY', 'ja-JP', 0, '￥1,234'),
      (123456, 'KWD', 'en-US', 3, 'KWD\u00a0123.456'),
      (123456, 'EUR', 'de-DE', 2, '1.234,56\u00a0€'),
      (123456, 'EUR', 'de-DE', 2, '1.234,56\u00a0€'),
      (123456, 'CHF', 'en-US', 2, 'CHF\u00a01,234.56'),
      (123456, 'USD', 'fr-FR', 2, '1\u202f234,56\u00a0\$US'),
      (123456, 'JPY', 'hi-IN', 2, 'JP¥1,234.56'),
    ];
    for (final e in examples) {
      expect(
        formatCurrencyMinorUnits(
          e.$1,
          currency: e.$2,
          locale: e.$3,
          fractionDigits: e.$4,
        ),
        e.$5,
      );
      expect(
        parseCurrencyMinorUnits(
          e.$5,
          currency: e.$2,
          locale: e.$3,
          fractionDigits: e.$4,
        ).value,
        e.$1,
      );
    }
  });
  test(
    'exact localized round trips across fraction scales and safe bounds',
    () {
      for (final locale in ['en_US', 'de_DE', 'fr_FR', 'hi_IN', 'ar_EG']) {
        for (final digits in [0, 2, 3]) {
          for (final value in [
            null,
            0,
            -1,
            1,
            123456789,
            kCurrencyMaxMinorUnits,
            -kCurrencyMaxMinorUnits,
          ]) {
            final text = formatCurrencyMinorUnits(
              value,
              currency: 'EUR',
              locale: locale,
              fractionDigits: digits,
            );
            final parsed = parseCurrencyMinorUnits(
              text,
              currency: 'EUR',
              locale: locale,
              fractionDigits: digits,
            );
            expect(parsed.valid, true, reason: '$locale/$digits/$value: $text');
            expect(parsed.value, value);
          }
        }
      }
    },
  );
  test('paste rejects incomplete, excess fraction, grouping and overflow', () {
    KCurrencyParseResult parse(String text) =>
        parseCurrencyMinorUnits(text, currency: 'EUR', locale: 'de_DE');
    expect(parse('1.234,50 €').value, 123450);
    expect(parse('-0,00').value, 0);
    expect(parse('').valid, true);
    expect(parse('').value, null);
    for (final text in [
      '-',
      '+',
      '1,',
      '1,001',
      '12.34,00',
      'NaN',
      'Infinity',
      '90071992547409,92',
      '€',
      '1e3',
    ]) {
      expect(parse(text).valid, false, reason: text);
    }
    expect(
      () => formatCurrencyMinorUnits(
        kCurrencyMaxMinorUnits + 1,
        currency: 'EUR',
        locale: 'de_DE',
      ),
      throwsArgumentError,
    );
  });
  testWidgets(
    'invalid draft persists; escape restores; outside commits; empty clears',
    (tester) async {
      int? value = 12345;
      final commits = <int?>[];
      final invalid = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, update) => Column(
                children: [
                  KCurrencyInput(
                    value: value,
                    currency: 'EUR',
                    locale: 'de_DE',
                    clearable: true,
                    label: 'Amount',
                    onCommit: (next) {
                      commits.add(next);
                      update(() => value = next);
                    },
                    onInvalidDraft: invalid.add,
                  ),
                  TextButton(
                    onPressed: () =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    child: const Text('Outside'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final field = find.byType(TextField);
      await tester.enterText(field, '-12,345');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(commits, isEmpty);
      expect(invalid, contains('-12,345'));
      expect(tester.widget<TextField>(field).controller!.text, '-12,345');
      await tester.tap(field);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(tester.widget<TextField>(field).controller!.text, '123,45');
      await tester.enterText(field, '-12,34');
      await tester.tap(find.text('Outside'));
      await tester.pump();
      expect(value, -1234);
      await tester.tap(field);
      await tester.enterText(field, '');
      await tester.pump();
      expect(value, null);
    },
  );
  testWidgets('currency changes preserve amount; readonly does not commit', (
    tester,
  ) async {
    final commits = <int?>[];
    Widget frame(String currency) => MaterialApp(
      home: Scaffold(
        body: KCurrencyInput(
          value: 12345,
          currency: currency,
          locale: 'en_US',
          readOnly: true,
          onCommit: commits.add,
        ),
      ),
    );
    await tester.pumpWidget(frame('USD'));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      r'$123.45',
    );
    await tester.pumpWidget(frame('EUR'));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '€123.45',
    );
    await tester.tap(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(commits, isEmpty);
  });
}
