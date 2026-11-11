import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

void main() {
  for (final width in [375.0, 1100.0]) {
    testWidgets('two-row composer grows to eight lines at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: KChatComposer(
                value: '',
                onValueChanged: (_) {},
                onSubmit: (_) {},
                onAttach: () {},
                onVoiceInput: () {},
              ),
            ),
          ),
        ),
      );
      final field = find.byType(TextField);
      final attach = find.byTooltip('Attach files');
      final voice = find.byTooltip('Start voice input');
      final send = find.byTooltip('Send message');
      final tokens = Theme.of(
        tester.element(field),
      ).extension<KDesignTokens>()!;
      final input = tester.widget<TextField>(field);
      expect(input.minLines, 2);
      expect(input.maxLines, 8);
      expect(input.style?.fontSize, tokens.fontBodySmallSize);
      expect(
        tester.getRect(field).bottom,
        lessThanOrEqualTo(tester.getRect(attach).top),
      );
      expect(tester.getCenter(attach).dy, tester.getCenter(voice).dy);
      expect(tester.getCenter(voice).dy, tester.getCenter(send).dy);
      final initial = tester.getSize(field).height;
      await tester.enterText(
        field,
        List.filled(4, 'A longer message').join('\n'),
      );
      await tester.pump();
      expect(tester.getSize(field).height, greaterThan(initial));
      await tester.enterText(
        field,
        List.filled(40, 'A longer message').join('\n'),
      );
      await tester.pump();
      expect(
        tester.getSize(field).height,
        closeTo(tokens.fontBodySmallLineHeight * 8, 1),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('composer keeps the optional model within a narrow layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: KChatComposer(
              value: '',
              onValueChanged: (_) {},
              onSubmit: (_) {},
              onAttach: () {},
              onVoiceInput: () {},
              models: const [
                KChatComposerModel(
                  value: 'long-model',
                  label: 'A model with a long display name',
                ),
              ],
              model: 'long-model',
              onModelChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(KSelect)).width, lessThanOrEqualTo(280));
    expect(tester.takeException(), isNull);
  });

  testWidgets('long placeholder keeps the empty composer compact', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Future<double> composerHeight(String placeholder) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: KChatComposer(
                value: '',
                onValueChanged: (_) {},
                onSubmit: (_) {},
                labels: KChatComposerLabels(placeholder: placeholder),
                onAttach: () {},
                onVoiceInput: () {},
              ),
            ),
          ),
        ),
      );
      return tester.getSize(find.byType(KChatComposer)).height;
    }

    final shortHeight = await composerHeight('Message');
    final longHeight = await composerHeight(
      'Nachricht schreiben und mit deinem Agenten teilen …',
    );

    expect(longHeight, shortHeight);
    expect(tester.takeException(), isNull);
  });

  testWidgets('composer icon sizing leaves the shared default unchanged', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: Row(
            children: [
              const KIcon(KIconName.info, key: ValueKey('default-icon')),
              KIconSizeScope(
                size: 22,
                child: const KIcon(
                  KIconName.info,
                  key: ValueKey('scoped-icon'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('default-icon'))),
      const Size.square(16),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('scoped-icon'))),
      const Size.square(22),
    );
  });

  testWidgets('touch composer keeps 48 targets around compact visuals', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(
          configuration: const KDesignConfiguration(
            inputMode: KInputMode.touch,
          ),
        ),
        home: Scaffold(
          body: KChatComposer(
            value: '',
            onValueChanged: (_) {},
            onSubmit: (_) {},
            onAttach: () {},
            onVoiceInput: () {},
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byTooltip('Attach files')),
      const Size.square(48),
    );
    // The visual surface must not stretch its icon to the full button size.
    expect(
      tester.getSize(
        find.descendant(
          of: find.byTooltip('Attach files'),
          matching: find.byType(KIcon),
        ),
      ),
      const Size.square(16),
    );
    for (final visual
        in find.byKey(const ValueKey('k-action-control-visual')).evaluate()) {
      expect(
        tester.getSize(find.byElementPredicate((element) => element == visual)),
        const Size.square(36),
      );
    }
    expect(tester.takeException(), isNull);
  });
}
