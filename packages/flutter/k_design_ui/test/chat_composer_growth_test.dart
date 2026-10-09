import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

void main() {
  for (final width in [375.0, 1100.0]) {
    testWidgets('composer grows and caps text height at width $width', (
      tester,
    ) async {
      KDesignTokens? scopedTokens;
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
                leadingTools: [
                  Builder(
                    builder: (context) {
                      scopedTokens = Theme.of(
                        context,
                      ).extension<KDesignTokens>();
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final field = find.byType(TextField);
      final attach = find.byTooltip('Attach files');
      final voice = find.byTooltip('Start voice input');
      final send = find.byTooltip('Send message');
      final initial = tester.getSize(field).height;
      final tokens = KDesignTokens.orbitLight;
      final expectedGap = tokens.spaceControlGap / 2;
      final expectedTarget = math.max(tokens.sizeControl, tokens.sizeHitTarget);
      final expectedVisual = math.min(
        expectedTarget,
        tokens.spaceControlGap * 4.5,
      );
      final expectedIcon = math.min(
        expectedVisual,
        tokens.spaceControlGap * 3 - tokens.borderWidthDefault * 2,
      );
      if (width == 375) {
        final composer = find.byType(KChatComposer);
        final material = tester.widget<Material>(
          find.descendant(of: composer, matching: find.byType(Material)).first,
        );
        final outerPadding = tester.widget<Padding>(
          find.descendant(of: composer, matching: find.byType(Padding)).first,
        );
        final surfaceFinder = find
            .descendant(of: composer, matching: find.byType(DecoratedBox))
            .first;
        final surface =
            tester.widget<DecoratedBox>(surfaceFinder).decoration
                as BoxDecoration;
        expect(material.color, tokens.colorSurfaceCanvas);
        expect(
          outerPadding.padding,
          EdgeInsets.symmetric(
            horizontal: tokens.spaceControlInsetInline,
            vertical: expectedGap,
          ),
        );
        expect(surface.border, Border.all(color: tokens.colorBorderDefault));
        expect(
          surface.borderRadius,
          BorderRadius.circular(expectedTarget / 2 + expectedGap),
        );
        expect(surface.boxShadow, tokens.elevationLow);
        expect(
          tester.getSize(surfaceFinder).height,
          expectedTarget + expectedGap * 2,
        );
      }
      expect(scopedTokens?.spaceControlGap, expectedGap);
      expect(scopedTokens?.sizeControl, expectedVisual);
      expect(scopedTokens?.sizeHitTarget, expectedTarget);
      expect(scopedTokens?.radiusControl, expectedVisual / 2);
      expect(scopedTokens?.fontBodySize, tokens.fontBodySize);
      expect(
        tester.widget<TextField>(field).style?.fontSize,
        tokens.fontBodySize,
      );
      for (final icon
          in find
              .descendant(
                of: find.byType(KChatComposer),
                matching: find.byType(KIcon),
              )
              .evaluate()) {
        expect(
          tester.getSize(find.byElementPredicate((e) => e == icon)),
          Size.square(expectedIcon),
        );
      }
      expect(
        tester.getRect(attach).right,
        lessThan(tester.getRect(field).left),
      );
      expect(tester.getRect(field).right, lessThan(tester.getRect(voice).left));
      expect(tester.getRect(voice).right, lessThan(tester.getRect(send).left));
      expect(tester.getSize(field).height, tester.getSize(attach).height);
      expect(tester.getCenter(field).dy, tester.getCenter(attach).dy);
      expect(tester.getCenter(field).dy, tester.getCenter(voice).dy);
      expect(tester.getCenter(field).dy, tester.getCenter(send).dy);
      expect(tester.getRect(attach).bottom, tester.getRect(field).bottom);
      expect(tester.getRect(voice).bottom, tester.getRect(field).bottom);
      expect(tester.getRect(send).bottom, tester.getRect(field).bottom);
      await tester.enterText(
        field,
        List.filled(4, 'A longer message').join('\n'),
      );
      await tester.pump();
      expect(tester.getSize(field).height, greaterThan(initial));
      expect(tester.getRect(attach).bottom, tester.getRect(field).bottom);
      expect(tester.getRect(voice).bottom, tester.getRect(field).bottom);
      expect(tester.getRect(send).bottom, tester.getRect(field).bottom);
      await tester.enterText(
        field,
        List.filled(40, 'A longer message').join('\n'),
      );
      await tester.pump();
      expect(tester.getSize(field).height, lessThanOrEqualTo(200));
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
      const Size.square(22),
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
