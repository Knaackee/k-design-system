import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    bool disableAnimations = true,
  }) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: child!,
        ),
        home: Scaffold(body: child),
      ),
    );
    await tester.pump();
  }

  KAgentToolPart tool({
    String id = 'tool',
    String title = 'Read file',
    KAgentToolState state = KAgentToolState.succeeded,
    String? error,
  }) => KAgentToolPart(
    id: id,
    toolName: 'read_file',
    title: title,
    state: state,
    arguments: const {'path': 'README.md'},
    error: error,
  );

  testWidgets('tool call is compact, collapsed, and keeps errors visible', (
    tester,
  ) async {
    await mount(
      tester,
      KAgentToolCall(
        part: tool(state: KAgentToolState.failed, error: 'Permission denied'),
      ),
    );

    final disclosure = tester.widget<KDisclosure>(find.byType(KDisclosure));
    expect(disclosure.presentation, KDisclosurePresentation.compact);
    expect(find.text('Arguments'), findsNothing);
    expect(find.text('Permission denied'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('running title shines only when motion is allowed', (
    tester,
  ) async {
    await mount(
      tester,
      KAgentToolCall(part: tool(state: KAgentToolState.running)),
      disableAnimations: false,
    );
    expect(find.byType(ShaderMask), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await mount(
      tester,
      KAgentToolCall(part: tool(state: KAgentToolState.running)),
    );
    expect(find.byType(ShaderMask), findsNothing);

    await mount(tester, KAgentToolCall(part: tool()));
    expect(find.byType(ShaderMask), findsNothing);
  });

  testWidgets('tool group summarizes parts and starts collapsed', (
    tester,
  ) async {
    await mount(
      tester,
      KAgentToolGroup(
        parts: [
          tool(id: 'one'),
          tool(id: 'two'),
        ],
      ),
    );

    expect(find.text('Read file · 2×'), findsOneWidget);
    expect(find.text('Arguments'), findsNothing);
    expect(
      tester.widget<KDisclosure>(find.byType(KDisclosure).first).presentation,
      KDisclosurePresentation.compact,
    );
  });

  testWidgets('approval note uses the default collapsed disclosure', (
    tester,
  ) async {
    await mount(
      tester,
      const KAgentApproval(
        part: KAgentApprovalPart(
          id: 'approval',
          title: 'Publish?',
          state: KAgentResolutionState.pending,
          options: [KAgentApprovalOption(id: 'yes', label: 'Approve')],
        ),
      ),
    );

    expect(find.text('Add a note (optional)'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Add a note (optional)'));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('single-choice rows expose radio semantics for the whole row', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await mount(
      tester,
      const KAgentQuestion(
        part: KAgentQuestionPart(
          id: 'city',
          title: 'Choose a city',
          kind: KAgentQuestionKind.singleChoice,
          state: KAgentResolutionState.pending,
          options: [
            KAgentQuestionOption(id: 'zurich', label: 'Zürich'),
            KAgentQuestionOption(id: 'berlin', label: 'Berlin'),
          ],
        ),
      ),
    );

    var node = tester.getSemantics(find.bySemanticsLabel('Zürich'));
    expect(node.label, 'Zürich');
    expect(
      node.getSemanticsData().flagsCollection.isChecked,
      CheckedState.isFalse,
    );
    expect(
      node.getSemanticsData().flagsCollection.isInMutuallyExclusiveGroup,
      isTrue,
    );

    await tester.tap(find.text('Zürich'));
    await tester.pump();
    node = tester.getSemantics(find.bySemanticsLabel('Zürich'));
    expect(
      node.getSemanticsData().flagsCollection.isChecked,
      CheckedState.isTrue,
    );

    final selectedRow = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text('Zürich'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    final decoration = selectedRow.decoration! as BoxDecoration;
    expect(decoration.color, KDesignTokens.orbitLight.colorActionGhostHover);
    expect(
      decoration.border,
      Border.all(
        color: KDesignTokens.orbitLight.colorBorderFocus,
        width: KDesignTokens.orbitLight.borderWidthDefault,
      ),
    );
    semantics.dispose();
  });

  testWidgets('multiple-choice rows expose checkbox semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    await mount(
      tester,
      const KAgentQuestion(
        part: KAgentQuestionPart(
          id: 'formats',
          title: 'Choose formats',
          kind: KAgentQuestionKind.multipleChoice,
          state: KAgentResolutionState.pending,
          options: [KAgentQuestionOption(id: 'pdf', label: 'PDF')],
        ),
      ),
    );

    final node = tester.getSemantics(find.bySemanticsLabel('PDF'));
    expect(node.label, 'PDF');
    expect(
      node.getSemanticsData().flagsCollection.isChecked,
      CheckedState.isFalse,
    );
    expect(
      node.getSemanticsData().flagsCollection.isInMutuallyExclusiveGroup,
      isFalse,
    );
    semantics.dispose();
  });
}
