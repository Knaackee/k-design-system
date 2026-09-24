import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class WorkflowFixture extends StatefulWidget {
  const WorkflowFixture({
    this.presentation = KWorkflowPresentation.auto,
    this.showTechnicalEventsInCompact = false,
    super.key,
  });

  final KWorkflowPresentation presentation;
  final bool showTechnicalEventsInCompact;

  @override
  State<WorkflowFixture> createState() => _WorkflowFixtureState();
}

class _WorkflowFixtureState extends State<WorkflowFixture> {
  late final DateTime _now = DateTime.now();
  late final DateTime _start = _now.subtract(
    const Duration(minutes: 3, seconds: 18),
  );
  String? _activated;
  KAgentQuestionResponse? _answer;

  DateTime minute(double value) =>
      _start.add(Duration(milliseconds: (value * 60000).round()));

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Stack(
      children: [
        Positioned.fill(
          child: KWorkflow(
            title: 'Knaackee',
            status: KWorkflowStatus.running,
            statusLabel: 'Läuft',
            phases: _phases(),
            startedAt: _start,
            stepCountLabel: '4',
            presentation: widget.presentation,
            labels: const KWorkflowLabels(
              timeline: 'Ablauf',
              steps: 'Schritte',
              duration: 'Dauer',
              start: 'Start',
              end: 'Ende',
              notEnded: 'Noch nicht beendet',
              running: 'Läuft',
              pending: 'Ausstehend',
              paused: 'Pausiert',
              waiting: 'Wartet',
              succeeded: 'Abgeschlossen',
              failed: 'Fehlgeschlagen',
              cancelled: 'Abgebrochen',
            ),
            showTechnicalEventsInCompact: widget.showTechnicalEventsInCompact,
            onEventActivate: (event, _) =>
                setState(() => _activated = event.id),
          ),
        ),
        if (_activated != null)
          PositionedDirectional(
            end: t.spaceLayoutGutter,
            bottom: t.spaceLayoutGutter,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: t.colorSurfaceRaised,
                border: Border.all(color: t.colorBorderDefault),
                borderRadius: BorderRadius.circular(t.radiusControl),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: t.spaceControlInsetInline,
                  vertical: t.spaceControlGap,
                ),
                child: Text('Event aktiviert: $_activated'),
              ),
            ),
          ),
      ],
    );
  }

  List<KWorkflowPhase> _phases() => [
    KWorkflowPhase(
      id: 'prepare',
      title: 'Start & Vorbereitung',
      status: KWorkflowStatus.succeeded,
      startedAt: _start,
      endedAt: minute(.7),
      events: [
        KWorkflowEvent(
          id: 'started',
          kind: KWorkflowEventKind.status,
          title: 'Status: Läuft',
          description: 'Agent work started',
          timestamp: '13:11',
          status: KWorkflowStatus.running,
        ),
        KWorkflowEvent(
          id: 'issue-log',
          kind: KWorkflowEventKind.log,
          title: 'Log',
          description:
              'Pi tool issues_get started.\nPi tool issues_get finished.',
          timestamp: '13:12',
          importance: KWorkflowEventImportance.technical,
        ),
      ],
    ),
    KWorkflowPhase(
      id: 'gate',
      title: 'Rückfrage · Human Gate',
      status: KWorkflowStatus.succeeded,
      startedAt: minute(.7),
      endedAt: minute(1.8),
      events: [
        KWorkflowEvent(
          id: 'location-question',
          kind: KWorkflowEventKind.question,
          title: 'Rückfrage',
          description:
              'Für welchen Ort soll ich das aktuelle Wetter ermitteln?',
          timestamp: '13:12',
          sequence: 4,
          content: KAgentSingleChoice(
            part: KAgentQuestionPart(
              id: 'location-choice',
              title: 'Ort auswählen',
              description: 'Die Workflow-Ausführung wartet auf diese Antwort.',
              kind: KAgentQuestionKind.singleChoice,
              state: _answer == null
                  ? KAgentResolutionState.pending
                  : KAgentResolutionState.answered,
              options: const [
                KAgentQuestionOption(id: 'zurich', label: 'Zürich'),
                KAgentQuestionOption(id: 'berlin', label: 'Berlin'),
              ],
              answerSummary: _answer == null
                  ? null
                  : 'Ausgewählt: ${_answer!.optionIds.firstOrNull ?? '–'}',
              submitLabel: 'Fortsetzen',
            ),
            onResponse: (value) => setState(() => _answer = value),
          ),
        ),
        const KWorkflowEvent(
          id: 'paused',
          kind: KWorkflowEventKind.status,
          title: 'Statusänderung',
          description: 'Agent work paused',
          timestamp: '13:12',
          sequence: 5,
          status: KWorkflowStatus.paused,
        ),
      ],
    ),
    KWorkflowPhase(
      id: 'result',
      title: 'Ergebnis & Artefakte',
      status: KWorkflowStatus.succeeded,
      startedAt: minute(1.8),
      endedAt: minute(2.8),
      events: const [
        KWorkflowEvent(
          id: 'web-log',
          kind: KWorkflowEventKind.log,
          title: 'Log',
          description:
              'Pi tool web_search finished.\nPi tool fetch_content finished.',
          timestamp: '13:14',
          importance: KWorkflowEventImportance.technical,
        ),
        KWorkflowEvent(
          id: 'weather',
          kind: KWorkflowEventKind.result,
          title: 'Ergebnis',
          description: 'Wetter für Zürich',
          timestamp: '13:15',
          sequence: 15,
          interactive: true,
          content: _WeatherResult(),
        ),
        KWorkflowEvent(
          id: 'approved',
          kind: KWorkflowEventKind.approval,
          title: 'Ergebnis freigegeben',
          description: 'Vom Nutzer freigegeben',
          timestamp: '13:15',
        ),
      ],
    ),
    KWorkflowPhase(
      id: 'continue',
      title: 'Weiterarbeit',
      status: KWorkflowStatus.running,
      startedAt: minute(2.8),
      events: const [
        KWorkflowEvent(
          id: 'resumed',
          kind: KWorkflowEventKind.progress,
          title: 'Fortschritt',
          description: 'Die abschließende Dokumentation wird erstellt.',
          timestamp: 'jetzt',
          status: KWorkflowStatus.running,
        ),
      ],
    ),
  ];
}

class _WeatherResult extends StatelessWidget {
  const _WeatherResult();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Laut '),
          KLink(label: 'wttr.in', onPressed: () {}),
          const Text(', Gebiet Zürichhorn:'),
        ],
      ),
      const SizedBox(height: 8),
      const Text(
        '•  16 °C, bedeckt',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const Text('•  Gefühlt 14 °C'),
      const Text('•  Wind 4 km/h'),
      const SizedBox(height: 8),
      const Text(
        'Die Ortsrückfrage wurde beantwortet und erst danach recherchiert.',
      ),
    ],
  );
}
