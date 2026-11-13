import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets(
    'bottom sheet preserves background header and content positions',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          home: KAdaptiveTheme(
            overrides: const KAdaptiveOverrides(style: KStyle.material),
            child: Scaffold(
              body: KAppShell(
                destinations: const [
                  KAppDestination(
                    id: 'home',
                    label: 'Home',
                    icon: KIconName.house,
                  ),
                  KAppDestination(
                    id: 'more',
                    label: 'More',
                    icon: KIconName.menu,
                  ),
                ],
                selectedId: 'home',
                onSelected: (_) {},
                child: Builder(
                  builder: (context) => KPage(
                    children: [
                      KPageHeader(
                        key: const ValueKey('header'),
                        title: 'Dashboard',
                        leading: KIconButton(
                          label: 'Open sheet',
                          icon: KIconName.menu,
                          onPressed: () async {
                            result = await KBottomSheet.show<String>(
                              context: context,
                              title: const KText('Sheet'),
                              child: Builder(
                                builder: (context) => KButton(
                                  label: 'Choose',
                                  onPressed: () =>
                                      Navigator.pop(context, 'chosen'),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const KText(
                        'Dashboard content',
                        key: ValueKey('content'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final header = find.byKey(const ValueKey('header'));
      final content = find.byKey(const ValueKey('content'));
      final headerY = tester.getTopLeft(header).dy;
      final contentY = tester.getTopLeft(content).dy;
      await tester.tap(find.byTooltip('Open sheet'));
      await tester.pumpAndSettle();
      expect(find.text('Sheet'), findsOneWidget);
      expect(tester.getTopLeft(header).dy, headerY);
      expect(tester.getTopLeft(content).dy, contentY);
      await tester.tap(find.widgetWithText(KButton, 'Choose'));
      await tester.pumpAndSettle();
      expect(result, 'chosen');
      expect(find.text('Sheet'), findsNothing);
      expect(tester.getTopLeft(header).dy, headerY);
      expect(tester.getTopLeft(content).dy, contentY);
      expect(find.byTooltip('Open sheet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'opaque routes remove covered page actions and restore them on pop',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          home: KAdaptiveTheme(
            overrides: const KAdaptiveOverrides(style: KStyle.material),
            child: Scaffold(
              body: KScrollTopBar(
                child: Navigator(
                  key: navigator,
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (_) => KPage(
                      children: [
                        KPageHeader(
                          title: 'Dashboard',
                          leading: KIconButton(
                            label: 'Dashboard action',
                            icon: KIconName.menu,
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Dashboard action'), findsOneWidget);
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              const KPage(children: [KPageHeader(title: 'Second page')]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Dashboard action'), findsNothing);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.byTooltip('Dashboard action'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
