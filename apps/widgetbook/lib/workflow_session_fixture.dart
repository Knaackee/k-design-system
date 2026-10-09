import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

/// Matching Storybook fixture ID: workflow-session-review.
class WorkflowSessionFixture extends StatefulWidget {
  const WorkflowSessionFixture({super.key});

  @override
  State<WorkflowSessionFixture> createState() => _WorkflowSessionFixtureState();
}

class _WorkflowSessionFixtureState extends State<WorkflowSessionFixture> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _open();
    });
  }

  Future<void> _open() async {
    final phone = MediaQuery.sizeOf(context).width < KAdaptiveDialog.breakpoint;
    Widget surface(BuildContext context) => KSurface(
      radius: KSurfaceRadius.overlay,
      elevation: KSurfaceElevation.overlay,
      child: const WorkflowSessionReview(),
    );
    if (phone) {
      await showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SizedBox(
          height: MediaQuery.sizeOf(context).height * .92,
          child: surface(context),
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (context) => Center(
          child: SizedBox(
            width: 900,
            height: MediaQuery.sizeOf(context).height * .92,
            child: surface(context),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Center(
    child: KButton(onPressed: _open, label: 'Session öffnen'),
  );
}

class WorkflowSessionReview extends StatefulWidget {
  const WorkflowSessionReview({super.key});

  @override
  State<WorkflowSessionReview> createState() => _WorkflowSessionReviewState();
}

class _WorkflowSessionReviewState extends State<WorkflowSessionReview> {
  bool _details = false;
  bool _approved = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Material(
      color: t.colorSurfaceCanvas,
      textStyle: TextStyle(
        fontFamily: t.fontFamily,
        fontSize: t.fontBodySmallSize,
        fontWeight: t.fontBodyWeight,
        color: t.colorTextPrimary,
      ),
      child: KWorkflow(
        title: 'Lokaler Pi – Persönlich',
        status: _approved ? KWorkflowStatus.succeeded : KWorkflowStatus.waiting,
        statusLabel: _approved ? 'Abgeschlossen' : 'Prüfung nötig',
        phases: _phases(),
        stepCountLabel: '2 / 2',
        durationLabel: '2 Min.',
        startedAt: DateTime(2026, 10, 9, 17, 43),
        endedAt: DateTime(2026, 10, 9, 17, 45),
        labels: const KWorkflowLabels(
          timeline: 'Ablauf',
          steps: 'Schritte',
          duration: 'Dauer',
          start: 'Start',
          end: 'Ende',
        ),
        toolbarActions: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Session-Details',
              style: TextStyle(fontSize: t.fontCaptionSize),
            ),
            SizedBox(width: t.spaceControlGap),
            KSwitch(
              label: 'Session-Details',
              value: _details,
              onChanged: (value) => setState(() => _details = value),
            ),
          ],
        ),
        eventBuilder: (_, event, _) =>
            event.kind == KWorkflowEventKind.custom ? event.content : null,
      ),
    );
  }

  List<KWorkflowPhase> _phases() => [
    const KWorkflowPhase(
      id: 'prepare',
      title: 'Start & Vorbereitung',
      status: KWorkflowStatus.succeeded,
      durationLabel: '12 Sek.',
      events: [
        KWorkflowEvent(
          id: 'ready',
          kind: KWorkflowEventKind.status,
          title: 'Bereit',
          description:
              'Arbeitsumgebung und zugewiesene Ressourcen wurden geladen.',
          timestamp: '17:43',
        ),
      ],
    ),
    KWorkflowPhase(
      id: 'inspect',
      title: 'Dateien prüfen',
      status: KWorkflowStatus.succeeded,
      durationLabel: '1 Min.',
      defaultOpen: true,
      events: [
        KWorkflowEvent(
          id: 'step',
          kind: KWorkflowEventKind.custom,
          title: 'Beispieldatei lesen',
          content: _SessionDisclosure(
            title: 'Beispieldatei lesen',
            defaultOpen: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Die Datei wurde geprüft. Zwei Abschnitte können verständlicher formuliert werden.',
                ),
                if (_details) ...[
                  _message(
                    'Du',
                    'Prüfe die Release Notes und schlage eine kurze, verständliche Zusammenfassung vor.',
                  ),
                  _message(
                    'Agent',
                    'Ich lese zuerst die vorhandene Datei und prüfe anschließend die Änderungen.',
                  ),
                  const _SessionDisclosure(
                    title: 'read · release-notes.md',
                    child: SelectableText(
                      'Argumente\n{ "path": "docs/release-notes.md" }\n\nErgebnis · Demo\n# Release Notes\nVerbesserte Session-Ansicht und nachvollziehbare Tool-Aufrufe.',
                    ),
                  ),
                  _message(
                    'Agent',
                    'Die relevanten Änderungen sind erfasst. Ich fasse sie zusammen und lasse die Formulierung vor dem Abschluss bestätigen.',
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
    const KWorkflowPhase(
      id: 'question',
      title: 'Rückfrage',
      status: KWorkflowStatus.succeeded,
      durationLabel: '18 Sek.',
      events: [
        KWorkflowEvent(
          id: 'question-event',
          kind: KWorkflowEventKind.question,
          title: 'Rückfrage',
          timestamp: '17:44',
          description:
              'Soll die Zusammenfassung auch technische Details enthalten?',
        ),
        KWorkflowEvent(
          id: 'answer',
          kind: KWorkflowEventKind.answer,
          title: 'Deine Antwort',
          timestamp: '17:44',
          description:
              'Ja, bitte die wichtigsten technischen Änderungen ergänzen.',
        ),
      ],
    ),
    KWorkflowPhase(
      id: 'result',
      title: 'Ergebnis & Freigabe',
      status: _approved ? KWorkflowStatus.succeeded : KWorkflowStatus.waiting,
      durationLabel: '30 Sek.',
      defaultOpen: true,
      events: [
        const KWorkflowEvent(
          id: 'artifact',
          kind: KWorkflowEventKind.artifact,
          title: 'Zusammenfassung.md',
          description: 'Vorschau · Beispieldatei',
          content: _SessionDisclosure(
            title: 'Datei ansehen',
            child: Text(
              'Die Session-Ansicht zeigt Arbeitsschritte, Rückfragen und Ergebnisse. Optionale Session-Details machen Nachrichten und Tool-Aufrufe nachvollziehbar.',
            ),
          ),
        ),
        KWorkflowEvent(
          id: 'approval',
          kind: KWorkflowEventKind.approval,
          title: _approved ? 'Freigegeben' : 'Deine Freigabe',
          description: _approved
              ? 'Das Demo-Ergebnis wurde bestätigt.'
              : 'Die Zusammenfassung ist fertig und wartet auf deine Prüfung.',
          content: Align(
            alignment: AlignmentDirectional.centerStart,
            child: KButton(
              onPressed: _approved
                  ? null
                  : () => setState(() => _approved = true),
              label: _approved ? 'Bestätigt' : 'Ergebnis bestätigen',
            ),
          ),
        ),
      ],
    ),
  ];

  Widget _message(String role, String text) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: t.spaceControlInsetInline / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role,
            style: TextStyle(
              color: t.colorTextMuted,
              fontSize: t.fontCaptionSize,
              fontWeight: t.fontLabelWeight,
            ),
          ),
          SizedBox(height: t.spaceControlGap),
          Text(text),
        ],
      ),
    );
  }
}

class _SessionDisclosure extends StatelessWidget {
  const _SessionDisclosure({
    required this.title,
    required this.child,
    this.defaultOpen = false,
  });
  final String title;
  final Widget child;
  final bool defaultOpen;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return KDisclosure(
      title: title,
      titleWidget: Text(
        title,
        style: TextStyle(
          fontSize: t.fontBodySmallSize,
          fontWeight: t.fontLabelWeight,
        ),
      ),
      defaultOpen: defaultOpen,
      presentation: KDisclosurePresentation.compact,
      showContentBorder: false,
      child: child,
    );
  }
}
