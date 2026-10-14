import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('call can mute, minimize, return and end at mobile width', (
    tester,
  ) async {
    bool expanded = true, muted = false, ended = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(configuration: KDesignConfiguration.mobileApp),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 600,
              child: StatefulBuilder(
                builder: (context, change) => KCallBar(
                  name: 'Alex',
                  status: 'Hört zu',
                  duration: '02:14',
                  muted: muted,
                  microphoneLevel: .7,
                  avatar: const SizedBox.square(dimension: 240),
                  expanded: expanded,
                  onMutedChanged: (value) => change(() => muted = value),
                  onExpandedChanged: (value) => change(() => expanded = value),
                  onEndCall: () => ended = true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Finder action(String label) => find.byWidgetPredicate(
      (widget) =>
          (widget is KIconButton && widget.label == label) ||
          (widget is KButton && widget.label == label),
    );
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 920));
    await tester.tap(action('Mute microphone'));
    await tester.pump();
    expect(muted, isTrue);
    await tester.tap(action('Back to chat'));
    await tester.pump();
    expect(expanded, isFalse);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Alex'));
    await tester.pump();
    expect(expanded, isTrue);
    await tester.pump(const Duration(milliseconds: 920));
    await tester.tap(action('End call'));
    expect(ended, isTrue);
  });
  testWidgets('call bar fits host mobile tokens at 320 pixels', (tester) async {
    bool? requested;
    final tokens = kDesignTokens(configuration: KDesignConfiguration.mobileApp);
    final minimumHeight =
        tokens.sizeIconDefault * 2 + tokens.spaceControlGap * 2;
    final compactHeight = minimumHeight + tokens.borderWidthDefault;
    await tester.pumpWidget(
      _host(
        name: 'A long agent name',
        onMutedChanged: (value) => requested = value,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(KCallBar)).height, compactHeight);
    await tester.tap(find.byType(KIconButton));
    expect(requested, isTrue);
    expect(find.text('02:14'), findsOneWidget);
  });

  testWidgets('call bar grows for large text without overflowing', (
    tester,
  ) async {
    final tokens = kDesignTokens(configuration: KDesignConfiguration.mobileApp);
    final minimumHeight =
        tokens.sizeIconDefault * 2 + tokens.spaceControlGap * 2;
    final scaledTextHeight =
        (tokens.fontBodyLineHeight + tokens.fontBodySmallLineHeight) * 2 +
        tokens.spaceControlGap * 2 +
        tokens.borderWidthDefault;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: _host(name: 'A long agent name', onMutedChanged: (_) {}),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(KCallBar)).height,
      allOf(greaterThan(minimumHeight), closeTo(scaledTextHeight, .01)),
    );
  });

  testWidgets(
    'call bar maps raw microphone amplitude perceptually and safely',
    (tester) async {
      final tokens = kDesignTokens(
        configuration: KDesignConfiguration.mobileApp,
      );
      final baseline = tokens.sizeIconDefault * .125;
      double peak() => tester
          .getSize(find.byKey(const ValueKey('k-call-bar-level-12')))
          .height;

      await tester.pumpWidget(
        _host(name: 'Agent', microphoneLevel: .02, onMutedChanged: (_) {}),
      );
      expect(peak(), greaterThan(baseline + tokens.sizeIconDefault * .3));

      for (final level in [0.0, -1.0, double.nan, double.infinity]) {
        await tester.pumpWidget(
          _host(name: 'Agent', microphoneLevel: level, onMutedChanged: (_) {}),
        );
        expect(peak(), baseline);
      }

      await tester.pumpWidget(
        _host(
          name: 'Agent',
          microphoneLevel: .8,
          muted: true,
          onMutedChanged: (_) {},
        ),
      );
      expect(peak(), baseline);

      await tester.pumpWidget(
        _host(name: 'Agent', microphoneLevel: 2, onMutedChanged: (_) {}),
      );
      expect(peak(), closeTo(tokens.sizeIconDefault, .01));
    },
  );
}

Widget _host({
  required String name,
  required ValueChanged<bool> onMutedChanged,
  double microphoneLevel = .8,
  bool muted = false,
}) => MaterialApp(
  theme: kDesignTheme(
    configuration: KDesignConfiguration.mobileApp,
    tokenTransform: (tokens) => tokens.copyWith(
      colorSurfaceRaised: const Color(0xFFFFFEFC),
      colorBorderDefault: const Color(0xFFE2DED8),
      colorTextPrimary: const Color(0xFF201E1D),
      colorTextMuted: const Color(0xFF6A635E),
      fontControlWeight: FontWeight.w400,
    ),
  ),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 320,
        child: KCallBar(
          name: name,
          status: 'Hört zu',
          duration: '02:14',
          muted: muted,
          microphoneLevel: microphoneLevel,
          onMutedChanged: onMutedChanged,
        ),
      ),
    ),
  ),
);
