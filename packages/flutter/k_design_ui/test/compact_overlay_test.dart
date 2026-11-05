import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final sheet in [false, true]) {
    for (final density in KDensity.values) {
      for (final scale in [1.0, 1.8]) {
        testWidgets('compact $sheet $density $scale keeps chrome fixed', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(390, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final theme = kDesignTheme(
            brightness: scale == 1 ? Brightness.light : Brightness.dark,
            configuration: KDesignConfiguration(density: density),
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Builder(
                builder: (context) => Scaffold(
                  body: KButton(
                    label: 'Open',
                    onPressed: () {
                      final content = KStack(
                        children: [
                          for (var i = 0; i < 20; i++)
                            KField(label: 'Field $i', child: const KInput()),
                        ],
                      );
                      final actions = KButton(
                        label: 'Save',
                        onPressed: () => Navigator.of(context).pop(),
                      );
                      if (sheet) {
                        KBottomSheet.show<void>(
                          context: context,
                          title: const KText('Settings'),
                          actions: actions,
                          child: content,
                        );
                      } else {
                        KDialog.show<void>(
                          context: context,
                          title: const KText('Settings'),
                          actions: actions,
                          child: content,
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final header = tester.getTopLeft(find.text('Settings'));
          final footer = tester.getTopLeft(find.text('Save'));
          expect(find.text('Save').hitTestable(), findsOneWidget);
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, -500),
          );
          await tester.pumpAndSettle();
          expect(tester.getTopLeft(find.text('Settings')), header);
          expect(tester.getTopLeft(find.text('Save')), footer);
          tester.view.viewInsets = const FakeViewPadding(bottom: 240);
          await tester.pumpAndSettle();
          expect(tester.getBottomLeft(find.text('Save')).dy, lessThan(400));
          expect(find.text('Save').hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('Save'));
          await tester.pumpAndSettle();
          expect(find.text('Settings'), findsNothing);
          expect(find.text('Open').hitTestable(), findsOneWidget);
        });
      }
    }
  }

  testWidgets('compact adaptive sheet stays content-sized', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: KAdaptiveDialog(
            expandBody: false,
            title: const KText('Details'),
            actions: KButton(label: 'Save', onPressed: () {}),
            child: const KText('Short content'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(KBottomSheet)).height, lessThan(400));
    expect(find.text('Save').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
