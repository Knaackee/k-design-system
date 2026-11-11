import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

import 'agent_ui_complete_data.dart';

enum CompleteScenario { empty, history, streaming }

/// Gallery-owned state; all rendered chat elements use the public K API.
class AgentUiCompleteFixture extends StatefulWidget {
  const AgentUiCompleteFixture({
    this.scenario = CompleteScenario.history,
    super.key,
  });
  final CompleteScenario scenario;
  @override
  State<AgentUiCompleteFixture> createState() => _AgentUiCompleteFixtureState();
}

class _AgentUiCompleteFixtureState extends State<AgentUiCompleteFixture> {
  late CompleteScenario scenario = widget.scenario;
  CompleteResponses responses = CompleteResponses();
  String draft = '', notice = '', model = 'fast';
  List<KChatAttachmentPart> attachments = [];
  final sent = <KChatMessageValue>[];
  late KChatRunState runState = widget.scenario == CompleteScenario.streaming
      ? KChatRunState.streaming
      : KChatRunState.idle;
  int resetKey = 0;
  bool get running => runState == KChatRunState.streaming;
  bool get uploading =>
      attachments.any((p) => p.state == KChatAttachmentPartState.uploading);

  @override
  void didUpdateWidget(covariant AgentUiCompleteFixture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scenario != widget.scenario) _reset(widget.scenario);
  }

  void _reset(CompleteScenario next) => setState(() {
    scenario = next;
    responses = CompleteResponses();
    draft = notice = '';
    attachments = [];
    sent.clear();
    runState = next == CompleteScenario.streaming
        ? KChatRunState.streaming
        : KChatRunState.idle;
    resetKey++;
  });

  List<KChatMessageValue> get messages => [
    if (scenario != CompleteScenario.empty) ...completeMessages(responses),
    ...sent,
    if (running ||
        runState == KChatRunState.stopped ||
        runState == KChatRunState.completed)
      KChatMessageValue(
        id: 'live-answer',
        role: KChatRole.assistant,
        authorLabel: 'Design-System Agent',
        parts: [
          KAgentActivityPart(
            id: 'live-activity',
            title: running
                ? 'Übergabe wird formuliert'
                : runState == KChatRunState.stopped
                ? 'Antwort gestoppt'
                : 'Übergabe formuliert',
            summary:
                'Lokale Simulation ohne Timer. Stoppen oder Abschließen verändert diesen Zustand.',
            active: running,
          ),
          KChatTextPart(
            id: 'live-text',
            text: runState == KChatRunState.completed
                ? 'Die **lokale Übergabe** ist formuliert. Der Entwurf und deine Eingaben bleiben in dieser Vorschau erhalten.'
                : 'Ich formuliere die **Übergabe** aus dem Entwurf und deinen Angaben…',
            streaming: running,
          ),
        ],
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return LayoutBuilder(
      builder: (context, constraints) => ColoredBox(
        color: t.colorSurfaceCanvas,
        child: Column(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: constraints.maxHeight / 2),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: t.spaceLayoutGutter,
                    vertical: t.spaceControlGap,
                  ),
                  child: KStack(
                    gap: KLayoutGap.control,
                    align: KLayoutAlign.stretch,
                    children: [
                      KInline(
                        gap: KLayoutGap.action,
                        wrap: true,
                        children: [
                          const KText(
                            'Agent UI Complete',
                            variant: KTextVariant.label,
                          ),
                          KSegmentedControl<CompleteScenario>(
                            label: 'Demo-Szenario',
                            value: scenario,
                            onChanged: _reset,
                            segments: const [
                              KSegment(
                                value: CompleteScenario.empty,
                                label: 'Leer',
                              ),
                              KSegment(
                                value: CompleteScenario.history,
                                label: 'Verlauf',
                              ),
                              KSegment(
                                value: CompleteScenario.streaming,
                                label: 'Antwort läuft',
                              ),
                            ],
                          ),
                          KButton(
                            label: 'Zurücksetzen',
                            variant: KButtonVariant.secondary,
                            onPressed: () => _reset(scenario),
                          ),
                          if (running)
                            KButton(
                              label: 'Antwort abschließen',
                              variant: KButtonVariant.secondary,
                              onPressed: () => setState(
                                () => runState = KChatRunState.completed,
                              ),
                            ),
                          if (uploading)
                            KButton(
                              label: 'Demo-Upload abschließen',
                              variant: KButtonVariant.secondary,
                              onPressed: () =>
                                  setState(() => attachments = [demoBrief]),
                            ),
                        ],
                      ),
                      Semantics(
                        liveRegion: true,
                        child: KText(
                          notice.isNotEmpty
                              ? notice
                              : running
                              ? 'Simulierte Antwort läuft · mit Stopp anhalten oder manuell abschließen.'
                              : 'Lokale Beispieldaten · keine Verbindung, Aufnahme oder Veröffentlichung.',
                          variant: KTextVariant.caption,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: KChatConversation(
                key: ValueKey(resetKey),
                messages: messages,
                runState: runState,
                metadataMode: KChatMessageMetadataMode.grouped,
                metadataByRole: const {
                  KChatRole.user: KChatMessageMetadataMode.hidden,
                  KChatRole.system: KChatMessageMetadataMode.hidden,
                },
                formatTimestamp: (value) =>
                    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
                labels: const KChatLabels(
                  assistant: 'Agent',
                  user: 'Du',
                  emptyTitle: 'Womit möchtest du starten?',
                  emptyDescription:
                      'Sende eine Nachricht oder wähle den vorbereiteten Verlauf.',
                  newContent: 'Zur neuesten Nachricht',
                  sending: 'Wird gesendet…',
                  sent: 'Gesendet',
                  failed: 'Nicht gesendet',
                  approvalNote: 'Notiz ergänzen (optional)',
                ),
                onQuestionResponse: (r) =>
                    setState(() => responses.questions[r.questionId] = r),
                onApprovalResponse: (r) =>
                    setState(() => responses.approvals[r.approvalId] = r),
                onFormResponse: (r) =>
                    setState(() => responses.forms[r.formId] = r),
                onExternalAction: (r) =>
                    setState(() => responses.external[r.actionId] = r),
                onAttachmentRequest: (r) =>
                    setState(() => responses.attachments[r.requestId] = r),
                onArtifactActivate: (_) => _notice(
                  'Agent-UI-Release.md: Der Entwurf ist oben als Markdown im Verlauf sichtbar.',
                ),
                onAttachmentActivate: (p) => _notice(
                  '${p.title}: Beispieldatei ohne Dateiinhalt; kein Download.',
                ),
                onSourceActivate: (_) => _notice(
                  'Lokale Quelle: Release-Brief, Abschnitt 2. Kein externes Dokument verbunden.',
                ),
                onLinkActivate: (_) => _notice(
                  'Demo-Link ausgewählt. Es wird keine externe Seite geöffnet.',
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      t.componentChatColumnMaxWidth +
                      t.componentChatComposerOverhang * 2,
                ),
                child: KChatComposer(
                  value: draft,
                  onValueChanged: (value) => setState(() => draft = value),
                  runState: runState,
                  labels: const KChatComposerLabels(
                    input: 'Nachricht',
                    placeholder: 'Nachricht an den Agenten…',
                    send: 'Nachricht senden',
                    stop: 'Antwort stoppen',
                    attach: 'Demo-Datei anhängen',
                    removeAttachment: 'Anhang entfernen',
                    model: 'Demo-Modell',
                  ),
                  attachments: attachments,
                  onAttach: () => setState(
                    () => attachments = [
                      const KChatAttachmentPart(
                        id: 'release-brief',
                        title: 'Release-Brief.pdf',
                        description: 'PDF · lokale Beispieldatei',
                        state: KChatAttachmentPartState.uploading,
                        progress: 0.45,
                      ),
                    ],
                  ),
                  onAttachmentActivate: (p) => _notice(
                    '${p.title}: Lokale Beispieldatei ohne Dateiinhalt.',
                  ),
                  onAttachmentRemove: (p) => setState(
                    () => attachments.removeWhere((item) => item.id == p.id),
                  ),
                  models: const [
                    KChatComposerModel(value: 'fast', label: 'K Fast · Demo'),
                    KChatComposerModel(
                      value: 'quality',
                      label: 'K Quality · Demo',
                    ),
                  ],
                  model: model,
                  onModelChanged: (value) =>
                      setState(() => model = value ?? model),
                  onStop: () =>
                      setState(() => runState = KChatRunState.stopped),
                  submitEnabled: !uploading,
                  onSubmit: (text) => setState(() {
                    sent.add(
                      KChatMessageValue(
                        id: 'local-${sent.length}',
                        role: KChatRole.user,
                        authorLabel: 'Du',
                        status: KChatMessageStatus.sent,
                        parts: [
                          KChatTextPart(
                            id: 'local-text-${sent.length}',
                            text: text,
                          ),
                          ...attachments,
                        ],
                      ),
                    );
                    draft = notice = '';
                    attachments = [];
                    runState = KChatRunState.streaming;
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _notice(String value) => setState(() => notice = value);
}
