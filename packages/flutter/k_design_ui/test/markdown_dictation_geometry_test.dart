import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/editors/k_markdown_dictation_overlay.dart';
import 'package:re_editor/re_editor.dart';

void main() {
  testWidgets(
    'saved-caret dots center on wrapped lines at large text and scroll',
    (tester) async {
      const source =
          'A long Markdown source line that wraps across the narrow phone editor.\n'
          'Second line\nThird line\nFourth line\nFifth line\nSixth line\n';
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final width in [1440.0, 393.0]) {
        tester.view.physicalSize = Size(width, 900);
        for (final scale in [1.0, 3.0]) {
          for (final state in [
            KDictationState.recording,
            KDictationState.processing,
          ]) {
            await tester.pumpWidget(
              MaterialApp(
                theme: kDesignTheme(),
                home: MediaQuery(
                  data: MediaQueryData(
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true,
                  ),
                  child: KAdaptiveTheme(
                    child: Scaffold(
                      body: SizedBox(
                        width: width,
                        height: 800,
                        child: KMarkdownEditor(
                          markdown: source,
                          contentMaxWidth: 720,
                          dictationState: state,
                          dictationOffset: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();
            await tester.pump();
            final overlayFinder = find.byType(KMarkdownDictationOverlay);
            final overlay = tester.widget<KMarkdownDictationOverlay>(
              overlayFinder,
            );

            void expectCentered() {
              final paragraph = overlay.paragraphs.value!.paragraphs.firstWhere(
                (value) => value.index == 0,
              );
              final caret = paragraph.getOffset(
                const TextPosition(offset: 40),
              )!;
              final scroll = overlay.scrollController;
              final origin = tester.getTopLeft(find.byType(CodeEditor));
              final expected =
                  origin +
                  paragraph.offset +
                  caret -
                  Offset(
                    scroll.horizontalScroller.hasClients
                        ? scroll.horizontalScroller.offset
                        : 0,
                    scroll.verticalScroller.hasClients
                        ? scroll.verticalScroller.offset
                        : 0,
                  );
              final dots = tester.getRect(find.byType(KDictationAnchor));
              expect(dots.left, closeTo(expected.dx, 0.01));
              expect(
                dots.center.dy,
                closeTo(expected.dy + paragraph.preferredLineHeight / 2, 0.01),
              );
            }

            expectCentered();
            final vertical = overlay.scrollController.verticalScroller;
            if (vertical.hasClients && vertical.position.maxScrollExtent > 0) {
              vertical.jumpTo(vertical.position.maxScrollExtent.clamp(0, 10));
              await tester.pump();
              await tester.pump();
              expectCentered();
            }
            tester
                .state<KCodeEditorState>(find.byType(KCodeEditor))
                .openSearch();
            await tester.pump();
            await tester.pump();
            expectCentered();
            expect(find.byType(KDictationAnchor), findsOneWidget);
            expect(tester.takeException(), isNull);
            expect(
              tester.state<KCodeEditorState>(find.byType(KCodeEditor)).value,
              source,
            );
            await tester.pumpWidget(const SizedBox.shrink());
          }
        }
      }
    },
  );
}
