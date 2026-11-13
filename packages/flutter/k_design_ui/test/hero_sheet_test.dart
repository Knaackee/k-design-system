import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final width in [390.0, 1120.0]) {
    for (final scale in [1.0, 1.3, 2.0, 3.0]) {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        testWidgets(
          'hero sheet scroll and fixed footer $width $scale $brightness',
          (tester) async {
            tester.view.physicalSize = Size(width, 844);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              MaterialApp(
                theme: kDesignTheme().copyWith(platform: TargetPlatform.iOS),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: KAdaptiveTheme(brightness: brightness, child: child!),
                ),
                home: Scaffold(
                  body: Builder(
                    builder: (context) => KButton(
                      label: 'Open',
                      onPressed: () => KAdaptiveSheet.show<void>(
                        context: context,
                        builder: (routeContext) => KAdaptiveSheet(
                          title: 'Booking details',
                          hero: const ColoredBox(
                            key: ValueKey('hero'),
                            color: Colors.transparent,
                          ),
                          closeLabel: 'Close details',
                          onClose: () => Navigator.of(routeContext).pop(),
                          footer: KButton(
                            label: 'Cancel booking',
                            tone: KButtonTone.destructive,
                            onPressed: () {},
                          ),
                          child: KList(
                            children: List.generate(
                              20,
                              (i) => KListItem(
                                title: 'Row $i',
                                description:
                                    'Booking information with enough content to scroll.',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.tap(find.text('Open'));
            await tester.pumpAndSettle();
            expect(
              tester.getSize(find.byKey(const ValueKey('hero'))).height,
              240,
            );
            expect(
              find.byTooltip('Close details').hitTestable(),
              findsOneWidget,
            );
            final footerTop = tester.getTopLeft(find.text('Cancel booking')).dy;
            await tester.scrollUntilVisible(
              find.text('Row 19'),
              300,
              scrollable: find.byType(Scrollable).first,
            );
            expect(find.text('Row 19').hitTestable(), findsOneWidget);
            expect(
              tester.getTopLeft(find.text('Cancel booking')).dy,
              footerTop,
            );
            expect(tester.takeException(), isNull);
            await tester.scrollUntilVisible(
              find.byTooltip('Close details'),
              -300,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.pumpAndSettle();
            if (find
                .byTooltip('Close details')
                .hitTestable()
                .evaluate()
                .isNotEmpty) {
              await tester.tap(find.byTooltip('Close details'));
              await tester.pumpAndSettle();
            }
            expect(find.byType(KAdaptiveSheet), findsNothing);
          },
        );
      }
    }
  }
  testWidgets('tall footer remains reachable at 3x in a short viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(3)),
          child: child!,
        ),
        home: Scaffold(
          body: KAdaptiveSheet(
            inline: true,
            title: 'Details',
            hero: const SizedBox(key: ValueKey('media')),
            onClose: () {},
            footer: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'The booking could not be cancelled. Please check the connection and try again.',
                ),
                KButton(
                  label: 'Confirm cancellation',
                  tone: KButtonTone.destructive,
                  onPressed: () {},
                ),
                KButton(label: 'Keep booking', onPressed: () {}),
              ],
            ),
            child: const Text('Customer details'),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byKey(const ValueKey('media'))).height, 240);
    await tester.scrollUntilVisible(
      find.text('Keep booking'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Keep booking').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'inline pane leaves its master list visible without a drag wrapper',
    (tester) async {
      tester.view.physicalSize = const Size(1120, 770);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: Row(
              children: [
                const Expanded(child: Text('Master list')),
                KAdaptiveSheet(
                  title: 'Details',
                  inline: true,
                  hero: const SizedBox(),
                  onClose: () {},
                  child: const Text('Customer'),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Master list').hitTestable(), findsOneWidget);
      expect(find.byType(KSheetDrag), findsNothing);
      expect(tester.getSize(find.byType(KSideSheet)).width, 420);
      expect(tester.takeException(), isNull);
    },
  );
}
