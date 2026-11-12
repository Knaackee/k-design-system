import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:re_editor/re_editor.dart';

void main() {
  for (final width in [393.0, 1166.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets(
        'inline prose has body-font fallback and fits at $width/$scale even when preferred font is unavailable',
        (tester) async {
          tester.view.physicalSize = Size(width, 852);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: kDesignTheme().copyWith(
                extensions: [
                  KDesignTokens.orbitLight.copyWith(
                    fontFamily: 'UnavailableBrandFont',
                  ),
                ],
              ),
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 852),
                  textScaler: TextScaler.linear(scale),
                ),
                child: const Scaffold(
                  body: SingleChildScrollView(child: _DraftHarness()),
                ),
              ),
            ),
          );
          final harness = tester.state<_DraftHarnessState>(
            find.byType(_DraftHarness),
          );
          harness.replaceBody(
            'Liebe Sabrina,\n\ndu bist mein Lieblingsmensch - sogar dann, wenn mein Computer wieder laenger ueber eine E-Mail nachdenkt als ich ueber das Abendessen. Danke, dass du so wunderbar bist!\n\nLiebe Gruesse\nDennis',
          );
          harness.lock();
          await tester.pump();
          final source = tester.widget<CodeEditor>(find.byType(CodeEditor));
          expect(source.style!.fontFamily, 'UnavailableBrandFont');
          expect(source.style!.fontFamilyFallback, ['sans-serif']);
          expect(source.wordWrap, isTrue);
          expect(
            source.scrollController!.verticalScroller.position.maxScrollExtent,
            0,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'Subject dictation is opt-in and host controller survives locking',
    (tester) async {
      final subject = TextEditingController(text: 'Project update');
      addTearDown(subject.dispose);
      KAgentEmailDraftValue value = const KAgentEmailDraftValue(
        to: 'mara@example.com',
        subject: 'Project update',
        markdown: 'Hello',
      );
      var capture = KDictationState.ready;
      var locked = false;
      late StateSetter update;
      await tester.pumpWidget(
        _shell(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return KAgentEmailDraft(
                draftId: 'dictation',
                title: 'Mail',
                from: 'sender@example.com',
                value: value,
                subjectController: subject,
                subjectDictationState: capture,
                subjectDictationOffset: 3,
                onSubjectDictationPressed: () {},
                disabled: locked,
                onChanged: (next) => setState(() => value = next),
                onSend: () {},
                onDiscard: () {},
              );
            },
          ),
        ),
      );
      expect(find.byType(KDictationAction), findsOneWidget);
      final input = find.descendant(
        of: find.byWidgetPredicate((w) => w is KInput && w.label == 'Subject'),
        matching: find.byType(TextField),
      );
      await tester.enterText(input, 'Manual project update');
      await tester.pump();
      expect(value.subject, 'Manual project update');
      for (final state in [
        KDictationState.recording,
        KDictationState.processing,
      ]) {
        update(() => capture = state);
        await tester.pump();
        expect(
          tester
              .widget<KButton>(
                find.byWidgetPredicate(
                  (w) => w is KButton && w.label == 'Send',
                ),
              )
              .onPressed,
          isNull,
        );
        expect(tester.widget<TextField>(input).enabled, isTrue);
        expect(
          tester
              .widget<KInput>(
                find.byWidgetPredicate(
                  (w) => w is KInput && w.label == 'Subject',
                ),
              )
              .dictationOffset,
          3,
        );
      }
      update(() {
        capture = KDictationState.ready;
        locked = true;
      });
      await tester.pump();
      expect(find.byType(KDictationAction), findsNothing);
      expect(subject.text, 'Manual project update');
      await tester.pumpWidget(const SizedBox.shrink());
      expect(subject.text, 'Manual project update');
    },
  );

  for (final width in [360.0, 393.0]) {
    for (final scale in [1.0, 1.3, 2.0, 3.0]) {
      testWidgets(
        'email fits $width at text $scale with errors and attachments',
        (tester) async {
          tester.view.physicalSize = Size(width, 852);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            _shell(const _DraftHarness(errors: true), scale),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          final heading = tester.element(
            find.descendant(
              of: find.byWidgetPredicate(
                (w) => w is KInput && w.label == 'Subject',
              ),
              matching: find.byType(TextField),
            ),
          );
          expect(
            MediaQuery.textScalerOf(heading).scale(10),
            lessThanOrEqualTo(20),
          );
          await tester.scrollUntilVisible(
            find.text('Discard'),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('Review recipient'), findsOneWidget);
        },
      );
    }
  }
  testWidgets(
    'controlled fields and message preserve edits through host lock',
    (tester) async {
      await tester.pumpWidget(_shell(const _DraftHarness()));
      final input = find.descendant(
        of: find.byWidgetPredicate((w) => w is KInput && w.label == 'To'),
        matching: find.byType(TextField),
      );
      await tester.enterText(input, 'new@example.com');
      await tester.pump();
      final editor = tester.state<KCodeEditorState>(find.byType(KCodeEditor));
      editor.replaceRange(0, 5, 'Changed');
      await tester.pump();
      final harness = tester.state<_DraftHarnessState>(
        find.byType(_DraftHarness),
      );
      expect(harness.value.to, 'new@example.com');
      expect(harness.value.markdown, 'Changed Mara');
      harness.lock();
      await tester.pump();
      expect(
        tester.widget<KMarkdownEditor>(find.byType(KMarkdownEditor)).readOnly,
        isTrue,
      );
      expect(
        tester.widget<KCodeEditor>(find.byType(KCodeEditor)).value,
        'Changed Mara',
      );
      expect(
        tester
            .widget<KButton>(
              find.byWidgetPredicate((w) => w is KButton && w.label == 'Send'),
            )
            .onPressed,
        isNull,
      );
      expect(harness.sends, 0);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'inline editor expands to default workspace and returns with its value',
    (tester) async {
      await tester.pumpWidget(_shell(const _DraftHarness()));
      expect(
        tester.widget<KCodeEditor>(find.byType(KCodeEditor)).prose,
        isTrue,
      );
      await tester.tap(find.byTooltip('Expand editor'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<KCodeEditor>(find.byType(KCodeEditor)).prose,
        isFalse,
      );
      expect(
        tester.widget<KCodeEditor>(find.byType(KCodeEditor)).fontFamily,
        'packages/k_design_ui/KDesignMono',
      );
      await tester.tap(find.byTooltip('Return to editor').first);
      await tester.pumpAndSettle();
      expect(
        tester.widget<KCodeEditor>(find.byType(KCodeEditor)).prose,
        isTrue,
      );
      expect(
        tester.widget<KCodeEditor>(find.byType(KCodeEditor)).value,
        'Hello Mara',
      );
    },
  );
  testWidgets('new inline options preserve generic defaults', (tester) async {
    expect(const KInput().appearance, KInputAppearance.outlined);
    expect(const KMarkdownEditor(markdown: '').inline, isFalse);
    expect(const KCodeEditor(value: '').prose, isFalse);
    await tester.pumpWidget(_shell(const KInput()));
    final input = tester.widget<TextField>(find.byType(TextField));
    expect(input.decoration!.enabledBorder, isA<OutlineInputBorder>());
  });
  testWidgets('compact attachments retain block and inline padding roles', (
    tester,
  ) async {
    await tester.pumpWidget(_shell(const _DraftHarness()));
    final attachment = find.byType(KAttachment);
    final container = tester.widget<Container>(
      find.descendant(of: attachment, matching: find.byType(Container)).first,
    );
    final tokens = Theme.of(
      tester.element(attachment),
    ).extension<KDesignTokens>()!;
    final padding = container.padding!.resolve(TextDirection.ltr);
    expect(padding.left, tokens.spaceControlGap);
    expect(padding.top, tokens.componentAttachmentCompactPaddingBlock);
  });
  testWidgets('dictation-only bottom bar is included in body fit', (
    tester,
  ) async {
    await tester.pumpWidget(
      _shell(const _DraftHarness(dictation: true, expand: false)),
    );
    final harness = tester.state<_DraftHarnessState>(
      find.byType(_DraftHarness),
    );
    harness.replaceBody(
      'Hallo Mara,\n\nanbei die Unterlagen für unseren Termin am Donnerstag.\n\nViele Grüße\nDennis',
    );
    await tester.pump();
    expect(find.byType(KEditorFormatBar), findsOneWidget);
    final source = tester.widget<CodeEditor>(find.byType(CodeEditor));
    expect(
      source.scrollController!.verticalScroller.position.maxScrollExtent,
      0,
    );
  });
  testWidgets(
    'metadata label and editable text share a measured alphabetic baseline',
    (tester) async {
      for (final scale in [1.0, 1.3, 2.0, 3.0]) {
        await tester.pumpWidget(_shell(const _DraftHarness(), scale));
        for (final name in ['From', 'To', 'Cc']) {
          final label = tester.renderObject<RenderBox>(
            find.byWidgetPredicate((w) => w is KText && w.data == name),
          );
          final editable = tester.renderObject<RenderBox>(
            find.descendant(
              of: find.byWidgetPredicate((w) => w is KInput && w.label == name),
              matching: find.byType(EditableText),
            ),
          );
          final labelBaseline =
              label.localToGlobal(Offset.zero).dy +
              label.getDryBaseline(label.constraints, TextBaseline.alphabetic)!;
          final inputBaseline =
              editable.localToGlobal(Offset.zero).dy +
              editable.getDryBaseline(
                editable.constraints,
                TextBaseline.alphabetic,
              )!;
          expect(
            labelBaseline,
            closeTo(inputBaseline, .01),
            reason: '$name at $scale',
          );
        }
      }
    },
  );
  testWidgets(
    'short prose fits fully, attachment stays compact and add action is labeled',
    (tester) async {
      await tester.pumpWidget(_shell(const _DraftHarness()));
      final harness = tester.state<_DraftHarnessState>(
        find.byType(_DraftHarness),
      );
      harness.replaceBody(
        'Hallo Mara,\n\nanbei die besprochene Übersicht für unseren Termin am Donnerstag. Passt es für dich weiterhin um 10 Uhr?\n\nViele Grüße\nDennis',
      );
      await tester.pump();
      final source = tester.widget<CodeEditor>(find.byType(CodeEditor));
      expect(
        source.scrollController!.verticalScroller.position.maxScrollExtent,
        0,
      );
      expect(
        tester.getSize(find.byType(KAttachment)).width,
        lessThan(tester.getSize(find.byType(KCard)).width),
      );
      expect(find.text('Add attachment'), findsOneWidget);
      final title = tester.widget<KText>(
        find.byWidgetPredicate(
          (w) => w is KText && w.data == 'Projektübersicht.pdf',
        ),
      );
      expect(title.style!.fontWeight, FontWeight.bold);
    },
  );
  testWidgets(
    'inline fields preserve control tracking and body weight, prose scales explicitly',
    (tester) async {
      await tester.pumpWidget(_shell(const _DraftHarness(), 1.3));
      final input = tester.widget<TextField>(
        find.descendant(
          of: find.byWidgetPredicate((w) => w is KInput && w.label == 'To'),
          matching: find.byType(TextField),
        ),
      );
      final tokens = Theme.of(
        tester.element(find.byType(KCard)),
      ).extension<KDesignTokens>()!;
      expect(
        input.style!.letterSpacing,
        closeTo(-.01 * tokens.fontControlSize * 1.3, .001),
      );
      expect(input.style!.fontWeight, tokens.fontBodyWeight);
      expect(
        input.style!.fontVariations!.first.value,
        tokens.fontBodyWeight.value,
      );
      expect(
        tester.widget<CodeEditor>(find.byType(CodeEditor)).style!.fontSize,
        tokens.fontControlSize * 1.3,
      );
    },
  );
  testWidgets(
    'host editor key supports cursor insertion and respects a resolved lock',
    (tester) async {
      await tester.pumpWidget(_shell(const _DraftHarness()));
      final harness = tester.state<_DraftHarnessState>(
        find.byType(_DraftHarness),
      );
      expect(harness.editorKey.currentState, isNotNull);
      expect(
        harness.editorKey.currentState!.insertDictation(
          'Inserted ',
          selection: const KEditorSelection(anchor: 0, head: 0),
        ),
        isTrue,
      );
      await tester.pump();
      expect(harness.value.markdown, 'Inserted Hello Mara');
      harness.lock();
      await tester.pump();
      expect(
        harness.editorKey.currentState!.insertDictation('Forbidden'),
        isFalse,
      );
      expect(harness.value.markdown, 'Inserted Hello Mara');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'remote message snapshots do not emit draft edits and inline padding clears maximize',
    (tester) async {
      await tester.pumpWidget(_shell(const _DraftHarness()));
      final harness = tester.state<_DraftHarnessState>(
        find.byType(_DraftHarness),
      );
      final editor = tester.widget<KMarkdownEditor>(
        find.byType(KMarkdownEditor),
      );
      editor.onChanged!(
        'Remote snapshot',
        const KEditorTransaction(
          value: 'Remote snapshot',
          selection: KEditorSelection(anchor: 0, head: 0),
          origin: KEditorTransactionOrigin.remote,
        ),
      );
      expect(harness.value.markdown, 'Hello Mara');
      harness.replaceBody('Host replacement');
      await tester.pump();
      expect(harness.value.markdown, 'Host replacement');
      expect(harness.changes, 0);
      final source = tester.widget<CodeEditor>(find.byType(CodeEditor));
      final tokens = Theme.of(
        tester.element(find.byType(KCodeEditor)),
      ).extension<KDesignTokens>()!;
      expect(
        source.padding!.resolve(TextDirection.ltr).bottom,
        greaterThanOrEqualTo(tokens.sizeHitTarget),
      );
    },
  );
}

Widget _shell(Widget child, [double scale = 1]) => MaterialApp(
  theme: kDesignTheme(),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  ),
);

class _DraftHarness extends StatefulWidget {
  const _DraftHarness({
    this.errors = false,
    this.dictation = false,
    this.expand = true,
  });
  final bool errors;
  final bool dictation, expand;
  @override
  State<_DraftHarness> createState() => _DraftHarnessState();
}

class _DraftHarnessState extends State<_DraftHarness> {
  final editorKey = GlobalKey<KMarkdownEditorState>();
  KAgentEmailDraftValue value = const KAgentEmailDraftValue(
    to: 'mara@example.com',
    subject: 'Project update',
    markdown: 'Hello Mara',
  );
  KAgentEmailDraftStatus status = KAgentEmailDraftStatus.pending;
  int sends = 0;
  int changes = 0;
  void replaceBody(String markdown) =>
      setState(() => value = value.copyWith(markdown: markdown));
  void lock() => setState(() => status = KAgentEmailDraftStatus.sent);
  @override
  Widget build(BuildContext context) => KAgentEmailDraft(
    draftId: 'one',
    editorKey: editorKey,
    showExpandButton: widget.expand,
    dictationState: widget.dictation ? KDictationState.ready : null,
    title: 'Mail',
    from: 'dennis@example.com',
    value: value,
    onChanged: (next) => setState(() {
      changes++;
      value = next;
    }),
    onSend: () => sends++,
    onDiscard: () {},
    status: status,
    errors: widget.errors
        ? const {KAgentEmailDraftField.to: 'Review recipient'}
        : const {},
    attachments: const [
      KAgentEmailDraftAttachment(
        id: 'one',
        name: 'Projektübersicht.pdf',
        description: 'PDF · 248 KB',
      ),
    ],
    onAddAttachment: () {},
    onRemoveAttachment: (_) {},
  );
}
