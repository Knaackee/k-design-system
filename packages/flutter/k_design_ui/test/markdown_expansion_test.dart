import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:re_editor/re_editor.dart';
import 'package:k_design_ui/src/editors/k_markdown_dictation_overlay.dart';

void main() {
  testWidgets(
    'reparenting retires semantics for one frame and preserves state',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final key = GlobalKey<KMarkdownEditorState>();
        await tester.pumpWidget(
          _shell(
            KMarkdownEditor(
              key: key,
              markdown: 'Draft',
              showExpandButton: true,
            ),
          ),
        );
        final source = key.currentState!.sourceEditor;
        bool excludesSource() => tester
            .widgetList<ExcludeSemantics>(
              find.ancestor(
                of: find.byType(KCodeEditor),
                matching: find.byType(ExcludeSemantics),
              ),
            )
            .any((widget) => widget.excluding);
        expect(excludesSource(), isFalse);

        await tester.tap(find.byTooltip('Expand editor'));
        await tester.pump();
        expect(excludesSource(), kIsWeb);
        expect(key.currentState!.sourceEditor, same(source));
        await tester.pump();
        expect(excludesSource(), isFalse);
        expect(find.bySemanticsLabel('Markdown editor'), findsWidgets);

        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(excludesSource(), kIsWeb);
        expect(key.currentState!.sourceEditor, same(source));
        await tester.pump();
        expect(excludesSource(), isFalse);
        expect(find.bySemanticsLabel('Markdown editor'), findsWidgets);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('expansion is optional by default', (tester) async {
    await tester.pumpWidget(_shell(const KMarkdownEditor(markdown: 'Draft')));
    expect(find.byTooltip('Expand editor'), findsNothing);
  });

  testWidgets('compact editor shows formatting only while expanded', (
    tester,
  ) async {
    final key = GlobalKey<KMarkdownEditorState>();
    await tester.pumpWidget(
      _shell(
        KMarkdownEditor(
          key: key,
          markdown: 'A compact draft',
          showExpandButton: true,
          showFixedToolbar: false,
          showFloatingToolbar: false,
          showModeSwitcher: false,
          showSearchButton: false,
          dictationState: KDictationState.ready,
          onDictationPressed: () {},
        ),
      ),
    );
    expect(find.byType(KEditorFormatBar), findsNothing);
    final source = key.currentState!.sourceEditor;
    final expand = tester.getRect(find.byTooltip('Expand editor'));
    final field = tester.getRect(find.byType(KMarkdownEditor));
    expect(expand.right, greaterThan(field.center.dx));
    expect(expand.bottom, greaterThan(field.center.dy));
    final sourceRect = tester.getRect(find.byType(KCodeEditor));
    expect(sourceRect.contains(expand.topLeft), isTrue);
    expect(sourceRect.contains(expand.bottomRight), isTrue);
    final sourcePadding = tester
        .widget<CodeEditor>(find.byType(CodeEditor))
        .padding!;
    expect(
      sourcePadding.resolve(TextDirection.ltr).bottom,
      greaterThan(expand.height),
    );
    expect(
      find.ancestor(
        of: find.byTooltip('Expand editor'),
        matching: find.byType(PositionedDirectional),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Expand editor'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(KEditorFormatBar), findsOneWidget);
    expect(
      tester.widget<KEditorFormatBar>(find.byType(KEditorFormatBar)).actions,
      kDefaultMarkdownFormatActions,
    );
    expect(find.byType(KDictationAction), findsOneWidget);
    final collapse = find.byWidgetPredicate(
      (widget) => widget is KIconButton && widget.icon == KIconName.minimize2,
    );
    expect(
      find.ancestor(of: collapse, matching: find.byType(KEditorFormatBar)),
      findsNothing,
    );
    expect(
      tester.getRect(collapse).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(KEditorFormatBar)).top),
    );
    expect(key.currentState!.sourceEditor, same(source));
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(key.currentState!.sourceEditor, same(source));
    expect(find.byType(KEditorFormatBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [360.0, 1440.0]) {
    testWidgets('last source line clears floating button at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _shell(
          KMarkdownEditor(
            markdown: List.generate(
              60,
              (index) => 'Document line $index',
            ).join('\n'),
            showExpandButton: true,
            showFixedToolbar: false,
            showFloatingToolbar: false,
            showModeSwitcher: false,
            showSearchButton: false,
          ),
        ),
      );
      Future<void> checkLastLine(String label) async {
        await tester.pump();
        await tester.pump();
        final geometry = tester.widget<KMarkdownSourceGeometry>(
          find.byType(KMarkdownSourceGeometry),
        );
        final scroll = geometry.scrollController.verticalScroller;
        scroll.jumpTo(scroll.position.maxScrollExtent);
        await tester.pump();
        await tester.pump();
        final paragraph = geometry.paragraphs.value!.paragraphs.lastWhere(
          (value) => value.index == 59,
        );
        final origin = tester.getTopLeft(find.byType(CodeEditor));
        final lastLineBottom =
            origin.dy +
            paragraph.offset.dy +
            paragraph.preferredLineHeight -
            scroll.offset;
        final tokens = Theme.of(
          tester.element(find.byType(KCodeEditor)),
        ).extension<KDesignTokens>()!;
        final button = tester.getRect(
          find.byWidgetPredicate(
            (widget) =>
                widget is KIconButton &&
                widget.icon ==
                    (label == 'Expand editor'
                        ? KIconName.maximize2
                        : KIconName.minimize2),
          ),
        );
        expect(
          lastLineBottom,
          lessThanOrEqualTo(button.top - tokens.spaceSmallInset),
        );
        expect(tester.takeException(), isNull);
      }

      await checkLastLine('Expand editor');
      await tester.tap(find.byTooltip('Expand editor'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await checkLastLine('Return to editor');
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await checkLastLine('Expand editor');
    });
  }

  testWidgets('host updates and removal remain safe while expanded', (
    tester,
  ) async {
    final key = GlobalKey<KMarkdownEditorState>();
    var visible = true;
    var dictation = KDictationState.ready;
    late StateSetter update;
    await tester.pumpWidget(
      _shell(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return visible
                ? KMarkdownEditor(
                    key: key,
                    markdown: 'Draft',
                    showExpandButton: true,
                    dictationState: dictation,
                  )
                : const SizedBox.shrink();
          },
        ),
      ),
    );
    final editor = key.currentState!.sourceEditor;
    await tester.tap(find.byTooltip('Expand editor'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    update(() => dictation = KDictationState.processing);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(key.currentState!.sourceEditor, same(editor));
    expect(
      tester.widget<KDictationAction>(find.byType(KDictationAction)).state,
      KDictationState.processing,
    );
    update(() => visible = false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(KDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [360.0, 768.0, 1440.0]) {
    testWidgets(
      'one editor retains history, selection and dictation at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 852);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey<KMarkdownEditorState>();
        await tester.pumpWidget(
          _shell(
            KMarkdownEditor(
              key: key,
              markdown: 'alpha beta',
              showExpandButton: true,
              dictationState: KDictationState.recording,
            ),
          ),
        );
        final editor = key.currentState!.sourceEditor!;
        editor.replaceRange(10, 10, ' gamma');
        editor.setSelection(const KEditorSelection(anchor: 6, head: 10));
        await tester.pump();
        final selection = editor.selection;
        final bar = tester
            .widgetList<KEditorFormatBar>(find.byType(KEditorFormatBar))
            .first;
        expect(bar.leadingAction, isA<KDictationAction>());
        expect(bar.trailingAction, isNull);
        expect(
          find.ancestor(
            of: find.byTooltip('Expand editor'),
            matching: find.byType(KEditorFormatBar),
          ),
          findsNothing,
        );
        expect(
          tester.getRect(find.byTooltip('Expand editor')).bottom,
          lessThanOrEqualTo(
            tester.getRect(find.byType(KEditorFormatBar).first).top,
          ),
        );
        await tester.tap(find.byTooltip('Expand editor'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(KCodeEditor), findsOneWidget);
        expect(key.currentState!.sourceEditor, same(editor));
        expect(editor.selection, selection);
        expect(editor.value, 'alpha beta gamma');
        expect(find.byType(KDictationAction), findsOneWidget);
        expect(tester.getSize(find.byType(KDialog)).width, width);
        expect(
          key.currentState!.insertDictation('spoken', selection: selection),
          isTrue,
        );
        await tester.pump();
        expect(editor.value, 'alpha spoken gamma');
        editor.undo();
        await tester.pump();
        expect(editor.value, 'alpha beta gamma');
        // System back closes the full-screen route and returns the same editor.
        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(KDialog), findsNothing);
        expect(find.byType(KCodeEditor), findsOneWidget);
        expect(key.currentState!.sourceEditor, same(editor));
        // re_editor also records selection changes after an undo. Walk those
        // selection-only records to verify the pre-expansion document history.
        for (var step = 0; step < 5 && editor.value != 'alpha beta'; step++) {
          editor.undo();
          await tester.pump();
        }
        expect(editor.value, 'alpha beta');
        for (
          var step = 0;
          step < 5 && editor.value != 'alpha beta gamma';
          step++
        ) {
          editor.redo();
          await tester.pump();
        }
        expect(editor.value, 'alpha beta gamma');
        await tester.tap(find.byTooltip('Expand editor'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final collapse = find.byWidgetPredicate(
          (widget) =>
              widget is KIconButton && widget.icon == KIconName.minimize2,
        );
        await tester.tap(collapse);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(key.currentState!.sourceEditor, same(editor));
        expect(editor.value, 'alpha beta gamma');
        expect(tester.takeException(), isNull);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      },
    );
  }
}

Widget _shell(Widget editor) => MaterialApp(
  theme: kDesignTheme(),
  home: Scaffold(body: SizedBox(height: 420, child: editor)),
);
