import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

Widget frame(Widget child) => MaterialApp(
  theme: kDesignTheme(),
  home: Scaffold(body: child),
);

const phases = [
  KWorkflowPhase(
    id: 'inspect',
    title: 'Inspect',
    status: KWorkflowStatus.succeeded,
    durationLabel: '12345 Minuten vergangen',
    defaultOpen: true,
    events: [
      KWorkflowEvent(
        id: 'step',
        kind: KWorkflowEventKind.custom,
        title: 'Step',
        content: KDisclosure(title: 'Tool', child: Text('Tool result')),
      ),
    ],
  ),
];

void main() {
  testWidgets(
    'toolbar action does not toggle phase and nested state survives collapse',
    (tester) async {
      var details = 0;
      await tester.pumpWidget(
        frame(
          KWorkflow(
            title: 'Session',
            status: KWorkflowStatus.waiting,
            phases: phases,
            toolbarActions: TextButton(
              onPressed: () => details++,
              child: const Text('Details'),
            ),
            eventBuilder: (_, event, _) => event.content,
          ),
        ),
      );
      await tester.tap(find.text('Tool'));
      await tester.pumpAndSettle();
      expect(find.text('Tool result'), findsOneWidget);
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();
      expect(details, 1);
      expect(find.text('Tool result'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('workflow-phase-inspect')));
      await tester.pumpAndSettle();
      expect(find.text('Tool result'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('workflow-phase-inspect')));
      await tester.pumpAndSettle();
      expect(find.text('Tool result'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'controlled phases emit changes and null builder uses default event',
    (tester) async {
      Set<String>? changed;
      await tester.pumpWidget(
        frame(
          KWorkflow(
            title: 'Session',
            status: KWorkflowStatus.waiting,
            phases: phases,
            expandedPhaseIds: const {},
            onExpandedPhaseIdsChanged: (ids) => changed = ids,
            eventBuilder: (_, _, _) => null,
          ),
        ),
      );
      await tester.tap(find.text('Inspect'));
      await tester.pumpAndSettle();
      expect(changed, {'inspect'});
      expect(find.text('STEP'), findsNothing);
      await tester.pumpWidget(
        frame(
          KWorkflow(
            title: 'Session',
            status: KWorkflowStatus.waiting,
            phases: phases,
            expandedPhaseIds: const {'inspect'},
            eventBuilder: (_, _, _) => null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('STEP'), findsOneWidget);
    },
  );

  testWidgets(
    'streamed phases open once while prior user collapse is retained',
    (tester) async {
      Widget workflow(List<KWorkflowPhase> items) => frame(
        KWorkflow(
          title: 'Session',
          status: KWorkflowStatus.waiting,
          phases: items,
          eventBuilder: (_, event, _) => event.content,
        ),
      );
      await tester.pumpWidget(workflow(phases));
      await tester.tap(find.text('Inspect'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        workflow([
          ...phases,
          const KWorkflowPhase(
            id: 'next',
            title: 'Next',
            status: KWorkflowStatus.running,
            defaultOpen: true,
            durationLabel: '1s',
            events: [
              KWorkflowEvent(
                id: 'new',
                kind: KWorkflowEventKind.custom,
                title: 'New',
                content: Text('Live result'),
              ),
            ],
          ),
        ]),
      );
      await tester.pump();
      expect(find.text('Tool'), findsNothing);
      expect(find.text('Live result'), findsOneWidget);
      expect(find.bySemanticsLabel('Next, Running'), findsOneWidget);
    },
  );

  testWidgets(
    'detailed summary reflows metrics and actions at 200 percent text',
    (tester) async {
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        frame(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(900, 800),
              textScaler: TextScaler.linear(2),
            ),
            child: KWorkflow(
              title: 'Lokaler Pi – Persönlich',
              status: KWorkflowStatus.waiting,
              statusLabel: 'Prüfung nötig',
              phases: const [],
              durationLabel: '2 Minuten',
              summaryActions: TextButton(
                onPressed: () {},
                child: const Text('Stopp anfordern'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact parent scrolling supports narrow viewport and large text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        frame(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 740),
              textScaler: TextScaler.linear(2),
            ),
            child: SingleChildScrollView(
              child: KWorkflow(
                title: 'Lokaler Pi – Persönlich',
                summaryActions: TextButton(
                  onPressed: () {},
                  child: const Text('Stopp anfordern'),
                ),
                status: KWorkflowStatus.waiting,
                phases: phases,
                scrollable: false,
                startedAt: DateTime(2026, 10, 9, 17, 43),
                toolbarActions: const Text('Details'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lokaler Pi – Persönlich'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
