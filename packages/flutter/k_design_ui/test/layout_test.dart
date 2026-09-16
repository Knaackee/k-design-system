import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

const a = SizedBox(key: ValueKey('a'), width: 30, height: 20);
const b = SizedBox(key: ValueKey('b'), width: 50, height: 40);

Widget frame(KDesignTokens tokens, Widget child) => MaterialApp(
  theme: ThemeData(extensions: [tokens]),
  home: Center(child: SizedBox(width: 200, child: child)),
);

void main() {
  for (final gap in KLayoutGap.values) {
    testWidgets('live ${gap.name} gaps and consumer overrides', (tester) async {
      final child = KStack(gap: gap, children: const [a, b]);
      Element? previous;
      for (final density in KDensity.values) {
        final tokens = kDesignTokens(
          configuration: KDesignConfiguration(density: density),
        );
        final expected = switch (gap) {
          KLayoutGap.control => tokens.spaceControlGap,
          KLayoutGap.action => tokens.spaceContentActionGap,
          KLayoutGap.section => tokens.spaceLayoutSectionGap,
        };
        await tester.pumpWidget(frame(tokens, child));
        await tester.pumpAndSettle();
        final element = tester.element(find.byKey(const ValueKey('a')));
        if (previous != null) expect(element, same(previous));
        previous = element;
        final first = tester.getRect(find.byKey(const ValueKey('a')));
        final second = tester.getRect(find.byKey(const ValueKey('b')));
        expect(second.top - first.bottom, closeTo(expected, .5));
        expect(first.size, const Size(30, 20));
        expect(second.size, const Size(50, 40));
      }
      final custom = KDesignTokens.orbitLight.copyWith(
        spaceControlGap: 13,
        spaceContentActionGap: 13,
        spaceLayoutSectionGap: 13,
      );
      await tester.pumpWidget(frame(custom, child));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('b'))).dy -
            tester.getBottomLeft(find.byKey(const ValueKey('a'))).dy,
        13,
      );
      await tester.pumpWidget(
        frame(custom, KInline(gap: gap, children: const [a, b])),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('b'))).dx -
            tester.getTopRight(find.byKey(const ValueKey('a'))).dx,
        13,
      );
    });
  }
  for (final count in [0, 1]) {
    testWidgets('empty/single child has no phantom gap: $count', (
      tester,
    ) async {
      for (final horizontal in [false, true]) {
        final children = count == 0 ? <Widget>[] : [a];
        final layout = horizontal
            ? KInline(children: children)
            : KStack(children: children);
        await tester.pumpWidget(frame(KDesignTokens.orbitLight, layout));
        expect(
          tester.getSize(find.byWidget(layout)).height,
          count == 0 ? 0 : 20,
        );
        expect(tester.takeException(), isNull);
      }
    });
  }
  testWidgets('wrap uses the same horizontal and vertical gap', (tester) async {
    await tester.pumpWidget(
      frame(
        KDesignTokens.orbitLight.copyWith(spaceControlGap: 13),
        const KInline(
          wrap: true,
          children: [
            a,
            b,
            SizedBox(key: ValueKey('c'), width: 160, height: 10),
          ],
        ),
      ),
    );
    final first = tester.getRect(find.byKey(const ValueKey('a')));
    final second = tester.getRect(find.byKey(const ValueKey('b')));
    final third = tester.getRect(find.byKey(const ValueKey('c')));
    expect(second.left - first.right, 13);
    expect(third.top - second.bottom, 13);
    expect(third.left, first.left);
  });
  testWidgets('wrapped stretch fails explicitly', (tester) async {
    await tester.pumpWidget(
      frame(
        KDesignTokens.orbitLight,
        const KInline(
          wrap: true,
          align: KLayoutAlign.stretch,
          children: [a, b],
        ),
      ),
    );
    expect(tester.takeException(), isArgumentError);
  });
  for (final align in KLayoutAlign.values) {
    testWidgets('cross axis ${align.name}', (tester) async {
      await tester.pumpWidget(
        frame(
          KDesignTokens.orbitLight,
          KInline(align: align, children: const [a, b]),
        ),
      );
      final first = tester.getRect(find.byKey(const ValueKey('a')));
      final second = tester.getRect(find.byKey(const ValueKey('b')));
      switch (align) {
        case KLayoutAlign.start:
          expect(first.top, second.top);
        case KLayoutAlign.center:
          expect(first.center.dy, second.center.dy);
        case KLayoutAlign.end:
          expect(first.bottom, second.bottom);
        case KLayoutAlign.stretch:
          expect(first.height, second.height);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
