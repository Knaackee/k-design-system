import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
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

  testWidgets('code editor emits local transactions and accepts remote state', (
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
    expect(changes, hasLength(1));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpWidget(const SizedBox.shrink());
  });

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
  _TestAdapter(String value)
    : _snapshot = ValueNotifier(KEditorCollaborationSnapshot(value: value));

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

  void remote(String value) {
    _snapshot.value = KEditorCollaborationSnapshot(
      value: value,
      selection: const KEditorSelection(anchor: 0, head: 0),
    );
  }
}
