import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

Widget frame(Widget child) => MaterialApp(
  theme: ThemeData(extensions: [KDesignTokens.orbitLight]),
  home: Scaffold(body: child),
);

void main() {
  testWidgets(
    'badge wraps long content at larger text scale without widening',
    (tester) async {
      await tester.pumpWidget(
        frame(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: const Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 180,
                child: KBadge(
                  leading: KIcon(KIconName.check),
                  trailing: KIcon(KIconName.chevronRight),
                  child: Text(
                    'Deine Buchungsseite ist jetzt online und bereit',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(KBadge)).width, 180);
      expect(
        tester
            .getSize(
              find.text('Deine Buchungsseite ist jetzt online und bereit'),
            )
            .height,
        greaterThan(30),
      );

      await tester.pumpWidget(
        frame(
          const Align(
            alignment: Alignment.topLeft,
            child: KBadge(child: Text('Live')),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(KBadge)).width, lessThan(100));
    },
  );
  testWidgets(
    'breadcrumb icon shares state, spacing and activation with label',
    (tester) async {
      var selected = false;
      await tester.pumpWidget(
        frame(
          KBreadcrumb(
            items: [
              KBreadcrumbItem(
                id: 'home',
                label: 'Home',
                icon: KIconName.house,
                onSelect: () => selected = true,
              ),
              const KBreadcrumbItem(
                id: 'settings',
                label: 'Settings',
                icon: KIconName.settings,
              ),
            ],
          ),
        ),
      );
      final icons = tester.widgetList<KIcon>(find.byType(KIcon)).toList();
      expect(icons.first.color, KDesignTokens.orbitLight.colorTextMuted);
      expect(icons.last.color, KDesignTokens.orbitLight.colorTextPrimary);
      // The stroke comes from the style token (Decision 0015).
      expect(icons.first.strokeWidth, isNull);
      expect(
        tester.getTopLeft(find.text('Home')).dx -
            tester.getTopRight(find.byType(KIcon).first).dx,
        KDesignTokens.orbitLight.spaceTight,
      );
      await tester.tap(find.byType(KIcon).first);
      expect(selected, isTrue);
    },
  );
  testWidgets('attachment exposes activation without owning navigation', (
    tester,
  ) async {
    var activations = 0;
    await tester.pumpWidget(
      frame(
        KAttachment(
          title: const Text('Brief.pdf'),
          activateLabel: 'Open Brief.pdf',
          onActivate: () => activations++,
        ),
      ),
    );

    await tester.tap(find.text('Brief.pdf'));
    expect(activations, 1);
  });

  testWidgets('alert dialog returns the selected result', (tester) async {
    await tester.pumpWidget(
      frame(
        Builder(
          builder: (context) => KButton(
            label: 'Open',
            onPressed: () => KAlertDialog.show(
              context: context,
              title: const Text('Delete project?'),
              description: const Text('This cannot be undone.'),
              cancelLabel: 'Cancel',
              actionLabel: 'Delete',
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Delete project?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Delete project?'), findsNothing);
  });

  testWidgets('carousel reports page changes', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      frame(
        SizedBox(
          width: 480,
          child: KCarousel(
            label: 'Projects',
            onIndexChanged: (value) => selected = value,
            children: const [Text('First'), Text('Second')],
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Next slide'));
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(find.text('Second'), findsOneWidget);
  });
}
