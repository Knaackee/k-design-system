import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final width in [360.0, 393.0, 599.0, 600.0, 839.0, 840.0]) {
    for (final scale in [1.0, 1.3, 2.0, 3.0]) {
      testWidgets(
        'brand navigation width $width text $scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          String selected = 'home';
          final builderStates = <bool>[];
          await tester.pumpWidget(
            MaterialApp(
              theme: kDesignTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: KAdaptiveTheme(child: child!),
              ),
              home: StatefulBuilder(
                builder: (context, setState) => KAppShell(
                  tabBarLabelVisibility: KMobileAppBarLabelVisibility.never,
                  destinations: [
                    const KAppDestination(
                      id: 'home',
                      label: 'Home',
                      icon: KIconName.house,
                    ),
                    KAppDestination(
                      id: 'brand',
                      label: 'Messages',
                      icon: KIconName.inbox,
                      mobileIconBuilder: (context, active) {
                        builderStates.add(active);
                        return const SizedBox(
                          width: 100,
                          height: 100,
                          child: ColoredBox(
                            key: ValueKey('brand'),
                            color: Colors.blue,
                          ),
                        );
                      },
                    ),
                  ],
                  selectedId: selected,
                  onSelected: (value) => setState(() => selected = value),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (width < 600) {
            expect(find.byKey(const ValueKey('brand')), findsOneWidget);
            expect(find.text('Messages'), findsNothing);
            expect(builderStates.last, isFalse);
            expect(
              tester
                  .widget<KMobileAppBar>(find.byType(KMobileAppBar))
                  .labelVisibility,
              KMobileAppBarLabelVisibility.never,
            );
            await tester.tap(find.bySemanticsLabel('Messages'));
            await tester.pumpAndSettle();
            expect(selected, 'brand');
            expect(builderStates.last, isTrue);
            final slot = find
                .ancestor(
                  of: find.byKey(const ValueKey('brand')),
                  matching: find.byType(FittedBox),
                )
                .first;
            expect(tester.getSize(slot).width, 24);
          } else {
            expect(builderStates, isEmpty);
            expect(find.byType(KMobileAppBar), findsNothing);
            expect(find.byType(KSidebar), findsOneWidget);
            expect(find.text('Messages'), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
        },
        semanticsEnabled: true,
        variant: TargetPlatformVariant({
          TargetPlatform.iOS,
          TargetPlatform.android,
        }),
      );
    }
  }
}
