import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

import 'agent_ui_fixtures.dart';

enum AskToolsFixtureKind {
  textQuestion,
  singleChoice,
  multipleChoice,
  confirmation,
  form,
  externalAction,
  attachmentRequest,
  all,
}

class AskToolsFixture extends StatefulWidget {
  const AskToolsFixture({this.kind = AskToolsFixtureKind.all, super.key});
  final AskToolsFixtureKind kind;
  @override
  State<AskToolsFixture> createState() => _AskToolsFixtureState();
}

class _AskToolsFixtureState extends State<AskToolsFixture> {
  final questions = <String, KAgentQuestionResponse>{};
  KAgentFormResponse? form;
  KAgentExternalActionResponse? external;
  KAgentAttachmentRequestResponse? attachment;

  @override
  Widget build(BuildContext context) => AgentUiFixture(
    extraMessages: _messages(),
    onQuestionResponse: (value) =>
        setState(() => questions[value.questionId] = value),
    onFormResponse: (value) => setState(() => form = value),
    onExternalAction: (value) => setState(() => external = value),
    onAttachmentRequest: (value) => setState(() => attachment = value),
  );

  List<KChatMessageValue> _messages() {
    final parts = <AskToolsFixtureKind, KChatMessagePart>{
      AskToolsFixtureKind.textQuestion: KAgentQuestionPart(
        id: 'release-note-question',
        statusLabel: 'Wartet auf deine Eingabe',
        title: 'Wie soll die Änderung beschrieben werden?',
        description: 'Eine freie Rückfrage mit typisiertem Antwort-Event.',
        kind: KAgentQuestionKind.text,
        state: _questionState('release-note-question'),
        placeholder: 'Kurze Beschreibung…',
        submitLabel: 'Antworten',
        answerSummary: questions['release-note-question']?.text,
      ),
      AskToolsFixtureKind.singleChoice: KAgentQuestionPart(
        id: 'density-question',
        statusLabel: 'Wartet auf deine Eingabe',
        title: 'Welche Dichte soll die Vorschau verwenden?',
        description: 'Wähle eine Option und bestätige deine Antwort.',
        kind: KAgentQuestionKind.singleChoice,
        state: _questionState('density-question'),
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
        submitLabel: 'Senden',
        answerSummary: questions['density-question'] == null
            ? null
            : 'Ausgewählt: ${questions['density-question']!.optionIds.firstOrNull ?? '–'}',
      ),
      AskToolsFixtureKind.multipleChoice: KAgentQuestionPart(
        id: 'checks-question',
        statusLabel: 'Wartet auf deine Eingabe',
        title: 'Welche Prüfungen sollen ausgeführt werden?',
        kind: KAgentQuestionKind.multipleChoice,
        state: _questionState('checks-question'),
        options: const [
          KAgentQuestionOption(
            id: 'web',
            label: 'Web',
            description: 'Typecheck und Storybook',
          ),
          KAgentQuestionOption(
            id: 'flutter',
            label: 'Flutter',
            description: 'Analyze und Widgetbook',
          ),
          KAgentQuestionOption(
            id: 'a11y',
            label: 'Accessibility',
            description: 'Semantik und Kontrast',
          ),
        ],
        submitLabel: 'Prüfungen starten',
        answerSummary: questions['checks-question'] == null
            ? null
            : '${questions['checks-question']!.optionIds.length} ausgewählt',
      ),
      AskToolsFixtureKind.confirmation: KAgentQuestionPart(
        id: 'replace-confirmation',
        statusLabel: 'Bitte bestätigen',
        title: 'Bestehende Vorschau ersetzen?',
        description:
            'Diese fachliche Bestätigung führt noch keine Tool-Aktion aus.',
        kind: KAgentQuestionKind.confirmation,
        state: _questionState('replace-confirmation'),
        options: const [
          KAgentQuestionOption(id: 'cancel', label: 'Behalten'),
          KAgentQuestionOption(id: 'replace', label: 'Ersetzen'),
        ],
        submitLabel: 'Übernehmen',
        answerSummary: questions['replace-confirmation'] == null
            ? null
            : 'Antwort: ${questions['replace-confirmation']!.optionIds.firstOrNull ?? '–'}',
      ),
      AskToolsFixtureKind.form: KAgentFormPart(
        id: 'release-form',
        title: 'Release konfigurieren',
        description:
            'Mehrere schemaorientierte Felder werden gemeinsam beantwortet.',
        state: form == null
            ? KAgentResolutionState.pending
            : form!.submit
            ? KAgentResolutionState.answered
            : KAgentResolutionState.cancelled,
        fields: const [
          KAgentFormField(
            id: 'name',
            kind: KAgentFormFieldKind.text,
            label: 'Release-Name',
            placeholder: 'September Release',
            required: true,
          ),
          KAgentFormField(
            id: 'environment',
            kind: KAgentFormFieldKind.singleChoice,
            label: 'Umgebung',
            defaultValue: 'preview',
            required: true,
            options: [
              KAgentQuestionOption(id: 'preview', label: 'Preview'),
              KAgentQuestionOption(id: 'production', label: 'Production'),
            ],
          ),
          KAgentFormField(
            id: 'checks',
            kind: KAgentFormFieldKind.multipleChoice,
            label: 'Checks',
            defaultValue: ['web'],
            minItems: 1,
            options: [
              KAgentQuestionOption(id: 'web', label: 'Web'),
              KAgentQuestionOption(id: 'flutter', label: 'Flutter'),
              KAgentQuestionOption(id: 'a11y', label: 'Accessibility'),
            ],
          ),
          KAgentFormField(
            id: 'notify',
            kind: KAgentFormFieldKind.boolean,
            label: 'Team benachrichtigen',
            defaultValue: true,
          ),
        ],
        cancelLabel: 'Abbrechen',
        submitLabel: 'Konfiguration übernehmen',
        responseSummary: form == null
            ? null
            : '${form!.values.length} Angaben übernommen',
      ),
      AskToolsFixtureKind.externalAction: KAgentExternalActionPart(
        id: 'external-auth',
        title: 'Mit GitHub verbinden',
        description:
            'Die Anmeldung findet außerhalb des Agentenverlaufs statt.',
        url: Uri.parse('https://github.com/login'),
        actionLabel: 'GitHub öffnen',
        cancelLabel: 'Nicht jetzt',
        state: external == null
            ? KAgentResolutionState.pending
            : external!.open
            ? KAgentResolutionState.answered
            : KAgentResolutionState.cancelled,
        responseSummary: external == null
            ? null
            : external!.open
            ? 'Externe Anmeldung geöffnet'
            : 'Abgebrochen',
      ),
      AskToolsFixtureKind.attachmentRequest: KAgentAttachmentRequestPart(
        id: 'brief-request',
        title: 'Release-Brief anhängen',
        description: 'PDF oder Bild, maximal zwei Dateien.',
        actionLabel: 'Dateien auswählen',
        accept: '.pdf,image/*',
        multiple: true,
        maxFiles: 2,
        state: attachment == null
            ? KAgentResolutionState.pending
            : KAgentResolutionState.answered,
        attachments: attachment == null
            ? const []
            : const [
                KChatAttachmentPart(
                  id: 'brief',
                  title: 'Release-Brief.pdf',
                  description: 'PDF · 1,8 MB',
                ),
              ],
        responseSummary: attachment == null ? null : '1 Datei ausgewählt',
      ),
    };
    final visible = widget.kind == AskToolsFixtureKind.all
        ? [
            parts[AskToolsFixtureKind.singleChoice]!,
            parts[AskToolsFixtureKind.textQuestion]!,
            parts[AskToolsFixtureKind.multipleChoice]!,
            parts[AskToolsFixtureKind.confirmation]!,
            parts[AskToolsFixtureKind.form]!,
            parts[AskToolsFixtureKind.externalAction]!,
            parts[AskToolsFixtureKind.attachmentRequest]!,
          ]
        : [parts[widget.kind]!];
    return [
      for (final part in visible)
        KChatMessageValue(
          id: '${part.id}-message',
          role: KChatRole.assistant,
          authorLabel: 'Agent',
          parts: [part],
        ),
    ];
  }

  KAgentResolutionState _questionState(String id) => questions[id] == null
      ? KAgentResolutionState.pending
      : KAgentResolutionState.answered;
}
