import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/src/components/chat_presentations.dart';
import 'package:k_design_ui/src/components/chat_presentation_media.dart';
import 'package:k_design_ui/src/primitives/k_button.dart';
import 'package:k_design_ui/src/overlays/k_adaptive_dialog.dart';

void main() {
  testWidgets('open gallery updates its image when next is selected', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 873);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => KPresentationGallery(
              images: const [
                KPresentationImage(src: 'https://example.com/a.png', alt: 'A'),
                KPresentationImage(src: 'https://example.com/b.png', alt: 'B'),
              ],
              selectedIndex: selected,
              onSelectedIndexChange: (index) =>
                  setState(() => selected = index),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('A'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.ensureVisible(find.text('Next image'));
    await tester.tap(find.text('Next image'));
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(tester.takeException(), isNull);
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.ensureVisible(find.text('Previous image'));
    await tester.tap(find.text('Previous image'));
    await tester.pumpAndSettle();
    expect(selected, 0);
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.ensureVisible(find.text('Close').last);
    await tester.tap(find.text('Close').last);
    await tester.pumpAndSettle();
    expect(selected, isNull);
    expect(tester.takeException(), isNull);
  });

  for (final covered in [false, true]) {
    testWidgets('host removal closes only its gallery (covered: $covered)', (
      tester,
    ) async {
      final visible = ValueNotifier(true);
      addTearDown(visible.dispose);
      final navigator = GlobalKey<NavigatorState>();
      var selections = 0;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          theme: kDesignTheme(),
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: visible,
              builder: (_, show, child) => show
                  ? KPresentationGallery(
                      images: const [
                        KPresentationImage(
                          src: 'https://example.com/a.png',
                          alt: 'A',
                        ),
                        KPresentationImage(
                          src: 'https://example.com/b.png',
                          alt: 'B',
                        ),
                      ],
                      selectedIndex: 0,
                      onSelectedIndexChange: (_) => selections++,
                    )
                  : const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final staleNext = tester
          .widget<KButton>(find.widgetWithText(KButton, 'Next image'))
          .onPressed!;
      if (covered) {
        navigator.currentState!.push<void>(
          MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Other route')),
          ),
        );
        await tester.pumpAndSettle();
      }
      visible.value = false;
      await tester.pumpAndSettle();
      staleNext();
      expect(selections, 0);
      expect(find.byType(KAdaptiveDialog, skipOffstage: false), findsNothing);
      if (covered) expect(find.text('Other route'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
