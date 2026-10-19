import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/files_home_fixture.dart';

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets('dashboard filters and full workspace navigation at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: const Scaffold(body: FilesHomeFixture(workspace: true)),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Bilder'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(KFilesHome),
          matching: find.text('Willkommen.md'),
        ),
        findsNothing,
      );
      await tester.ensureVisible(
        find.descendant(
          of: find.byType(KFilesHome),
          matching: find.text('Entwurf.png'),
        ),
      );
      await tester.tap(
        find.descendant(
          of: find.byType(KFilesHome),
          matching: find.text('Entwurf.png'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      await tester.tap(find.widgetWithText(KButton, 'Dateien'));
      await tester.pumpAndSettle();
      expect(find.text('Dein Platz für Ideen.'), findsOneWidget);
      await tester.tap(find.text('Dokumente'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.descendant(
          of: find.byType(KFilesHome),
          matching: find.text('Willkommen.md'),
        ),
      );
      await tester.tap(
        find.descendant(
          of: find.byType(KFilesHome),
          matching: find.text('Willkommen.md'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(KMarkdownEditor), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  for (final width in [390.0, 600.0, 1280.0]) {
    testWidgets('file cards share geometry at $width', (tester) async {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: const Scaffold(body: FilesHomeFixture()),
        ),
      );
      final rects = [
        for (final label in ['Neue Datei', 'Neuer Ordner', 'Hochladen'])
          tester.getRect(
            find
                .ancestor(of: find.text(label), matching: find.byType(KSurface))
                .first,
          ),
      ];
      expect(rects[0].height, closeTo(rects[1].height, .01));
      expect(rects[1].height, closeTo(rects[2].height, .01));
      expect(rects[0].width, closeTo(rects[1].width, .01));
      if (width > 480) {
        expect(rects[0].top, rects[1].top);
        expect(rects[1].top, rects[2].top);
      } else {
        expect(rects[0].left, rects[1].left);
        expect(rects[1].left, rects[2].left);
      }
      expect(tester.takeException(), isNull);
    });
  }
  for (final width in [390.0, 1280.0]) {
    testWidgets('folder toggle and add menu align at $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: const Scaffold(body: FilesHomeFixture(workspace: true)),
        ),
      );
      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is KIconButton && widget.label == 'Dateien öffnen',
        ),
      );
      await tester.pumpAndSettle();
      final toggle = find.byKey(const ValueKey('files-toggle-notes'));
      final chevron = find.descendant(of: toggle, matching: find.byType(KIcon));
      expect(tester.getCenter(toggle), tester.getCenter(chevron));
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(KFileTree),
          matching: find.text('Willkommen.md'),
        ),
        findsNothing,
      );
      final menu = find.byWidgetPredicate(
        (widget) => widget is KMenuButton && widget.label == 'Datei hinzufügen',
      );
      final icons = find.descendant(of: menu, matching: find.byType(KIcon));
      expect(icons, findsNWidgets(2));
      final trash = find.byWidgetPredicate(
        (widget) => widget is KSidebarItem && widget.label == 'Papierkorb',
      );
      final trashIcon = find.descendant(
        of: trash,
        matching: find.byType(KIcon),
      );
      expect(
        tester.getCenter(icons.first).dx,
        closeTo(tester.getCenter(trashIcon).dx, .01),
      );
      expect(
        tester.getRect(find.text('Datei hinzufügen')).left,
        closeTo(tester.getRect(find.text('Papierkorb')).left, .01),
      );
      final labelRect = tester.getRect(find.text('Datei hinzufügen'));
      expect(
        tester.getCenter(icons.first).dy,
        closeTo(labelRect.center.dy, .01),
      );
      expect(
        tester.getCenter(icons.last).dy,
        closeTo(labelRect.center.dy, .01),
      );
      expect(tester.getRect(icons.first).right, lessThan(labelRect.left));
      expect(tester.getRect(icons.last).left, greaterThan(labelRect.right));
      await tester.tap(menu);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(MenuItemButton, 'Neue Datei'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('empty dashboard creation is interactive', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const Scaffold(body: FilesHomeFixture(empty: true)),
      ),
    );
    expect(find.text('Hier beginnt deine Sammlung.'), findsOneWidget);
    await tester.ensureVisible(find.text('Erste Datei erstellen'));
    await tester.tap(find.text('Erste Datei erstellen'));
    await tester.pumpAndSettle();
    expect(find.text('Neue Datei.md'), findsOneWidget);
    expect(find.text('Hier beginnt deine Sammlung.'), findsNothing);
  });
}
