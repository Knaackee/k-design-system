import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final rootFont = File(
      'packages/flutter/k_design_tokens/assets/fonts/InterVariable.ttf',
    );
    final font = rootFont.existsSync()
        ? rootFont
        : File('../k_design_tokens/assets/fonts/InterVariable.ttf');
    final loader = FontLoader('packages/k_design_tokens/Inter');
    loader.addFont(font.readAsBytes().then(ByteData.sublistView));
    await loader.load();
  });
  testWidgets('phone toast keeps readable compact geometry without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 343,
              child: KToast(
                title: const Text('Changes saved'),
                description: const Text(
                  'Your workspace settings are up to date.',
                ),
                icon: const KIcon(KIconName.circleCheck),
                action: KButton(label: 'View', onPressed: () {}),
                onDismiss: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(KToast)).height, lessThan(120));
    expect(tester.takeException(), isNull);
  });
  testWidgets('queued notifications preserve order and dismiss exactly once', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Builder(
          builder: (c) {
            context = c;
            return const Scaffold(body: Text('Page'));
          },
        ),
      ),
    );
    var dismissals = 0;
    final first = KToast.show(
      context: context,
      title: const Text('First'),
      duration: Duration.zero,
      onDismiss: () => dismissals++,
    );
    final second = KSnackbar.show(
      context: context,
      message: const Text('Second'),
      duration: Duration.zero,
    );
    await tester.pump();
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsNothing);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('First'), findsOneWidget);
    first.dismiss();
    first.dismiss();
    await tester.pump();
    expect(dismissals, 1);
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
    second.dismiss();
    await tester.pump();
  });
  testWidgets('timer dismisses and close action respects consumer callback', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Builder(
          builder: (c) {
            context = c;
            return const Scaffold();
          },
        ),
      ),
    );
    var calls = 0;
    KToast.show(
      context: context,
      title: const Text('Timed'),
      duration: const Duration(milliseconds: 100),
      onDismiss: () => calls++,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 101));
    expect(find.text('Timed'), findsNothing);
    expect(calls, 1);
    KSnackbar.show(
      context: context,
      message: const Text('Closable'),
      duration: Duration.zero,
      dismissLabel: 'Close message',
      onDismiss: () => calls++,
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Close message'));
    await tester.pump();
    expect(find.text('Closable'), findsNothing);
    expect(calls, 2);
  });
}
