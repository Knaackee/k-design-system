import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('packages/k_design_tokens/Inter');
    font.addFont(
      File(
        '../k_design_tokens/assets/fonts/InterVariable.ttf',
      ).readAsBytes().then(ByteData.sublistView),
    );
    await font.load();
  });
  const message =
      'Bereit für einen entspannteren Arbeitsalltag und mehr Umsatz?';
  Future<Size> measure(
    WidgetTester tester,
    KText text, {
    double scale = 1,
    double width = 340,
    bool bold = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(scale),
            boldText: bold,
          ),
          child: Center(
            child: SizedBox(width: width, child: text),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    return tester.getSize(find.text(text.data));
  }

  testWidgets('balancing keeps a fitting long word intact', (tester) async {
    const heading = 'Schön, dich kennenzulernen.';
    await measure(
      tester,
      const KText(
        heading,
        variant: KTextVariant.heading1,
        textWrap: KTextWrap.balance,
        align: TextAlign.center,
      ),
      width: 296,
    );
    final paragraph = tester.renderObject<RenderParagraph>(find.text(heading));
    final wordStart = heading.indexOf('kennenzulernen');
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: wordStart, extentOffset: heading.length),
    );
    expect(boxes, hasLength(1), reason: 'The final word must occupy one line');
  });

  testWidgets('multilingual headings preserve lines and fit phone and tablet', (
    tester,
  ) async {
    const examples = [
      message,
      'Ready for a calmer working day and more revenue?',
      'Prêt pour des journées plus sereines et un meilleur chiffre d’affaires ?',
      '¿Listo para una jornada laboral más relajada y mayores ingresos?',
    ];
    for (final text in examples) {
      for (final width in [340.0, 680.0]) {
        for (final scale in [1.0, 1.5]) {
          final reason = '$text; width=$width; scale=$scale';
          final natural = await measure(
            tester,
            KText(text, variant: KTextVariant.heading1),
            width: width,
            scale: scale,
          );
          final naturalParagraph = tester.renderObject<RenderParagraph>(
            find.byType(RichText),
          );
          final selection = TextSelection(
            baseOffset: 0,
            extentOffset: text.length,
          );
          final naturalLines = naturalParagraph
              .getBoxesForSelection(selection)
              .map((box) => box.top)
              .toSet()
              .length;
          final balanced = await measure(
            tester,
            KText(
              text,
              variant: KTextVariant.heading1,
              textWrap: KTextWrap.balance,
              align: TextAlign.center,
            ),
            width: width,
            scale: scale,
          );
          final paragraph = tester.renderObject<RenderParagraph>(
            find.byType(RichText),
          );
          final boxes = paragraph.getBoxesForSelection(selection);
          expect(
            boxes.map((box) => box.top).toSet().length,
            naturalLines,
            reason: reason,
          );
          expect(balanced.height, closeTo(natural.height, .1), reason: reason);
          expect(balanced.width, lessThanOrEqualTo(width), reason: reason);
          // Selection boxes include trailing spaces past a soft line break.
          // Check painted characters, not that invisible selection padding.
          final visibleBoxes = <TextBox>[];
          for (var i = 0; i < text.length; i++) {
            if (text[i].trim().isNotEmpty) {
              visibleBoxes.addAll(
                paragraph.getBoxesForSelection(
                  TextSelection(baseOffset: i, extentOffset: i + 1),
                ),
              );
            }
          }
          for (final box in visibleBoxes) {
            expect(box.left, greaterThanOrEqualTo(-.1), reason: reason);
            expect(
              box.right,
              lessThanOrEqualTo(balanced.width + .1),
              reason: reason,
            );
          }
          // Headings are capped at 1.4x (Decision 0010).
          expect(
            paragraph.textScaler.scale(10),
            closeTo(10 * (scale > 1.4 ? 1.4 : scale), 1e-9),
            reason: reason,
          );
        }
      }
    }
  });

  testWidgets('respects accessibility bold and non-inherited styles', (
    tester,
  ) async {
    for (final inherit in [true, false]) {
      final style = TextStyle(
        inherit: inherit,
        fontSize: 30,
        fontFamily: 'packages/k_design_tokens/Inter',
      );
      final natural = await measure(
        tester,
        KText(message, style: style),
        bold: true,
      );
      final balanced = await measure(
        tester,
        KText(message, style: style, textWrap: KTextWrap.balance),
        bold: true,
      );
      expect(balanced.height, closeTo(natural.height, .1));
      expect(balanced.width, lessThanOrEqualTo(natural.width));
    }
  });

  testWidgets('balances without extra lines or shrinking scaled fonts', (
    tester,
  ) async {
    for (final scale in [1.0, 1.5, 2.0]) {
      final natural = await measure(
        tester,
        const KText(message, variant: KTextVariant.heading1),
        scale: scale,
      );
      final balanced = await measure(
        tester,
        const KText(
          message,
          variant: KTextVariant.heading1,
          textWrap: KTextWrap.balance,
          align: TextAlign.center,
        ),
        scale: scale,
      );
      expect(balanced.height, closeTo(natural.height, .1));
      expect(balanced.width, lessThanOrEqualTo(natural.width));
      final paragraph = tester.renderObject<RenderParagraph>(
        find.byType(RichText),
      );
      expect(
        paragraph.textScaler.scale(10),
        closeTo(10 * (scale > 1.4 ? 1.4 : scale), 1e-9),
      );
      final textCenter = tester.getCenter(find.text(message)).dx;
      expect(textCenter, closeTo(400, .1));
    }
  });
  testWidgets(
    'default wrapping stays unchanged and explicit line breaks opt out',
    (tester) async {
      final normal = await measure(
        tester,
        const KText('First line\nSecond line'),
      );
      final balanced = await measure(
        tester,
        const KText('First line\nSecond line', textWrap: KTextWrap.balance),
      );
      expect(balanced, normal);
      expect(
        tester.widget<KText>(find.byType(KText)).textWrap,
        KTextWrap.balance,
      );
      await measure(tester, const KText(message));
      expect(tester.widget<KText>(find.byType(KText)).textWrap, KTextWrap.wrap);
    },
  );
  testWidgets('ellipsis and softWrap false retain original geometry', (
    tester,
  ) async {
    for (final softWrap in [true, false]) {
      final normal = await measure(
        tester,
        KText(
          message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: softWrap,
        ),
      );
      final balanced = await measure(
        tester,
        KText(
          message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: softWrap,
          textWrap: KTextWrap.balance,
        ),
      );
      expect(balanced, normal);
    }
  });
}
