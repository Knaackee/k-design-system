import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  Widget host(Widget icon, {bool reduced = false}) => Theme(
    data: kDesignTheme(),
    child: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Center(child: icon),
    ),
  );

  testWidgets('renders every bundled icon at rest and controlled midpoint', (
    tester,
  ) async {
    for (final name in KIconName.values) {
      await tester.pumpWidget(
        host(KAnimatedIcon(name, size: 24, from: KIconName.menu, progress: .5)),
      );
      expect(tester.takeException(), isNull, reason: name.name);
    }
  });

  testWidgets('interruptible animation settles and delivers lifecycle events', (
    tester,
  ) async {
    var starts = 0, ends = 0;
    Widget icon(KIconName name) => host(
      KAnimatedIcon(
        name,
        onAnimationStart: () => starts++,
        onAnimationEnd: () => ends++,
      ),
    );
    await tester.pumpWidget(icon(KIconName.menu));
    await tester.pumpWidget(icon(KIconName.x));
    await tester.pump(const Duration(milliseconds: 48));
    await tester.pumpWidget(icon(KIconName.heart));
    await tester.pumpAndSettle();
    expect(starts, 2);
    expect(ends, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('honors reduced motion without scheduling animation frames', (
    tester,
  ) async {
    var ends = 0;
    await tester.pumpWidget(
      host(const KAnimatedIcon(KIconName.sun), reduced: true),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      host(
        KAnimatedIcon(KIconName.moon, onAnimationEnd: () => ends++),
        reduced: true,
      ),
    );
    expect(ends, 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('retargets before motion advances and exits controlled mode', (
    tester,
  ) async {
    await tester.pumpWidget(host(const KAnimatedIcon(KIconName.menu)));
    await tester.pumpWidget(host(const KAnimatedIcon(KIconName.x)));
    await tester.pumpWidget(host(const KAnimatedIcon(KIconName.sun)));
    await tester.pumpAndSettle();
    for (final progress in [0.0, 1.0]) {
      await tester.pumpWidget(
        host(
          KAnimatedIcon(
            KIconName.moon,
            from: KIconName.sun,
            progress: progress,
            size: 40,
          ),
        ),
      );
      expect(tester.getSize(find.byType(KAnimatedIcon)), const Size(40, 40));
      expect(tester.binding.hasScheduledFrame, isFalse);
    }
    await tester.pumpWidget(host(const KAnimatedIcon(KIconName.heart)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom SVG works and unsupported geometry is rejected', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const KAnimatedIcon.svg(
          '<svg viewBox="0 0 24 24"><path d="M2 2L22 22"/></svg>',
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      host(const KAnimatedIcon.svg('<svg><text>no</text></svg>')),
    );
    expect(tester.takeException(), isArgumentError);
  });
}
