import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets(
    'description truncation preserves full semantics and opt-in default',
    (tester) async {
      const url =
          'https://booking.example.test/u/a-long-public-booking-address';
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Widget host({int? maxLines}) => MaterialApp(
        home: KAdaptiveTheme(
          overrides: const KAdaptiveOverrides(style: KStyle.apple),
          child: Scaffold(
            body: KPage(
              children: [
                KListItem(
                  title: 'Online',
                  description: url,
                  descriptionMaxLines: maxLines,
                  disclosure: false,
                  onPressed: () {},
                  trailing: KButton(label: 'Adresse ändern', onPressed: () {}),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final description = find.text(url);
      final wrappedHeight = tester.getSize(description).height;
      expect(
        tester.renderObject<RenderParagraph>(description).maxLines,
        isNull,
      );

      await tester.pumpWidget(host(maxLines: 1));
      await tester.pumpAndSettle();
      final paragraph = tester.renderObject<RenderParagraph>(description);
      expect(paragraph.maxLines, 1);
      expect(paragraph.overflow, TextOverflow.ellipsis);
      expect(paragraph.didExceedMaxLines, isTrue);
      expect(tester.getSize(description).height, lessThan(wrappedHeight));
      expect(find.bySemanticsLabel(RegExp(RegExp.escape(url))), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}
