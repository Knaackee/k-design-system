import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets(
    'snackbar custom placement preserves width and animates opted-in exit',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Builder(
            builder: (value) {
              context = value;
              return const Scaffold();
            },
          ),
        ),
      );
      var dismissed = 0;
      final heights = <double>[];
      final focus = FocusNode();
      addTearDown(focus.dispose);
      final snackbar = KSnackbar.show(
        context: context,
        message: const Text('Änderungen übernommen'),
        action: Focus(focusNode: focus, child: const Text('Action')),
        onHeightChanged: heights.add,
        bottomOffset: 100,
        maxWidth: 340,
        animateExit: true,
        duration: Duration.zero,
        onDismiss: () => dismissed++,
      );
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byType(KSnackbar));
      expect(rect.width, 340);
      expect(rect.bottom, 744);
      expect(heights.last, rect.height);
      focus.requestFocus();
      await tester.pump();
      final second = KSnackbar.show(
        context: context,
        message: const Text('Next'),
        duration: Duration.zero,
      );
      snackbar.dismiss();
      focus.unfocus();
      snackbar.dismiss();
      await tester.pump();
      expect(dismissed, 1);
      expect(find.byType(KSnackbar), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Next'), findsOneWidget);
      expect(heights.last, 0);
      second.dismiss();
      await tester.pump();
      expect(find.byType(KSnackbar), findsNothing);
    },
  );
  testWidgets('reduced motion skips opted-in snackbar exit', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Builder(
          builder: (value) {
            context = value;
            return const Scaffold();
          },
        ),
      ),
    );
    final snackbar = KSnackbar.show(
      context: context,
      message: const Text('Saved'),
      animateExit: true,
      duration: Duration.zero,
    );
    await tester.pump();
    snackbar.dismiss();
    await tester.pump();
    expect(find.byType(KSnackbar), findsNothing);
  });
}
