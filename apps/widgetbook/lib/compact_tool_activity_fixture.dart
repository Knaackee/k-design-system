import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

/// Matches Storybook's agent-ui-compact-tools / project-selection fixtures.
class CompactToolActivityFixture extends StatefulWidget {
  const CompactToolActivityFixture({
    this.phone = false,
    this.question = false,
    super.key,
  });
  final bool phone;
  final bool question;
  @override
  State<CompactToolActivityFixture> createState() =>
      _CompactToolActivityFixtureState();
}

class _CompactToolActivityFixtureState
    extends State<CompactToolActivityFixture> {
  KAgentToolState _state = KAgentToolState.running;
  late bool _showQuestion = widget.question;
  String? _project;
  KAgentResolutionState _approval = KAgentResolutionState.pending;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final messages = [
      KChatMessageValue(
        id: 'activity-review',
        role: KChatRole.assistant,
        parts: [
          const KChatTextPart(
            id: 'intro',
            text:
                'Ich prüfe die passenden Projekte und bereite dein Issue vor.',
          ),
          for (final index in [1, 2, 3])
            KAgentToolPart(
              id: 'search-$index',
              toolName: 'search_issues',
              title: 'Issues durchsuchen',
              state: index == 3 ? _state : KAgentToolState.succeeded,
              arguments: {'project': 'Orbit', 'page': index},
              result: index == 3 && _state == KAgentToolState.running
                  ? null
                  : {'matches': 4},
              error: index == 3 && _state == KAgentToolState.failed
                  ? 'Die Suche konnte nicht abgeschlossen werden. Bitte erneut versuchen.'
                  : null,
            ),
          const KChatTextPart(
            id: 'result',
            text: 'Die technischen Details kannst du bei Bedarf aufklappen.',
          ),
          if (_showQuestion)
            KAgentQuestionPart(
              id: 'project-question',
              title: 'In welchem Projekt soll das Issue entstehen?',
              description:
                  'Wähle ein Projekt oder lege das Issue in deinem privaten Bereich an.',
              kind: KAgentQuestionKind.singleChoice,
              state: _project == null
                  ? KAgentResolutionState.pending
                  : KAgentResolutionState.answered,
              answerSummary: _project == null ? null : 'Ausgewählt: $_project',
              submitLabel: 'Auswahl übernehmen',
              options: const [
                KAgentQuestionOption(
                  id: 'Orbit',
                  label: 'Orbit',
                  description: 'Agent Runtime und Delegationen',
                ),
                KAgentQuestionOption(
                  id: 'Tasks',
                  label: 'Tasks',
                  description: 'Web- und Flutter-Anwendung',
                ),
                KAgentQuestionOption(
                  id: 'Privat',
                  label: 'Privater Bereich',
                  description: 'Ohne Projekt · Nur für dich',
                ),
              ],
            )
          else
            KAgentApprovalPart(
              id: 'approval',
              title: 'Issue erstellen?',
              description: 'Projekt Orbit · Morgen · Dir zugewiesen',
              state: _approval,
              options: const [
                KAgentApprovalOption(
                  id: 'approve',
                  label: 'Issue erstellen',
                  primary: true,
                ),
                KAgentApprovalOption(id: 'reject', label: 'Abbrechen'),
              ],
            ),
        ],
      ),
    ];
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: widget.phone ? 390 : 760,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(t.spaceControlInsetInline),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Wrap(
                  spacing: t.spaceControlGap,
                  runSpacing: t.spaceControlGap,
                  children: [
                    KButton(
                      label: 'Rückfrage',
                      variant: KButtonVariant.secondary,
                      onPressed: () => setState(() {
                        _showQuestion = true;
                        _project = null;
                      }),
                    ),
                    KButton(
                      label: 'Freigabe',
                      variant: KButtonVariant.secondary,
                      onPressed: () => setState(() {
                        _showQuestion = false;
                        _approval = KAgentResolutionState.pending;
                      }),
                    ),
                    for (final entry in [
                      ('Läuft', KAgentToolState.running),
                      ('Abgeschlossen', KAgentToolState.succeeded),
                      ('Fehler', KAgentToolState.failed),
                    ])
                      KButton(
                        label: entry.$1,
                        variant: KButtonVariant.secondary,
                        onPressed: () => setState(() => _state = entry.$2),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: KChatConversation(
                messages: messages,
                metadataMode: KChatMessageMetadataMode.hidden,
                showTimestamps: false,
                runState: _state == KAgentToolState.running
                    ? KChatRunState.streaming
                    : KChatRunState.awaitingInput,
                labels: const KChatLabels(
                  approvalNote: 'Anmerkung hinzufügen (optional)',
                ),
                onQuestionResponse: (response) =>
                    setState(() => _project = response.optionIds.firstOrNull),
                onApprovalResponse: (response) => setState(
                  () => _approval = response.optionId == 'approve'
                      ? KAgentResolutionState.approved
                      : KAgentResolutionState.rejected,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
