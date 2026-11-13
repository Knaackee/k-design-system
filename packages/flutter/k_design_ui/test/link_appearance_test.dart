import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('subtle links use neutral text and icon, wrap and activate', (
    tester,
  ) async {
    var taps = 0;
    const label =
        'Verified source with a long descriptive title that wraps on narrow screens';
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 180,
            child: KLink(
              label: label,
              appearance: KLinkAppearance.subtle,
              leading: const KIcon(KIconName.link),
              onPressed: () => taps++,
            ),
          ),
        ),
      ),
    );
    final context = tester.element(find.text(label));
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    expect(DefaultTextStyle.of(context).style.color, tokens.colorTextMuted);
    expect(DefaultTextStyle.of(context).style.decoration, TextDecoration.none);
    expect(
      tester.widget<KIcon>(find.byType(KIcon)).color,
      tokens.colorTextMuted,
    );
    expect(
      tester.getSize(find.text(label)).height,
      greaterThan(tokens.fontBodySmallSize * 2),
    );
    await tester.tap(find.text(label));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('default links preserve underlining and explicit icon colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: Column(
            children: [
              KLink(label: 'Default', onPressed: () {}),
              KLink(
                label: 'Custom icon',
                appearance: KLinkAppearance.subtle,
                leading: const KIcon(KIconName.link, color: Colors.red),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    final context = tester.element(find.text('Default'));
    expect(
      DefaultTextStyle.of(context).style.decoration,
      TextDecoration.underline,
    );
    expect(tester.widget<KIcon>(find.byType(KIcon)).color, Colors.red);
  });
}
