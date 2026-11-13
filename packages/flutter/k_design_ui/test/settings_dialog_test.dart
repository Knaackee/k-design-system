import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

// Decision 0017: KSettingsDialog, KSaveBar, KAvatarPicker.
void main() {
  Widget app(Widget child, {Size size = const Size(1024, 768)}) {
    return MaterialApp(
      home: KAdaptiveTheme(
        fontFamily: 'packages/k_design_tokens/Inter',
        child: KLocalization(
          locale: 'en',
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<KSettingsDialogSection> sections({bool dirty = false}) => [
    KSettingsDialogSection(
      id: 'profile',
      group: 'Agent',
      title: 'Profile',
      summary: 'Drop',
      dirty: dirty,
      child: const Text('Profile body'),
    ),
    const KSettingsDialogSection(
      id: 'runtime',
      group: 'Runtime',
      title: 'Runtime',
      status: KStatusTone.error,
      summary: 'Unavailable',
      child: Text('Runtime body'),
    ),
  ];

  testWidgets('wide: navigation beside the content', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(
        KSettingsDialog(
          title: 'Rocky',
          sections: sections(),
          onClose: () {},
          footer: KSaveBar(changes: 0, onSave: () {}),
        ),
        size: const Size(820, 640),
      ),
    );
    expect(find.text('Profile body'), findsOneWidget);
    expect(find.byType(KSidebar), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('k-settings-nav:runtime')));
    await tester.pumpAndSettle();
    expect(find.text('Runtime body'), findsOneWidget);
    expect(find.text('Profile body'), findsNothing);
    expect(tester.getSize(find.byType(KSettingsDialog)), const Size(820, 640));
  });

  testWidgets('compact: section list, detail and back', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(
        KSettingsDialog(title: 'Rocky', sections: sections(dirty: true)),
        size: const Size(390, 700),
      ),
    );
    expect(find.byType(KSidebar), findsNothing);
    expect(find.text('Drop'), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('k-settings-row:runtime')));
    await tester.pumpAndSettle();
    expect(find.text('Runtime body'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Runtime body'), findsNothing);
    expect(find.text('Drop'), findsOneWidget);
  });

  for (final detail in [false, true]) {
    testWidgets('phone drag from ${detail ? 'detail' : 'list'} dismisses', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => KSettingsDialog.show<void>(
                context: context,
                builder: (_) =>
                    KSettingsDialog(title: 'Rocky', sections: sections()),
              ),
              child: const Text('Open settings'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open settings'));
      await tester.pumpAndSettle();
      if (detail) {
        await tester.tap(find.byKey(const ValueKey('k-settings-row:profile')));
        await tester.pumpAndSettle();
      }
      await tester.fling(
        find.text(detail ? 'Profile body' : 'Drop'),
        const Offset(0, 400),
        1500,
      );
      await tester.pumpAndSettle();
      expect(find.byType(KSettingsDialog), findsNothing);
    });
  }

  testWidgets('save bar counts changes and saves', (tester) async {
    final log = <String>[];
    Future<void> pump(int changes) => tester.pumpWidget(
      app(
        KSaveBar(
          changes: changes,
          onSave: () => log.add('save'),
          onDiscard: () => log.add('discard'),
        ),
        size: const Size(600, 80),
      ),
    );
    await pump(0);
    expect(find.text('All changes saved'), findsOneWidget);
    await tester.tap(find.text('Save'));
    expect(log, isEmpty);
    await pump(2);
    expect(find.text('2 unsaved changes'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.tap(find.text('Save'));
    expect(log, ['discard', 'save']);
  });

  for (final width in [360.0, 393.0, 412.0]) {
    testWidgets('German save bar fits phone width $width', (tester) async {
      await tester.pumpWidget(
        app(
          KLocalization(
            locale: 'de',
            child: KSaveBar(changes: 0, onSave: () {}, onDiscard: () {}),
          ),
          size: Size(width, 200),
        ),
      );
      expect(tester.takeException(), isNull);
      final state = tester.getRect(find.text('Alles gespeichert'));
      final save = tester.getRect(find.text('Speichern'));
      expect(state.bottom, lessThanOrEqualTo(save.top));
    });
  }

  testWidgets('avatar picker reports shape and colour', (tester) async {
    String? shape;
    Color? color;
    await tester.pumpWidget(
      app(
        KAvatarPicker(
          shapes: const [
            KAvatarShape(id: 'circle', label: 'Circle', icon: SizedBox()),
            KAvatarShape(id: 'star', label: 'Star', icon: SizedBox()),
          ],
          colors: const [
            KAvatarColor(value: Color(0xFFF43F5E), label: 'Rose'),
            KAvatarColor(value: Color(0xFF3B82F6), label: 'Blue'),
          ],
          shape: 'circle',
          color: const Color(0xFFF43F5E),
          onShapeChanged: (value) => shape = value,
          onColorChanged: (value) => color = value,
        ),
        size: const Size(320, 240),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('k-avatar-shape:star')));
    await tester.tap(find.byKey(const ValueKey('k-avatar-color:Blue')));
    expect(shape, 'star');
    expect(color, const Color(0xFF3B82F6));
  });
}
