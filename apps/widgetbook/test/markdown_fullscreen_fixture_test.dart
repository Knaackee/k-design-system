import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/editor_fixtures.dart';
import 'package:k_design_widgetbook/markdown_fixtures.dart';

void main() {
  testWidgets('desktop gallery hover and scrollbars survive editor expansion', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _shell(MarkdownEditorDemoViewport(child: _deepEditorFixture())),
    );
    tester.widget<KMarkdownEditor>(find.byType(KMarkdownEditor)).onModeChanged!(
      KEditorMode.read,
    );
    await tester.pump();
    await tester.pump();
    ScrollController previewController() => tester
        .widget<SingleChildScrollView>(
          find
              .ancestor(
                of: find.byType(KMarkdownPreview, skipOffstage: false),
                matching: find.byType(
                  SingleChildScrollView,
                  skipOffstage: false,
                ),
              )
              .first,
        )
        .controller!;
    final inlinePreview = previewController();
    inlinePreview.jumpTo(inlinePreview.position.maxScrollExtent.clamp(0, 100));
    await tester.pump();
    final savedOffset = inlinePreview.offset;
    expect(savedOffset, greaterThan(0));
    tester.widget<KMarkdownEditor>(find.byType(KMarkdownEditor)).onModeChanged!(
      KEditorMode.source,
    );
    await tester.pump();
    await tester.pump();
    tester
        .state<TooltipState>(find.byTooltip('Expand editor'))
        .ensureTooltipVisible();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byTooltip('Expand editor'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.byType(KDialog), findsOneWidget);
    final expandedPreview = previewController();
    expect(expandedPreview, isNot(same(inlinePreview)));
    expect(expandedPreview.positions, hasLength(1));
    expect(expandedPreview.offset, closeTo(savedOffset, 0.01));
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is KIconButton && widget.icon == KIconName.minimize2,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    final returnedPreview = previewController();
    expect(returnedPreview, isNot(same(expandedPreview)));
    expect(returnedPreview.positions, hasLength(1));
    expect(returnedPreview.offset, closeTo(savedOffset, 0.01));
    semantics.dispose();
  });
}

Widget _shell(Widget editor) => MaterialApp(
  theme: kDesignTheme().copyWith(
    platform: TargetPlatform.windows,
    scrollbarTheme: const ScrollbarThemeData(
      thumbVisibility: WidgetStatePropertyAll(true),
      interactive: true,
    ),
  ),
  home: Scaffold(body: SizedBox(height: 420, child: editor)),
);

Widget _deepEditorFixture() {
  Widget child = const EditorFixture(markdown: true, compact: true);
  // Gallery addons can make the inline editor deeper than the popup route.
  for (var depth = 0; depth < 40; depth++) {
    final nested = child;
    child = Builder(builder: (_) => nested);
  }
  return child;
}
