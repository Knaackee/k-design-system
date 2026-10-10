import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/foley_sounds_fixture.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <String>[];
  final eventChannels = <MethodChannel>[];

  setUp(() async {
    calls.clear();
    for (final channel in [
      const MethodChannel('xyz.luan/audioplayers.global'),
      const MethodChannel('xyz.luan/audioplayers.global/events'),
    ]) {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => null,
      );
    }
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        calls.add(call.method);
        if (call.method == 'create') {
          final id = (call.arguments as Map)['playerId'];
          final channel = MethodChannel('xyz.luan/audioplayers/events/$id');
          eventChannels.add(channel);
          binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            (_) async => null,
          );
        }
        return null;
      },
    );
    await AudioPlayer.global.ensureInitialized();
  });

  tearDown(() {
    for (final channel in [
      const MethodChannel('xyz.luan/audioplayers'),
      const MethodChannel('xyz.luan/audioplayers.global'),
      const MethodChannel('xyz.luan/audioplayers.global/events'),
      ...eventChannels,
    ]) {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    }
    eventChannels.clear();
  });

  for (final width in [320.0, 640.0, 960.0]) {
    testWidgets('loads all cues without layout errors at $width px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // Load the real packaged metadata, rather than replacing it with a fixture.
      rootBundle.evict('assets/foley/export-metadata.json');
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: const Scaffold(body: FoleySoundsFixture()),
        ),
      );
      await tester.runAsync(
        () => rootBundle.loadString('assets/foley/export-metadata.json'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Tap'),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .join(', '),
      );
      expect(find.text('Complete'), findsOneWidget);
      expect(
        find.text('Klangpalette konnte nicht geladen werden.'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      final expand = find.text('Alle 28 Klänge entdecken');
      await tester.ensureVisible(expand);
      await tester.tap(expand);
      await tester.pumpAndSettle();
      expect(find.text('Tick'), findsOneWidget);
      expect(find.text('Sparkle'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              (widget.properties.label?.endsWith(' anhören') ?? false),
        ),
        findsNWidgets(28),
      );
      expect(
        calls,
        isNot(contains('resume')),
        reason: 'Loading or expanding never plays a cue',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('event policies keep actions visible while suppressing audio', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(960, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    rootBundle.evict('assets/foley/export-metadata.json');
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const Scaffold(body: FoleySoundsFixture()),
      ),
    );
    await tester.runAsync(
      () => rootBundle.loadString('assets/foley/export-metadata.json'),
    );
    await tester.pumpAndSettle();
    Finder toggle(String label) => find.byWidgetPredicate(
      (widget) => widget is KSwitch && widget.label == label,
    );
    Future<void> click(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    final master = toggle('Ereignistöne aktivieren');
    expect(tester.widget<KSwitch>(master).value, isTrue);
    await click(master);
    expect(tester.widget<KSwitch>(master).value, isFalse);
    expect(tester.widget<KSwitch>(toggle('Chat')).onChanged, isNull);
    expect(
      tester.widget<KSwitch>(toggle('Tool-Aktivitäten')).onChanged,
      isNull,
    );
    await click(find.text('Nachricht empfangen'));
    expect(find.text('Nachricht empfangen.'), findsOneWidget);
    expect(calls, isNot(contains('setSourceUrl')));

    await click(master);
    await click(toggle('Chat'));
    await click(find.text('Rückfrage'));
    expect(find.text('Rückfrage gestellt.'), findsOneWidget);
    expect(calls, isNot(contains('setSourceUrl')));
    await click(toggle('Tool-Aktivitäten'));
    await click(find.text('Suche fehlgeschlagen'));
    expect(find.text('Suche fehlgeschlagen.'), findsOneWidget);
    expect(calls, isNot(contains('setSourceUrl')));

    await click(toggle('Chat'));
    await click(toggle('Tool-Aktivitäten'));
    await click(find.text('Stummschalten'));
    await click(find.text('Suche abgeschlossen'));
    expect(find.text('Suche abgeschlossen.'), findsOneWidget);
    expect(calls, isNot(contains('setSourceUrl')));
    expect(
      calls,
      contains('stop'),
      reason: 'Disabling policy or muting stops the preview',
    );

    await click(find.text('Ton einschalten'));
    tester.widget<KSlider>(find.byType(KSlider)).onChanged!(0);
    await tester.pumpAndSettle();
    await click(find.text('Nachricht empfangen'));
    expect(find.text('Nachricht empfangen.'), findsOneWidget);
    expect(calls, isNot(contains('setSourceUrl')));
    expect(calls, isNot(contains('resume')));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
