import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:re_editor/re_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

Widget shell(Widget child) => MaterialApp(
  theme: ThemeData(extensions: [KDesignTokens.orbitLight]),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('actual typed text reaches preview after controlled rebuild', (
    tester,
  ) async {
    var value = '# Initial';
    var changes = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [KDesignTokens.orbitLight]),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => KMarkdownEditor(
              markdown: value,
              defaultMode: KEditorMode.read,
              onChanged: (next, _) => setState(() {
                value = next;
                changes++;
              }),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Markdown'));
    await tester.pumpAndSettle();
    await tester.tapAt(
      tester.getTopLeft(find.byType(CodeEditor)) + const Offset(70, 80),
    );
    await tester.pump();
    expect(tester.testTextInput.hasAnyClients, isTrue);
    final client = tester.testTextInput.log
        .lastWhere((call) => call.method == 'TextInput.setClient')
        .arguments[0];
    final oldText = tester.testTextInput.editingState!['text'] as String;
    const changed = '# Changed through typing';
    // re_editor uses DeltaTextInputClient. tester.enterText sends the legacy
    // non-delta message, which this editor intentionally ignores.
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.textInput.name,
      SystemChannels.textInput.codec.encodeMethodCall(
        MethodCall('TextInputClient.updateEditingStateWithDeltas', [
          client,
          {
            'deltas': [
              {
                'oldText': oldText,
                'deltaText': changed,
                'deltaStart': 0,
                'deltaEnd': oldText.length,
                'selectionBase': changed.length,
                'selectionExtent': changed.length,
                'selectionAffinity': 'TextAffinity.downstream',
                'selectionIsDirectional': false,
                'composingBase': -1,
                'composingExtent': -1,
              },
            ],
          },
        ]),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();
    expect(changes, greaterThan(0));
    expect(value, contains('Changed through typing'));
    await tester.tap(find.bySemanticsLabel('Preview'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Changed through typing'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('conversation forwards host Markdown options to text parts', (
    tester,
  ) async {
    final options = KMarkdownOptions(copyLabel: 'Host copy', onCopy: (_) {});
    await tester.pumpWidget(
      shell(
        KChatConversation(
          markdownOptions: options,
          messages: const [
            KChatMessageValue(
              id: 'message',
              role: KChatRole.assistant,
              parts: [
                KChatTextPart(id: 'text', text: '```js\nconst n = 1;\n```'),
              ],
            ),
          ],
        ),
      ),
    );
    final renderer = tester.widget<KMarkdownRenderer>(
      find.byType(KMarkdownRenderer),
    );
    expect(renderer.onCopy, options.onCopy);
    expect(find.widgetWithText(KButton, 'Host copy'), findsOneWidget);
  });

  testWidgets('conversation can restrict user Markdown independently', (
    tester,
  ) async {
    await tester.pumpWidget(
      shell(
        const KChatConversation(
          userMarkdownAllowedElements: {'p'},
          messages: [
            KChatMessageValue(
              id: 'user',
              role: KChatRole.user,
              parts: [
                KChatTextPart(
                  id: 'user-text',
                  text: '# User\n\n```\nCode\n```',
                ),
              ],
            ),
            KChatMessageValue(
              id: 'assistant',
              role: KChatRole.assistant,
              parts: [
                KChatTextPart(id: 'assistant-text', text: '# Assistant reply'),
              ],
            ),
          ],
        ),
      ),
    );
    final renderers = tester.widgetList<KMarkdownRenderer>(
      find.byType(KMarkdownRenderer),
    );
    expect(renderers.first.allowedElements, {'p'});
    expect(renderers.last.allowedElements, isNull);
    expect(find.text('User'), findsOneWidget);
    expect(find.text('Assistant reply'), findsOneWidget);
  });

  testWidgets(
    'chat follows input mode and keeps streamed touch content scrollable',
    (tester) async {
      var text = List.filled(100, 'Earlier text.\n\n').join();
      var width = 700.0;
      var input = KInputMode.touch;
      bool? selectable;
      late StateSetter update;
      await tester.pumpWidget(
        shell(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Align(
                child: SizedBox(
                  width: width,
                  child: KAdaptive(
                    configuration: KDesignConfiguration(inputMode: input),
                    child: KChatConversation(
                      metadataMode: KChatMessageMetadataMode.hidden,
                      markdownOptions: KMarkdownOptions(selectable: selectable),
                      messages: [
                        KChatMessageValue(
                          id: 'message',
                          role: KChatRole.assistant,
                          parts: [
                            KChatTextPart(
                              id: 'part',
                              text: text,
                              streaming: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      KMarkdownRenderer renderer() =>
          tester.widget<KMarkdownRenderer>(find.byType(KMarkdownRenderer));
      expect(renderer().selectable, isFalse);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.liveRegion == true &&
              widget.child is KMarkdownRenderer,
        ),
        findsNothing,
      );
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      final start = position.pixels;
      await tester.drag(
        find.byType(KChatConversation),
        const Offset(0, 250),
        kind: PointerDeviceKind.touch,
      );
      await tester.pumpAndSettle();
      final scrolled = position.pixels;
      expect(scrolled, lessThan(start));
      update(() => text += '**Incoming');
      await tester.pumpAndSettle();
      expect(position.pixels, scrolled);
      update(() {
        width = 360;
        input = KInputMode.pointer;
      });
      await tester.pumpAndSettle();
      expect(renderer().selectable, isTrue);
      update(() => selectable = false);
      await tester.pumpAndSettle();
      expect(renderer().selectable, isFalse);
    },
  );

  testWidgets('nested lists preserve indentation and ordered starts', (
    tester,
  ) async {
    await tester.pumpWidget(
      shell(
        const KMarkdownRenderer(
          selectable: false,
          content:
              '- Parent\n  - Child\n    - Grandchild\n\n3. Third\n4. Fourth',
        ),
      ),
    );
    final parent = tester.getTopLeft(find.text('Parent')).dx;
    final child = tester.getTopLeft(find.text('Child')).dx;
    final grandchild = tester.getTopLeft(find.text('Grandchild')).dx;
    expect(child, greaterThan(parent));
    expect(grandchild, greaterThan(child));
    expect(child - parent, grandchild - child);
    expect(find.text('3.'), findsOneWidget);
    expect(find.text('4.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chat delegates shared renderer actions and image ownership', (
    tester,
  ) async {
    String? copied;
    Uri? linked;
    await tester.pumpWidget(
      shell(
        SingleChildScrollView(
          child: KChatMarkdown(
            text:
                '[Open](https://example.com)\n\n![Portrait](private.png)\n\n```js\nconst n = 1;\n```',
            onLinkActivate: (uri) => linked = uri,
            markdownOptions: KMarkdownOptions(
              selectable: false,
              copyLabel: 'Copy source',
              onCopy: (value) => copied = value,
              imageBuilder: (uri, alt, title) => Text('Image: $uri'),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.widget<KMarkdownRenderer>(find.byType(KMarkdownRenderer)).profile,
      KMarkdownProfile.chat,
    );
    await tester.tap(find.text('Open'));
    expect(linked.toString(), 'https://example.com');
    await tester.tap(find.widgetWithText(KButton, 'Copy source'));
    expect(copied, 'const n = 1;');
    expect(find.text('Image: private.png'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'editor preview forwards options and legacy callbacks take priority',
    (tester) async {
      String? copied;
      String? linked;
      var fallbackCalled = false;
      await tester.pumpWidget(
        shell(
          KMarkdownEditor(
            markdown: '[Open](https://example.com)\n\n```js\nconst n = 1;\n```',
            mode: KEditorMode.read,
            onLinkPressed: (url) => linked = url,
            markdownOptions: KMarkdownOptions(
              selectable: false,
              onLinkActivate: (_) => fallbackCalled = true,
              onCopy: (text) => copied = text,
              copyLabel: 'Copy source',
            ),
          ),
        ),
      );
      expect(find.byType(KMarkdownPreview), findsOneWidget);
      await tester.tap(find.text('Open'));
      expect(linked, 'https://example.com');
      expect(fallbackCalled, isFalse);
      await tester.tap(find.widgetWithText(KButton, 'Copy source'));
      expect(copied, 'const n = 1;');
      expect(tester.takeException(), isNull);
    },
  );
}
