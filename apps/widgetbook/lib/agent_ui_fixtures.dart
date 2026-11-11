import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

enum AgentUiFixtureKind { conversation, messages, tools, approval, question }

class AgentUiFixture extends StatefulWidget {
  const AgentUiFixture({
    this.kind = AgentUiFixtureKind.conversation,
    this.metadataMode = KChatMessageMetadataMode.grouped,
    this.showTimestamps = true,
    this.extraMessages,
    this.onQuestionResponse,
    this.onFormResponse,
    this.onExternalAction,
    this.onAttachmentRequest,
    super.key,
  });

  final List<KChatMessageValue>? extraMessages;
  final ValueChanged<KAgentQuestionResponse>? onQuestionResponse;
  final ValueChanged<KAgentFormResponse>? onFormResponse;
  final ValueChanged<KAgentExternalActionResponse>? onExternalAction;
  final ValueChanged<KAgentAttachmentRequestResponse>? onAttachmentRequest;
  final AgentUiFixtureKind kind;
  final KChatMessageMetadataMode metadataMode;
  final bool showTimestamps;

  @override
  State<AgentUiFixture> createState() => _AgentUiFixtureState();
}

class _AgentUiFixtureState extends State<AgentUiFixture> {
  String draft = '';
  KChatRunState runState = KChatRunState.awaitingInput;
  KAgentApprovalResponse? approval;
  KAgentQuestionResponse? answer;
  final sentMessages = <KChatMessageValue>[];
  final attachments = <KChatAttachmentPart>[];
  bool voiceActive = false;
  String model = 'fast';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return ColoredBox(
      color: t.colorSurfaceCanvas,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: t.componentTopBarHeight),
            padding: EdgeInsets.symmetric(horizontal: t.spaceLayoutGutter),
            decoration: BoxDecoration(
              color: t.colorSurfaceRaised,
              border: Border(bottom: BorderSide(color: t.colorBorderDefault)),
            ),
            alignment: AlignmentDirectional.centerStart,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Design-System Agent',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  runState == KChatRunState.streaming
                      ? 'Antwortet…'
                      : runState == KChatRunState.awaitingInput
                      ? 'Wartet auf dich'
                      : 'Bereit',
                  style: TextStyle(
                    color: t.colorTextMuted,
                    fontSize: t.fontSize * 0.86,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: t.componentChatColumnMaxWidth,
                ),
                child: KChatConversation(
                  messages: [
                    if (widget.extraMessages == null)
                      ..._messages()
                    else ...[
                      ..._messages().take(2),
                      ...widget.extraMessages!,
                    ],
                    ...sentMessages,
                  ],
                  runState: runState,
                  labels: const KChatLabels(
                    assistant: 'Agent',
                    user: 'Du',
                    loadOlder: 'Frühere Nachrichten laden',
                    sending: 'Wird gesendet…',
                    sent: 'Gesendet',
                    failed: 'Nicht gesendet',
                  ),
                  metadataMode: widget.metadataMode,
                  metadataByRole: widget.kind == AgentUiFixtureKind.conversation
                      ? const {
                          KChatRole.user: KChatMessageMetadataMode.hidden,
                          KChatRole.system: KChatMessageMetadataMode.hidden,
                        }
                      : const {},
                  showTimestamps: widget.showTimestamps,
                  onApprovalResponse: (response) => setState(() {
                    approval = response;
                    runState = KChatRunState.idle;
                  }),
                  onQuestionResponse: (response) => setState(() {
                    answer = response;
                    widget.onQuestionResponse?.call(response);
                    runState = KChatRunState.idle;
                  }),
                  onFormResponse: (response) {
                    widget.onFormResponse?.call(response);
                    setState(() => runState = KChatRunState.idle);
                  },
                  onExternalAction: (response) {
                    widget.onExternalAction?.call(response);
                    setState(() => runState = KChatRunState.idle);
                  },
                  onAttachmentRequest: (response) {
                    widget.onAttachmentRequest?.call(response);
                    setState(() => runState = KChatRunState.idle);
                  },
                  onSourceActivate: (source) => _notice(source.title),
                  onArtifactActivate: (artifact) => _notice(artifact.title),
                  onLinkActivate: (uri) => _notice(uri.toString()),
                  formatTimestamp: (value) =>
                      '${value.hour.toString().padLeft(2, '0')}:'
                      '${value.minute.toString().padLeft(2, '0')}',
                ),
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
                onSubmit: _submit,
                onStop: () => setState(() => runState = KChatRunState.stopped),
                runState: runState,
                labels: const KChatComposerLabels(
                  placeholder: 'Nachricht an den Agenten…',
                ),
                attachments: attachments,
                onAttachmentRemove: (attachment) => setState(
                  () => attachments.removeWhere(
                    (item) => item.id == attachment.id,
                  ),
                ),
                onAttach: () => setState(() {
                  if (attachments.isEmpty) {
                    attachments.add(
                      const KChatAttachmentPart(
                        id: 'brief.pdf',
                        title: 'Release-Brief.pdf',
                        description: 'PDF · 1,8 MB',
                      ),
                    );
                  }
                }),
                voiceActive: voiceActive,
                onVoiceInput: () => setState(() => voiceActive = !voiceActive),
                models: const [
                  KChatComposerModel(value: 'fast', label: 'K Fast'),
                  KChatComposerModel(value: 'quality', label: 'K Quality'),
                ],
                model: model,
                onModelChanged: (value) =>
                    setState(() => model = value ?? model),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit(String text) => setState(() {
    sentMessages.add(
      KChatMessageValue(
        id: 'user-${sentMessages.length}',
        role: KChatRole.user,
        authorLabel: 'Du',
        timestamp: DateTime.now(),
        parts: [KChatTextPart(id: 'text-${sentMessages.length}', text: text)],
      ),
    );
    draft = '';
    runState = KChatRunState.streaming;
  });

  void _notice(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  List<KChatMessageValue> _messages() {
    final intro = <KChatMessageValue>[
      KChatMessageValue(
        id: 'request',
        role: KChatRole.user,
        authorLabel: 'Du',
        timestamp: DateTime(2026, 9, 24, 10, 42),
        parts: const [
          KChatTextPart(
            id: 'request-text',
            text:
                'Prüfe die neue Chat-Komponente und bereite die Veröffentlichung vor.',
          ),
        ],
      ),
      KChatMessageValue(
        id: 'agent',
        role: KChatRole.assistant,
        authorLabel: 'Agent',
        timestamp: DateTime(2026, 9, 24, 10, 42),
        parts: const [
          KChatTextPart(
            id: 'agent-text',
            text:
                'Ich prüfe **Web und Flutter** mit denselben Zuständen. Die Komponenten bleiben transportneutral und senden nur typisierte Events an den Host.',
          ),
          KAgentTaskPart(
            id: 'tasks',
            title: 'Veröffentlichung vorbereiten',
            items: [
              KAgentTaskItem(
                id: 'task-1',
                title: 'Komponenten prüfen',
                state: KAgentTaskState.completed,
              ),
              KAgentTaskItem(
                id: 'task-2',
                title: 'Galerien abgleichen',
                state: KAgentTaskState.active,
              ),
              KAgentTaskItem(
                id: 'task-3',
                title: 'Release freigeben',
                state: KAgentTaskState.pending,
              ),
            ],
          ),
        ],
      ),
    ];
    final tools = KChatMessageValue(
      id: 'tools',
      role: KChatRole.assistant,
      authorLabel: 'Agent',
      parts: [
        KAgentToolPart(
          id: 'tool-read',
          toolName: 'read_design_tokens',
          title: 'Design Tokens gelesen',
          description:
              'Die Agentenoberfläche nutzt ausschließlich öffentliche semantische Tokens.',
          state: KAgentToolState.succeeded,
          arguments: {'theme': 'Orbit Dark'},
          result: {'tokens': 184, 'violations': 0},
        ),
        KAgentActivityPart(
          id: 'activity',
          title: 'Galerien werden verglichen',
          summary:
              'Storybook und Widgetbook erhalten identische Fixture-Zustände.',
          active: true,
        ),
        KAgentSourcePart(
          id: 'source',
          title: 'Agent-UI-Spezifikation',
          description: 'Transportneutrale Agent-UI-Entscheidung',
          url: Uri.https('sdk.vercel.ai', '/docs/ai-sdk-ui'),
        ),
      ],
    );
    final approvalMessage = KChatMessageValue(
      id: 'approval-message',
      role: KChatRole.assistant,
      authorLabel: 'Agent',
      parts: [
        KAgentApprovalPart(
          id: 'release-approval',
          title: 'Veröffentlichung freigeben?',
          description:
              'Die sichtbare Demo ist bereit. Der Host entscheidet, was die Aktion ausführt.',
          detail: 'Ziel: design-system-preview\nUmfang: Chat + Agent UI',
          state: approval == null
              ? KAgentResolutionState.pending
              : approval!.optionId == 'approve'
              ? KAgentResolutionState.approved
              : KAgentResolutionState.rejected,
          options: const [
            KAgentApprovalOption(id: 'reject', label: 'Ablehnen'),
            KAgentApprovalOption(
              id: 'approve',
              label: 'Freigeben',
              primary: true,
            ),
          ],
          responseSummary: approval == null
              ? null
              : approval!.optionId == 'approve'
              ? 'Freigegeben'
              : 'Abgelehnt',
        ),
      ],
    );
    final questionMessage = KChatMessageValue(
      id: 'question-message',
      role: KChatRole.assistant,
      authorLabel: 'Agent',
      parts: [
        KAgentQuestionPart(
          id: 'density-question',
          statusLabel: 'Wartet auf deine Eingabe',
          title: 'Welche Dichte soll die Vorschau verwenden?',
          description: 'Wähle eine Option und bestätige deine Antwort.',
          kind: KAgentQuestionKind.singleChoice,
          state: answer == null
              ? KAgentResolutionState.pending
              : KAgentResolutionState.answered,
          options: const [
            KAgentQuestionOption(
              id: 'dense',
              label: 'Kompakt',
              description: 'Für produktive Desktop-Oberflächen',
            ),
            KAgentQuestionOption(
              id: 'comfortable',
              label: 'Großzügig',
              description: 'Mehr Raum für Touch-Eingaben',
            ),
          ],
          answerSummary: answer == null
              ? null
              : 'Ausgewählt: ${answer!.optionIds.firstOrNull ?? '–'}',
          submitLabel: 'Senden',
        ),
      ],
    );
    final messageStates = [
      KChatMessageValue(
        id: 'message-user-sent',
        role: KChatRole.user,
        authorLabel: 'Du',
        timestamp: DateTime(2026, 9, 24, 10, 44),
        status: KChatMessageStatus.sent,
        parts: const [
          KChatTextPart(
            id: 'message-user-sent-text',
            text: 'Fasse die Unterschiede zwischen Web und Flutter zusammen.',
          ),
        ],
      ),
      KChatMessageValue(
        id: 'message-agent-answer',
        role: KChatRole.assistant,
        authorLabel: 'Agent',
        timestamp: DateTime(2026, 9, 24, 10, 44),
        parts: const [
          KChatTextPart(
            id: 'message-agent-answer-text',
            text:
                'Beide Plattformen verwenden dieselben Zustände. Metadaten können vollständig, gruppiert oder ausgeblendet dargestellt werden.',
          ),
        ],
      ),
      KChatMessageValue(
        id: 'message-user-sending',
        role: KChatRole.user,
        authorLabel: 'Du',
        timestamp: DateTime(2026, 9, 24, 10, 45),
        status: KChatMessageStatus.sending,
        parts: const [
          KChatTextPart(
            id: 'message-user-sending-text',
            text: 'Zeige auch den Versandstatus.',
          ),
        ],
      ),
      KChatMessageValue(
        id: 'message-user-failed',
        role: KChatRole.user,
        authorLabel: 'Du',
        timestamp: DateTime(2026, 9, 24, 10, 45),
        status: KChatMessageStatus.failed,
        parts: const [
          KChatTextPart(
            id: 'message-user-failed-text',
            text: 'Diese Nachricht konnte nicht gesendet werden.',
          ),
        ],
      ),
    ];
    return switch (widget.kind) {
      AgentUiFixtureKind.messages => messageStates,
      AgentUiFixtureKind.tools => [...intro, tools],
      AgentUiFixtureKind.approval => [...intro, approvalMessage],
      AgentUiFixtureKind.question => [...intro, questionMessage],
      AgentUiFixtureKind.conversation => [
        ...intro,
        tools,
        approvalMessage,
        questionMessage,
      ],
    };
  }
}
