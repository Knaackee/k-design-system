import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:re_editor/re_editor.dart';

void main() {
  testWidgets('Markdown preview and source share the content width', (
    tester,
  ) async {
    for (final contentMaxWidth in <double?>[400, null]) {
      Widget shell(KEditorMode mode) => _Shell(
        width: 700,
        child: KMarkdownEditor(
          markdown: '# Preview',
          contentMaxWidth: contentMaxWidth,
          mode: mode,
        ),
      );

      await tester.pumpWidget(shell(KEditorMode.source));
      final source = tester.getRect(find.byType(CodeEditor));
      await tester.pumpWidget(shell(KEditorMode.read));
      final preview = tester.getRect(
        find
            .ancestor(
              of: find.byType(KMarkdownPreview),
              matching: find.byType(SingleChildScrollView),
            )
            .first,
      );

      expect(preview.width, contentMaxWidth ?? 700);
      expect(preview.width, source.width);
      expect(preview.center.dx, source.center.dx);
    }
  });

  testWidgets(
    'dictation leads the bottom format actions on compact and wide editors',
    (tester) async {
      for (final width in [420.0, 700.0]) {
        for (final showFixedToolbar in [true, false]) {
          await tester.pumpWidget(
            _Shell(
              width: width,
              child: KMarkdownEditor(
                markdown: 'alpha beta',
                showFixedToolbar: showFixedToolbar,
                dictationState: KDictationState.ready,
                onDictationPressed: () {},
              ),
            ),
          );
          final bar = tester.widget<KEditorFormatBar>(
            find.byType(KEditorFormatBar),
          );
          expect(bar.leadingAction, isA<KDictationAction>());
          expect(bar.trailingAction, isNull);
          expect(
            bar.actions,
            showFixedToolbar ? kDefaultMarkdownFormatActions : isEmpty,
          );
          expect(find.byType(KDictationAction), findsOneWidget);
          expect(
            tester.getTopLeft(find.byType(KEditorFormatBar)).dy,
            greaterThanOrEqualTo(
              tester.getBottomLeft(find.byType(KCodeEditor)).dy,
            ),
          );
          final source = tester.state<KCodeEditorState>(
            find.byType(KCodeEditor),
          );
          source.replaceRange(
            0,
            0,
            '',
            selection: const KEditorSelection(anchor: 0, head: 5),
          );
          await tester.pump();
          final bars = tester.widgetList<KEditorFormatBar>(
            find.byType(KEditorFormatBar),
          );
          expect(bars, hasLength(2));
          expect(bars.where((bar) => bar.leadingAction != null), hasLength(1));
          expect(bars.where((bar) => bar.trailingAction != null), isEmpty);
          expect(find.byType(KDictationAction), findsOneWidget);
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pump(const Duration(milliseconds: 120));
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    },
  );

  testWidgets(
    'markdown dictation saves its insertion point before caret moves',
    (tester) async {
      final key = GlobalKey<KMarkdownEditorState>();
      var dictation = KDictationState.ready;
      String? changed;
      await tester.pumpWidget(
        _Shell(
          child: StatefulBuilder(
            builder: (context, setState) => KMarkdownEditor(
              key: key,
              markdown: 'alpha beta',
              dictationState: dictation,
              onDictationPressed: () =>
                  setState(() => dictation = KDictationState.recording),
              onChanged: (value, _) => changed = value,
            ),
          ),
        ),
      );
      final source = tester.state<KCodeEditorState>(find.byType(KCodeEditor));
      source.replaceRange(6, 6, '');
      await tester.pump();
      await tester.tap(find.byTooltip('Dictate'));
      await tester.pump();
      source.replaceRange(0, 0, '');
      await tester.pump();
      key.currentState!.insertDictation('voice ');
      await tester.pump();
      expect(changed, 'alpha voice beta');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'markdown dictation stays visual and inserts with undo and collaboration',
    (tester) async {
      final key = GlobalKey<KMarkdownEditorState>();
      final adapter = _TestAdapter('alpha beta');
      var state = KDictationState.ready;
      late StateSetter update;
      await tester.pumpWidget(
        _Shell(
          child: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return KMarkdownEditor(
                key: key,
                markdown: '',
                collaborationAdapter: adapter,
                dictationState: state,
                dictationOffset: 6,
                onDictationPressed: () =>
                    setState(() => state = KDictationState.recording),
              );
            },
          ),
        ),
      );
      await tester.tap(find.byTooltip('Dictate'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(KDictationAnchor), findsOneWidget);
      expect(adapter.localTransactions, isEmpty);
      expect(
        tester.state<KCodeEditorState>(find.byType(KCodeEditor)).value,
        'alpha beta',
      );
      update(() => state = KDictationState.processing);
      await tester.pump();
      expect(find.byType(KDictationAnchor), findsOneWidget);
      key.currentState!.insertDictation(
        'voice ',
        selection: const KEditorSelection(anchor: 6, head: 6),
      );
      update(() => state = KDictationState.ready);
      await tester.pump();
      expect(adapter.localTransactions.last.value, 'alpha voice beta');
      expect(find.byType(KDictationAnchor), findsNothing);
      await tester.tap(find.byTooltip('Undo'));
      await tester.pump();
      expect(adapter.localTransactions.last.value, 'alpha beta');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpWidget(const SizedBox.shrink());
      adapter.dispose();
    },
  );

  testWidgets('read and read-only markdown suppress dictation', (tester) async {
    for (final mode in [KEditorMode.source, KEditorMode.read]) {
      final key = GlobalKey<KMarkdownEditorState>();
      final changes = <String>[];
      await tester.pumpWidget(
        _Shell(
          child: KMarkdownEditor(
            key: key,
            markdown: 'alpha',
            mode: mode,
            readOnly: mode == KEditorMode.source,
            dictationState: KDictationState.recording,
            onDictationPressed: () {},
            onChanged: (value, _) => changes.add(value),
          ),
        ),
      );
      key.currentState!.insertDictation('voice');
      await tester.pump();
      expect(find.byType(KDictationAction), findsNothing);
      expect(find.byType(KDictationAnchor), findsNothing);
      expect(changes, isEmpty);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('code editor labels changes and protects remote text from undo', (
    tester,
  ) async {
    final key = GlobalKey<KCodeEditorState>();
    final adapter = _TestAdapter('const ready = false;');
    final changes = <KEditorTransaction>[];

    await tester.pumpWidget(
      _Shell(
        child: KCodeEditor(
          key: key,
          value: '',
          collaborationAdapter: adapter,
          onChanged: (_, transaction) => changes.add(transaction),
        ),
      ),
    );

    expect(key.currentState?.value, 'const ready = false;');
    key.currentState?.replaceRange(14, 19, 'true');
    await tester.pump();

    expect(key.currentState?.value, 'const ready = true;');
    expect(changes.single.origin, KEditorTransactionOrigin.local);
    expect(adapter.localTransactions.single.value, 'const ready = true;');

    adapter.remote('const ready = "remote";');
    await tester.pump();

    expect(key.currentState?.value, 'const ready = "remote";');
    expect(changes, hasLength(2));
    expect(changes.last.origin, KEditorTransactionOrigin.remote);
    expect(adapter.localTransactions, hasLength(1));

    key.currentState?.undo();
    await tester.pump();
    expect(key.currentState?.value, 'const ready = "remote";');
    expect(changes, hasLength(2));

    key.currentState?.replaceRange(0, 0, '// ');
    key.currentState?.undo();
    await tester.pump();
    expect(key.currentState?.value, 'const ready = "remote";');
    expect(changes, hasLength(4));
    expect(adapter.localTransactions, hasLength(3));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Markdown formatting follows snapshot selection after reconnect',
    (tester) async {
      final key = GlobalKey<KMarkdownEditorState>();
      final adapter = _TestAdapter(
        'Alpha beta',
        selection: const KEditorSelection(anchor: 5, head: 0),
      );
      final reconnect = _TestAdapter(
        'Zulu alpha',
        selection: const KEditorSelection(anchor: 100, head: 5),
      );
      final changes = <KEditorTransaction>[];
      Widget editor(KEditorCollaborationAdapter value) => _Shell(
        child: KMarkdownEditor(
          key: key,
          markdown: '',
          collaborationAdapter: value,
          showFloatingToolbar: false,
          onChanged: (_, transaction) => changes.add(transaction),
        ),
      );

      await tester.pumpWidget(editor(adapter));
      expect(
        key.currentState!.selection,
        const KEditorSelection(anchor: 5, head: 0),
      );
      adapter.remote(
        'Alpha beta',
        selection: const KEditorSelection(anchor: 6, head: 10),
      );
      await tester.pump();
      expect(
        key.currentState!.selection,
        const KEditorSelection(anchor: 6, head: 10),
      );
      expect(changes, isEmpty);

      await tester.pumpWidget(editor(reconnect));
      expect(
        key.currentState!.selection,
        const KEditorSelection(anchor: 10, head: 5),
      );
      expect(changes, isEmpty);
      adapter.remote('Ignore the detached adapter');
      await tester.pump();
      await tester.tap(find.byTooltip('Bold'));
      await tester.pump();
      expect(changes.single.value, 'Zulu **alpha**');
      expect(reconnect.localTransactions.single.value, 'Zulu **alpha**');
      expect(adapter.localTransactions, isEmpty);

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpWidget(const SizedBox.shrink());
      adapter.dispose();
      reconnect.dispose();
    },
  );

  testWidgets(
    'Markdown link dialog validates, cancels and inserts selected text',
    (tester) async {
      tester.view.physicalSize = const Size(900, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final changes = <KEditorTransaction>[];
      const frame = ValueKey('phone viewport');
      const frameSize = Size(390, 620);
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: Center(
              child: SizedBox.fromSize(
                key: frame,
                size: frameSize,
                child: Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(size: frameSize),
                    child: Navigator(
                      pages: [
                        MaterialPage<void>(
                          child: KMarkdownEditor(
                            markdown: 'A [label]',
                            showFloatingToolbar: false,
                            labels: const KEditorLabels(
                              linkDialogTitle: 'Link hinzufügen',
                              linkUrl: 'Zieladresse',
                              linkSubmit: 'Einfügen',
                              linkCancel: 'Abbrechen',
                              linkInvalidUrl: 'Adresse prüfen',
                            ),
                            onChanged: (_, transaction) =>
                                changes.add(transaction),
                          ),
                        ),
                      ],
                      onDidRemovePage: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final source = tester.state<KCodeEditorState>(find.byType(KCodeEditor));
      source.replaceRange(
        0,
        0,
        '',
        selection: const KEditorSelection(anchor: 2, head: 9),
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Link'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(frame),
          matching: find.byType(KBottomSheet),
        ),
        findsOneWidget,
      );
      expect(find.text('Zieladresse'), findsOneWidget);
      for (final invalid in ['javascript:alert(1)', 'mailto:', r'\host\path']) {
        await tester.enterText(find.byType(KInput), invalid);
        await tester.tap(find.widgetWithText(KButton, 'Einfügen'));
        await tester.pump();
        expect(find.text('Adresse prüfen'), findsOneWidget);
      }
      await tester.tap(find.widgetWithText(KButton, 'Abbrechen'));
      await tester.pumpAndSettle();
      expect(changes, isEmpty);
      expect(source.value, 'A [label]');
      expect(source.selection, const KEditorSelection(anchor: 2, head: 9));

      await tester.tap(find.byTooltip('Link'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(KInput), 'https://example.org/a(b)');
      await tester.tap(find.widgetWithText(KButton, 'Einfügen'));
      await tester.pumpAndSettle();
      expect(
        changes.single.value,
        r'A [\[label\]](https://example.org/a\(b\))',
      );

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'host link hook cannot apply a stale request after an external update',
    (tester) async {
      final request = Completer<String?>();
      final changes = <String>[];
      var markdown = 'Initial';
      KEditorSelection? requested;
      late StateSetter update;
      await tester.pumpWidget(
        _Shell(
          child: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return KMarkdownEditor(
                markdown: markdown,
                onChanged: (value, _) => changes.add(value),
                onLinkRequested: (selection) {
                  requested = selection;
                  return request.future;
                },
              );
            },
          ),
        ),
      );
      await tester.tap(find.byTooltip('Link'));
      await tester.pump();
      expect(find.byType(KAdaptiveDialog), findsNothing);
      expect(requested, const KEditorSelection(anchor: 0, head: 0));
      update(() => markdown = 'Replacement');
      await tester.pump();
      request.complete('https://example.org');
      await tester.pump();
      expect(changes, isEmpty);
      expect(
        tester.state<KCodeEditorState>(find.byType(KCodeEditor)).value,
        'Replacement',
      );
    },
  );

  testWidgets(
    'code editor shows dictation dots at the supplied insertion offset',
    (tester) async {
      await tester.pumpWidget(
        const _Shell(
          child: KCodeEditor(
            value: 'alpha beta',
            dictationState: KDictationState.recording,
            dictationOffset: 6,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(KDictationAnchor), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('markdown preview is derived and remains read only', (
    tester,
  ) async {
    var mode = KEditorMode.source;
    await tester.pumpWidget(
      _Shell(
        child: StatefulBuilder(
          builder: (context, setState) => KMarkdownEditor(
            markdown: '# Release',
            mode: mode,
            onModeChanged: (next) => setState(() => mode = next),
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Preview'));
    await tester.pumpAndSettle();

    expect(mode, KEditorMode.read);
    expect(find.text('Release'), findsOneWidget);
    expect(find.bySemanticsLabel('Markdown'), findsOneWidget);
  });

  testWidgets('preview round-trip retains source selection on touch', (
    tester,
  ) async {
    final key = GlobalKey<KMarkdownEditorState>();
    await tester.pumpWidget(
      _Shell(
        child: KMarkdownEditor(key: key, markdown: 'Release notes'),
      ),
    );
    const selected = KEditorSelection(anchor: 7, head: 0);
    final source = key.currentState!.sourceEditor!;
    source.focus();
    source.setSelection(selected);
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Preview'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Markdown'));
    await tester.pumpAndSettle();

    expect(key.currentState!.sourceEditor, same(source));
    expect(key.currentState!.selection, selected);
  });

  testWidgets('search action toggles the design-system search panel', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _Shell(child: KCodeEditor(value: 'alpha beta alpha')),
    );

    await tester.tap(find.bySemanticsLabel('Search'));
    await tester.pump();
    expect(find.byType(KEditorSearchPanel), findsOneWidget);
    expect(find.bySemanticsLabel('Find'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Search'));
    await tester.pump();
    expect(find.byType(KEditorSearchPanel), findsNothing);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('markdown preview follows remote collaboration snapshots', (
    tester,
  ) async {
    final adapter = _TestAdapter('# Initial');
    await tester.pumpWidget(
      _Shell(
        child: KMarkdownEditor(
          markdown: '',
          defaultMode: KEditorMode.read,
          collaborationAdapter: adapter,
        ),
      ),
    );

    expect(find.text('Initial'), findsOneWidget);
    adapter.remote('# Remote update');
    await tester.pump();
    expect(find.text('Remote update'), findsOneWidget);
  });

  testWidgets(
    'preview renders tables and delegates relative images, retaining source state',
    (tester) async {
      final images = <String>[];
      await tester.pumpWidget(
        _Shell(
          child: KMarkdownEditor(
            markdown:
                '| Name | Value |\n| --- | --- |\n| first | second |\n\n![Local](./picture.png)',
            defaultMode: KEditorMode.read,
            imageBuilder: (uri, alt, title) {
              images.add(uri.toString());
              return Text('Image: $alt');
            },
          ),
        ),
      );
      expect(find.text('first'), findsOneWidget);
      expect(find.text('Image: Local'), findsOneWidget);
      expect(
        images,
        contains('picture.png'),
      ); // Uri normalizes the redundant ./ prefix.
      final before = tester.state(
        find.byType(KCodeEditor, skipOffstage: false),
      );
      await tester.tap(find.bySemanticsLabel('Markdown'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Preview'));
      await tester.pumpAndSettle();
      expect(
        tester.state(find.byType(KCodeEditor, skipOffstage: false)),
        same(before),
      );
    },
  );

  testWidgets('markdown formatting emits a controlled transaction', (
    tester,
  ) async {
    String? changed;
    await tester.pumpWidget(
      _Shell(
        child: KMarkdownEditor(
          markdown: 'Release',
          onChanged: (value, _) => changed = value,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Bold'));
    await tester.pump();
    expect(changed, '****Release');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('markdown format bar exposes working undo and redo actions', (
    tester,
  ) async {
    final changes = <String>[];
    await tester.pumpWidget(
      _Shell(
        child: KMarkdownEditor(
          markdown: 'Release',
          onChanged: (value, _) => changes.add(value),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Bold'));
    await tester.pump();
    await tester.tap(find.byTooltip('Undo'));
    await tester.pump();
    await tester.tap(find.byTooltip('Redo'));
    await tester.pump();

    expect(
      changes,
      containsAllInOrder(['****Release', 'Release', '****Release']),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child, this.width = 420});
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: kDesignTheme(),
    home: Scaffold(
      body: SizedBox(width: width, height: 600, child: child),
    ),
  );
}

class _TestAdapter implements KEditorCollaborationAdapter {
  _TestAdapter(
    String value, {
    KEditorSelection selection = const KEditorSelection(anchor: 0, head: 0),
  }) : _snapshot = ValueNotifier(
         KEditorCollaborationSnapshot(value: value, selection: selection),
       );

  final ValueNotifier<KEditorCollaborationSnapshot> _snapshot;
  final List<KEditorTransaction> localTransactions = [];

  @override
  ValueListenable<KEditorCollaborationSnapshot> get snapshot => _snapshot;

  @override
  void applyLocalTransaction(KEditorTransaction transaction) {
    localTransactions.add(transaction);
    _snapshot.value = KEditorCollaborationSnapshot(
      value: transaction.value,
      selection: transaction.selection,
    );
  }

  void dispose() => _snapshot.dispose();

  void remote(
    String value, {
    KEditorSelection selection = const KEditorSelection(anchor: 0, head: 0),
  }) {
    _snapshot.value = KEditorCollaborationSnapshot(
      value: value,
      selection: selection,
    );
  }
}
