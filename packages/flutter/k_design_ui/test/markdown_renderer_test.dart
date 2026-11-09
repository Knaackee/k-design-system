import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

Widget shell(Widget child) => MaterialApp(
  theme: ThemeData(extensions: [KDesignTokens.orbitLight]),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets(
    'headings cap text scale at heading maximum and body keeps body maximum',
    (tester) async {
      await tester.pumpWidget(
        shell(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(4)),
            child: const KMarkdownRenderer(
              content: '# Heading\n\nBody text',
              selectable: false,
            ),
          ),
        ),
      );
      final headingContext = tester.element(find.text('Heading'));
      final bodyContext = tester.element(find.text('Body text'));
      expect(
        MediaQuery.textScalerOf(headingContext).scale(10),
        10 * KDesignTokens.orbitLight.textScaleMaxHeading,
      );
      expect(
        MediaQuery.textScalerOf(bodyContext).scale(10),
        10 * KDesignTokens.orbitLight.textScaleMaxBody,
      );
    },
  );

  testWidgets('shared fixtures fit narrow windows at large text sizes', (
    tester,
  ) async {
    for (final scale in [1.0, 3.0]) {
      for (final file in Directory(
        '../../../fixtures/markdown',
      ).listSync().whereType<File>()) {
        if (!file.path.endsWith('.md')) continue;
        await tester.pumpWidget(
          shell(
            MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: SizedBox(
                width: 360,
                child: KMarkdownRenderer(
                  content: file.readAsStringSync(),
                  imageBuilder: (_, alt, title) => Text(alt ?? ''),
                  onCopy: (_) {},
                ),
              ),
            ),
          ),
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${file.path} at $scale',
        );
      }
    }
  });

  testWidgets('table copy sends TSV to consumer', (tester) async {
    String? copied;
    await tester.pumpWidget(
      shell(
        KMarkdownRenderer(
          content: '| A | B |\n| --- | --- |\n| One | Two |',
          onCopy: (text) => copied = text,
        ),
      ),
    );
    await tester.tap(find.widgetWithText(KButton, 'Copy'));
    expect(copied, 'A\tB\nOne\tTwo');
  });

  testWidgets('chat tables fill available width and scroll only when wider', (
    tester,
  ) async {
    Future<void> pump(String cell) => tester.pumpWidget(
      shell(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 360,
            child: KMarkdownRenderer(
              content: '| A | B |\n| --- | --- |\n| $cell | Two |',
              profile: KMarkdownProfile.chat,
              selectable: false,
            ),
          ),
        ),
      ),
    );
    final table = find.byType(Table);
    final horizontal = find.byWidgetPredicate(
      (widget) =>
          widget is SingleChildScrollView &&
          widget.scrollDirection == Axis.horizontal,
    );
    await pump('One');
    expect(tester.getSize(table).width, 360);
    expect(tester.widget<Table>(table).border!.bottom.style, BorderStyle.solid);
    expect(horizontal, findsOneWidget);

    await pump(List.filled(80, 'wide').join());
    expect(tester.getSize(horizontal).width, 360);
    expect(tester.getSize(table).width, greaterThan(360));
    final scroll = tester.state<ScrollableState>(
      find.descendant(of: horizontal, matching: find.byType(Scrollable)),
    );
    expect(scroll.position.maxScrollExtent, greaterThan(0));
    await tester.drag(horizontal, const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared streaming frames commit only complete Markdown blocks', (
    tester,
  ) async {
    final sequence =
        jsonDecode(
              File(
                '../../../fixtures/markdown/streaming-sequence.json',
              ).readAsStringSync(),
            )
            as List;
    Uri? link;
    String? copied;
    for (final frame in sequence.cast<Map<String, dynamic>>()) {
      final id = frame['id'] as String;
      await tester.pumpWidget(
        shell(
          KMarkdownRenderer(
            content: frame['content'] as String,
            streaming: frame['streaming'] as bool,
            selectable: false,
            onLinkActivate: (uri) => link = uri,
            onCopy: (value) => copied = value,
          ),
        ),
      );
      expect(find.text('Live-Bericht'), findsOneWidget, reason: id);
      expect(tester.takeException(), isNull, reason: id);
      switch (id) {
        case 'open-emphasis':
          expect(find.text('**Ergebnis'), findsOneWidget);
        case 'closed-emphasis':
          expect(find.textContaining('Ergebnis:'), findsOneWidget);
          expect(find.textContaining('**'), findsNothing);
        case 'open-link':
          expect(
            find.text('[Dokumentation](https://example.org/d'),
            findsOneWidget,
          );
          await tester.tap(find.text('[Dokumentation](https://example.org/d'));
          expect(link, isNull);
        case 'closed-link':
          await tester.tap(find.text('Dokumentation'));
          expect(link.toString(), 'https://example.org/docs');
        case 'open-code':
          expect(find.text('typescript'), findsOneWidget);
          await tester.tap(find.widgetWithText(KButton, 'Copy'));
          expect(copied, 'const status = "be');
        case 'open-table':
          expect(find.byType(Table), findsNothing);
          expect(find.textContaining('| Web |'), findsOneWidget);
        case 'closed-table' || 'complete':
          expect(find.byType(Table), findsOneWidget);
          expect(find.text('Bereit'), findsNWidgets(2));
      }
    }
  });

  testWidgets('switching streaming off renders the unchanged final input', (
    tester,
  ) async {
    const content = 'Earlier\r\n\r\n[Open](https://example.org)';
    Future<void> pump(bool streaming) => tester.pumpWidget(
      shell(
        KMarkdownRenderer(
          content: content,
          streaming: streaming,
          selectable: false,
        ),
      ),
    );

    await pump(true);
    expect(find.text('Earlier'), findsOneWidget);
    expect(find.text('[Open](https://example.org)'), findsOneWidget);
    await pump(false);
    expect(find.text('Earlier'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('[Open](https://example.org)'), findsNothing);
  });

  testWidgets('copy code emits host event and preserves source', (
    tester,
  ) async {
    String? copied;
    await tester.pumpWidget(
      shell(
        KMarkdownRenderer(
          content: '```js\nconst answer = 42;\n```',
          onCopy: (value) => copied = value,
        ),
      ),
    );
    await tester.tap(find.widgetWithText(KButton, 'Copy'));
    expect(copied, 'const answer = 42;');
    expect(tester.takeException(), isNull);
  });

  testWidgets('HTML omitted and unsafe image never reaches host', (
    tester,
  ) async {
    var images = 0;
    await tester.pumpWidget(
      shell(
        KMarkdownRenderer(
          content:
              '<script>bad()</script>\n\n![bad](javascript:bad)\n\nSafe <b>text</b>',
          imageBuilder: (_, alt, title) {
            images++;
            return Text(alt ?? 'image');
          },
        ),
      ),
    );
    expect(images, 0);
    expect(find.textContaining('bad()'), findsNothing);
    expect(find.textContaining('<b>'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('allowlist unwraps headings and removes images', (tester) async {
    await tester.pumpWidget(
      shell(
        const KMarkdownRenderer(
          content: '# Title\n\n![alt](https://example.com/a.png)',
          allowedElements: {'p'},
          selectable: false,
        ),
      ),
    );
    expect(find.text('Title'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets(
    'task lists are read only and tables have only horizontal dividers',
    (tester) async {
      await tester.pumpWidget(
        shell(
          const KMarkdownRenderer(
            content:
                '- [x] Complete\n- [ ] Pending\n\n| A | B |\n| --- | ---: |\n| One | 2 |',
          ),
        ),
      );
      final boxes = tester.widgetList<KCheckbox>(find.byType(KCheckbox));
      expect(boxes.length, 2);
      expect(boxes.every((box) => box.onChanged == null), isTrue);
      final table = tester.widget<Table>(find.byType(Table));
      expect(table.border!.verticalInside, BorderSide.none);
      expect(table.border!.horizontalInside.style, BorderStyle.solid);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('GFM alerts reuse KAlert', (tester) async {
    await tester.pumpWidget(
      shell(const KMarkdownRenderer(content: '> [!WARNING]\n> Keep a backup.')),
    );
    expect(find.byType(KAlert), findsOneWidget);
    expect(
      tester.widget<KAlert>(find.byType(KAlert)).tone,
      KStatusTone.warning,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview uses host loading and empty content', (tester) async {
    await tester.pumpWidget(
      shell(
        const KMarkdownPreview(
          content: '',
          loading: true,
          loadingContent: Text('Loading document'),
          emptyContent: Text('Empty document'),
        ),
      ),
    );
    expect(find.text('Loading document'), findsOneWidget);
    await tester.pumpWidget(
      shell(
        const KMarkdownPreview(
          content: '',
          emptyContent: Text('Empty document'),
        ),
      ),
    );
    expect(find.text('Empty document'), findsOneWidget);
  });
}
