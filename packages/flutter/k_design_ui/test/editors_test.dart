import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
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
    expect(find.byType(KSearchField), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Search'));
    await tester.pump();
    expect(find.byType(KSearchField), findsNothing);
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
  const _Shell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: kDesignTheme(),
    home: Scaffold(body: SizedBox(width: 420, height: 600, child: child)),
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
  }

  void remote(String value) {
    _snapshot.value = KEditorCollaborationSnapshot(
      value: value,
      selection: const KEditorSelection(anchor: 0, head: 0),
    );
  }
}
