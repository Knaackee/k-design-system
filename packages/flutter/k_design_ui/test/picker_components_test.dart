import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/pickers/picker_model.dart';
import 'package:k_design_ui/src/pickers/picker_types.dart';

PickerModel model({
  PickerKind kind = PickerKind.dateTime,
  String zone = 'Europe/Berlin',
  KDateFormat date = KDateFormat.iso,
  KTimeFormat time = KTimeFormat.h24,
  KTimeDisambiguation disambiguation = KTimeDisambiguation.reject,
  String? min,
  String? max,
}) => PickerModel(
  kind: kind,
  timeZone: zone,
  dateFormat: date,
  timeFormat: time,
  disambiguation: disambiguation,
  min: min,
  max: max,
);
void main() {
  test('date parsing validates Gregorian leap days and formats', () {
    expect(parseDate('2024-2-29', KDateFormat.iso), DateTime.utc(2024, 2, 29));
    expect(parseDate('2026-02-29', KDateFormat.iso), isNull);
    expect(parseDate('31.04.2026', KDateFormat.dayMonthYear), isNull);
    expect(
      formatDate(
        parseDate('2/9/2026', KDateFormat.monthDayYear)!,
        KDateFormat.iso,
      ),
      '2026-02-09',
    );
    expect(parseDate('0000-01-01', KDateFormat.iso), isNull);
  });
  test('time formats reject normalization and support AM PM', () {
    expect(timeIso(parseTime('12:00 AM', KTimeFormat.h12)!), '00:00');
    expect(timeIso(parseTime('1:35 pm', KTimeFormat.h12)!), '13:35');
    expect(
      formatTime(DateTime.utc(2000, 1, 1, 0, 15), KTimeFormat.h12),
      '12:15 AM',
    );
    for (final value in ['24:00', '23:60', '-1:00']) {
      expect(parseTime(value, KTimeFormat.h24), isNull);
    }
    expect(parseTime('00:00 PM', KTimeFormat.h12), isNull);
  });
  test('Berlin DST gap rejects and overlap requires explicit policy', () {
    expect(model().fromParts('2026-03-29', '02:30').error, 'nonexistent');
    expect(model().fromParts('2026-10-25', '02:30').error, 'ambiguous');
    expect(
      model(
        disambiguation: KTimeDisambiguation.earlier,
      ).fromParts('2026-10-25', '02:30').value,
      '2026-10-25T00:30:00.000Z',
    );
    expect(
      model(
        disambiguation: KTimeDisambiguation.later,
      ).fromParts('2026-10-25', '02:30').value,
      '2026-10-25T01:30:00.000Z',
    );
  });
  test('timezone conversion preserves instant and context today', () {
    expect(model().display('2026-09-16T10:00:00Z'), '2026-09-16 12:00');
    expect(
      model(zone: 'America/New_York').display('2026-09-16T10:00:00.000Z'),
      '2026-09-16 06:00',
    );
    expect(
      dateIso(
        model(zone: 'Pacific/Kiritimati').today(DateTime.utc(2026, 9, 16, 12)),
      ),
      '2026-09-17',
    );
    expect(() => model(zone: 'Not/AZone'), throwsArgumentError);
  });
  test('canonical minute precision and bounds validation', () {
    expect(parseInstant('2026-09-16T10:00:01Z'), isNull);
    expect(parseInstant('2026-09-16T10:00:00.001Z'), isNull);
    expect(parseInstant('2026-02-30T10:00:00Z'), isNull);
    expect(
      model(
        min: '2026-09-16T10:00:00Z',
        max: '2026-09-16T12:00:00Z',
      ).fromParts('2026-09-16', '11:59').error,
      'outOfRange',
    );
    expect(
      model(
        min: '2026-09-16T10:00:00Z',
        max: '2026-09-16T12:00:00Z',
      ).fromParts('2026-09-16', '12:00').value,
      '2026-09-16T10:00:00.000Z',
    );
    expect(
      () => model(kind: PickerKind.date, min: '2026-2-01'),
      throwsArgumentError,
    );
    expect(
      () => model(kind: PickerKind.time, min: '18:00', max: '08:00'),
      throwsArgumentError,
    );
  });
  Future<void> mount(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(body: SizedBox(width: 360, child: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'manual invalid date stays draft and Enter commits normalized value',
    (tester) async {
      String? value = '2026-09-16';
      await mount(
        tester,
        StatefulBuilder(
          builder: (context, setState) => KDatePicker(
            allowTextInput: true,
            value: value,
            onChanged: (next) => setState(() => value = next),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '2026-02-30');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(value, '2026-09-16');
      expect(find.text('Enter a valid date and time.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '2024-2-29');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(value, '2024-02-29');
      expect(find.text('2024-02-29'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(value, isNull);
    },
  );
  testWidgets('dialog cancel Escape and clear restore stable trigger focus', (
    tester,
  ) async {
    String? value = '2026-09-16';
    await mount(
      tester,
      StatefulBuilder(
        builder: (context, setState) => KDatePicker(
          allowTextInput: true,
          value: value,
          onChanged: (next) => setState(() => value = next),
          clearable: true,
        ),
      ),
    );
    await open(tester);
    await tester.enterText(find.byType(TextField).last, '2027-01-01');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(value, '2026-09-16');
    expect(
      tester
          .widget<FilledButton>(find.byType(FilledButton))
          .focusNode!
          .hasFocus,
      isTrue,
    );
    await open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Apply'), findsNothing);
    expect(value, '2026-09-16');
    await open(tester);
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(value, isNull);
    expect(
      tester
          .widget<FilledButton>(find.byType(FilledButton))
          .focusNode!
          .hasFocus,
      isTrue,
    );
  });
  testWidgets(
    'dialog applies date and calendar keyboard navigation crosses months',
    (tester) async {
      String? value = '2026-09-30';
      await mount(
        tester,
        StatefulBuilder(
          builder: (context, setState) => KDatePicker(
            allowTextInput: true,
            value: value,
            onChanged: (next) => setState(() => value = next),
          ),
        ),
      );
      await open(tester);
      final selected = tester.widget<TextButton>(
        find.widgetWithText(TextButton, '30').first,
      );
      selected.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('October'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(value, '2026-10-01');
    },
  );
  testWidgets('disabled readonly and bounds prevent changes', (tester) async {
    var changes = 0;
    await mount(
      tester,
      KDatePicker(
        allowTextInput: true,
        value: '2026-09-16',
        onChanged: (_) => changes++,
        readOnly: true,
      ),
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    await mount(
      tester,
      KDatePicker(
        allowTextInput: true,
        value: '2026-09-16',
        onChanged: (_) => changes++,
        enabled: false,
      ),
    );
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    await mount(
      tester,
      KDatePicker(
        allowTextInput: true,
        value: '2026-09-16',
        onChanged: (_) => changes++,
        min: '2026-09-10',
        max: '2026-09-20',
      ),
    );
    await open(tester);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, '9').first)
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField).last, '2026-09-21');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(
      find.text('Choose a value within the allowed range.'),
      findsOneWidget,
    );
    expect(changes, 0);
  });
  testWidgets(
    'datetime uses injected zoned now and rejects DST gap in dialog',
    (tester) async {
      String? value;
      await mount(
        tester,
        KDateTimePicker(
          allowTextInput: true,
          value: value,
          onChanged: (next) => value = next,
          timeZone: 'Europe/Berlin',
          now: DateTime.utc(2026, 9, 16, 10),
        ),
      );
      await open(tester);
      final fields = find.byType(TextField);
      expect(
        tester.widget<TextField>(fields.at(1)).controller!.text,
        '2026-09-16',
      );
      await tester.enterText(fields.at(1), '2026-03-29');
      await tester.pump();
      expect(tester.widget<TextField>(fields.at(2)).controller!.text, '12:00');
      await tester.enterText(fields.at(2), '02:30');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(value, isNull);
      expect(
        find.text('This local time does not exist in the selected time zone.'),
        findsOneWidget,
      );
    },
  );
  testWidgets('German mobile picker stays usable at two times text size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: KDateTimePicker(
            allowTextInput: true,
            value: '2026-09-16T10:00:00.000Z',
            onChanged: (_) {},
            locale: KPickerLocale.de,
            clearable: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await open(tester);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Abbrechen'));
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(find.text('Übernehmen'), findsNothing);
  });
  testWidgets(
    'unchanged overlap instant does not become an ambiguous new draft',
    (tester) async {
      var changes = 0;
      await mount(
        tester,
        KDateTimePicker(
          allowTextInput: true,
          value: '2026-10-25T00:30:00.000Z',
          onChanged: (_) => changes++,
          timeZone: 'Europe/Berlin',
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(changes, 0);
      expect(
        find.text(
          'This local time occurs twice. Choose an explicit disambiguation policy.',
        ),
        findsNothing,
      );
    },
  );
  testWidgets(
    'opening clamps date draft to bounds without mutating committed value',
    (tester) async {
      String? value = '2026-09-01';
      await mount(
        tester,
        StatefulBuilder(
          builder: (context, setState) => KDatePicker(
            allowTextInput: true,
            value: value,
            onChanged: (next) => setState(() => value = next),
            min: '2026-09-10',
            max: '2026-09-20',
          ),
        ),
      );
      await open(tester);
      expect(value, '2026-09-01');
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        '2026-09-10',
      );
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(value, '2026-09-10');
    },
  );
  testWidgets('datetime clamps zoned date while preserving draft clock time', (
    tester,
  ) async {
    String? value = '2026-09-15T10:00:00.000Z';
    await mount(
      tester,
      KDateTimePicker(
        allowTextInput: true,
        value: value,
        onChanged: (next) => value = next,
        timeZone: 'Europe/Berlin',
        min: '2026-09-16T14:00:00.000Z',
      ),
    );
    await open(tester);
    final fields = find.byType(TextField);
    expect(
      tester.widget<TextField>(fields.at(1)).controller!.text,
      '2026-09-16',
    );
    expect(tester.widget<TextField>(fields.at(2)).controller!.text, '12:00');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(value, '2026-09-15T10:00:00.000Z');
    expect(
      find.text('Choose a value within the allowed range.'),
      findsOneWidget,
    );
  });
  testWidgets(
    'calendar button exposes full date and selected state on one node',
    (tester) async {
      final handle = tester.ensureSemantics();
      await mount(
        tester,
        KDatePicker(
          allowTextInput: true,
          value: '2026-09-16',
          onChanged: (_) {},
        ),
      );
      await open(tester);
      final day = tester.getSemantics(find.widgetWithText(TextButton, '16'));
      final data = day.getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.label, '2026-09-16');
      expect(data.flagsCollection.isSelected.name, 'isTrue');
      final other = tester
          .getSemantics(find.widgetWithText(TextButton, '17'))
          .getSemanticsData();
      expect(other.label, '2026-09-17');
      expect(other.flagsCollection.isSelected.name, 'isFalse');
      handle.dispose();
    },
  );
  testWidgets('modal preserves density and text scale', (tester) async {
    final dense = kDesignTheme(
      configuration: const KDesignConfiguration(density: KDensity.dense),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Theme(
          data: dense,
          child: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: Scaffold(
                body: KDatePicker(
                  allowTextInput: true,
                  value: '2026-09-16',
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await open(tester);
    final day = find.widgetWithText(TextButton, '16');
    final context = tester.element(day);
    expect(
      Theme.of(context).extension<KDesignTokens>()!.sizeControl,
      dense.extension<KDesignTokens>()!.sizeControl,
    );
    expect(MediaQuery.textScalerOf(context).scale(10), 15);
    final tokens = dense.extension<KDesignTokens>()!;
    expect(
      tester.getSize(day).height,
      (tokens.fontControlSize * 1.5 + 16).clamp(
        tokens.sizeControl,
        double.infinity,
      ),
    );
  });
}
