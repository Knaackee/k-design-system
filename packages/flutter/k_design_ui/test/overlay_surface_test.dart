import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final sheet in [false, true]) {
    testWidgets('overlay $sheet overrides only its surface', (tester) async {
      const overlay = Color(0xff142635);
      const raised = Color(0xffeeeeee);
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(
            tokenTransform: (tokens) => tokens.copyWith(
              colorSurfaceOverlay: overlay,
              colorSurfaceRaised: raised,
            ),
          ),
          home: Scaffold(
            body: sheet
                ? const KBottomSheet(title: Text('Sheet'), child: KInput())
                : const KDialog(title: Text('Dialog'), child: KInput()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration!.fillColor,
        raised,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => sheet
              ? widget is Material && widget.color == overlay
              : widget is DecoratedBox &&
                    widget.decoration is BoxDecoration &&
                    (widget.decoration as BoxDecoration).color == overlay,
        ),
        findsOneWidget,
      );
    });
  }
}
