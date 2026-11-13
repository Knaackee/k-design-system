import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final (settings, width) in [
    (false, 1210.0),
    (true, 1210.0),
    (true, 393.0),
  ]) {
    testWidgets(
      'page start respects safe area: settings=$settings width=$width',
      (tester) async {
        tester.view.physicalSize = Size(width, 834);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 32);
        tester.view.viewPadding = const FakeViewPadding(top: 32);
        addTearDown(tester.view.reset);
        late KDesignTokens tokens;
        const title = KPageHeader(title: 'Page start');
        await tester.pumpWidget(
          MaterialApp(
            home: KAdaptiveTheme(
              overrides: const KAdaptiveOverrides(style: KStyle.apple),
              child: MediaQuery(
                data: MediaQueryData.fromView(tester.view),
                child: Builder(
                  builder: (context) {
                    tokens = Theme.of(context).extension<KDesignTokens>()!;
                    return Scaffold(
                      body: settings
                          ? const KSettingsPage(
                              navigation: SizedBox(),
                              detailVisible: true,
                              content: title,
                            )
                          : KPageTopGap(
                              gap: tokens.spaceControlGap,
                              child: const Column(children: [title]),
                            ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(find.text('Page start')).dy,
          closeTo(
            32 +
                (width < 700
                    ? tokens.spaceControlInsetInline +
                          tokens.componentPageHeaderPaddingBlockStart
                    : tokens.spaceControlGap),
            1,
          ),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
