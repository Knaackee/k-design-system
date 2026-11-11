import 'package:k_design_ui/k_design_ui.dart';

const demoBrief = KChatAttachmentPart(
  id: 'release-brief',
  title: 'Release-Brief.pdf',
  description: 'PDF · lokale Beispieldatei',
);

class CompleteResponses {
  final questions = <String, KAgentQuestionResponse>{
    'audience': const KAgentQuestionResponse(
      questionId: 'audience',
      optionIds: ['team'],
    ),
  };
  final approvals = <String, KAgentApprovalResponse>{};
  final forms = <String, KAgentFormResponse>{};
  final external = <String, KAgentExternalActionResponse>{};
  final attachments = <String, KAgentAttachmentRequestResponse>{};
}

const _summary =
    '''Ich habe den Brief ausgewertet und einen **lokalen Entwurf** vorbereitet.

| Bereich | Ergebnis |
| --- | --- |
| Web | Chat und Rückfragen beschrieben |
| Flutter | Abgleich als nächster Schritt vorgemerkt |
| Veröffentlichung | Noch nicht freigegeben |

Vor der Übergabe:
1. Zielgruppe und Prüfungen festlegen.
2. Release-Angaben ergänzen.
3. Den Entwurf ausdrücklich freigeben.

Die Übergabe verwendet diese Konfiguration:

```json
{
  "release": "Agent UI",
  "channel": "preview",
  "publish": false
}
```

Alle Angaben sind Beispieldaten; es wird nichts veröffentlicht.''';

List<KChatMessageValue> completeMessages(CompleteResponses state) {
  final checks = state.questions['checks'];
  final note = state.questions['note'];
  final confirmation = state.questions['confirmation'];
  final form = state.forms['release-config'];
  final approval = state.approvals['release-approval'];
  final external = state.external['review-space'];
  final attachment = state.attachments['screenshot-request'];
  KChatMessageValue agent(
    String id,
    int minute,
    List<KChatMessagePart> parts,
  ) => KChatMessageValue(
    id: id,
    role: KChatRole.assistant,
    authorLabel: 'Design-System Agent',
    timestamp: DateTime(2026, 9, 24, 10, minute),
    parts: parts,
  );
  return [
    KChatMessageValue(
      id: 'request',
      role: KChatRole.user,
      authorLabel: 'Du',
      timestamp: DateTime(2026, 9, 24, 10, 42),
      status: KChatMessageStatus.sent,
      parts: const [
        KChatTextPart(
          id: 'request-text',
          text:
              'Bereite aus diesem Brief eine Vorschau für das Agent-UI-Release vor. Zeige mir den Entwurf, bevor etwas veröffentlicht wird.',
        ),
        demoBrief,
      ],
    ),
    agent('analysis', 42, [
      const KAgentActivityPart(
        id: 'analysis-activity',
        title: 'Brief und Komponenten geprüft',
        summary:
            'Den Brief gelesen, die öffentlichen Web-Komponenten zugeordnet und einen Vorschau-Entwurf erstellt.',
      ),
      const KAgentToolPart(
        id: 'read-brief',
        toolName: 'read_file',
        title: 'Dateien gelesen',
        state: KAgentToolState.succeeded,
        arguments: {'path': 'Release-Brief.pdf'},
        result: {'sections': 4, 'release': 'Agent UI'},
      ),
      const KAgentToolPart(
        id: 'read-catalog',
        toolName: 'read_file',
        title: 'Dateien gelesen',
        state: KAgentToolState.succeeded,
        arguments: {'path': 'component-catalog.md'},
        result: {
          'components': ['KChatConversation', 'KAgentQuestion', 'KAgentForm'],
        },
      ),
      KAgentQuestionPart(
        id: 'audience',
        title: 'Für wen ist die Vorschau?',
        kind: KAgentQuestionKind.singleChoice,
        state: KAgentResolutionState.answered,
        options: const [
          KAgentQuestionOption(id: 'team', label: 'Internes Team'),
          KAgentQuestionOption(id: 'public', label: 'Öffentlich'),
        ],
        selectedOptionIds: state.questions['audience']!.optionIds,
        answerSummary: 'Internes Team',
      ),
    ]),
    agent('draft', 43, [
      const KChatTextPart(id: 'summary', text: _summary),
      KAgentTaskPart(
        id: 'plan',
        title: 'Release vorbereiten',
        items: [
          const KAgentTaskItem(
            id: 'read',
            title: 'Brief auswerten',
            state: KAgentTaskState.completed,
          ),
          KAgentTaskItem(
            id: 'configure',
            title: 'Prüfumfang und Angaben bestätigen',
            state: form?.submit == true
                ? KAgentTaskState.completed
                : KAgentTaskState.active,
          ),
          KAgentTaskItem(
            id: 'approve',
            title: 'Entwurf freigeben',
            state: approval?.optionId == 'approve'
                ? KAgentTaskState.completed
                : KAgentTaskState.pending,
          ),
        ],
      ),
      const KAgentSourcePart(
        id: 'source',
        title: 'Release-Brief · Abschnitt 2',
        description: 'Lokale Quelle für den Vorschau-Entwurf',
      ),
    ]),
    agent('questions', 44, [
      KAgentQuestionPart(
        id: 'checks',
        statusLabel: 'Wartet auf deine Eingabe',
        title: 'Welche Prüfungen gehören in die Übergabe?',
        description:
            'Die Auswahl bleibt in dieser Demo und startet keine Prüfprogramme.',
        kind: KAgentQuestionKind.multipleChoice,
        state: checks == null
            ? KAgentResolutionState.pending
            : KAgentResolutionState.answered,
        options: const [
          KAgentQuestionOption(
            id: 'web',
            label: 'Web',
            description: 'Storybook und Typecheck',
          ),
          KAgentQuestionOption(
            id: 'flutter',
            label: 'Flutter',
            description: 'Für den späteren Galerie-Abgleich',
          ),
          KAgentQuestionOption(id: 'a11y', label: 'Barrierefreiheit'),
        ],
        selectedOptionIds: checks?.optionIds ?? [],
        answerSummary: checks?.optionIds.join(', '),
        submitLabel: 'Prüfumfang übernehmen',
      ),
      KAgentQuestionPart(
        id: 'note',
        statusLabel: 'Wartet auf deine Eingabe',
        title: 'Was soll in den Release-Hinweis?',
        kind: KAgentQuestionKind.text,
        state: note == null
            ? KAgentResolutionState.pending
            : KAgentResolutionState.answered,
        placeholder: 'Kurze Beschreibung für das Team…',
        answerSummary: note?.text,
        submitLabel: 'Hinweis übernehmen',
      ),
      KAgentQuestionPart(
        id: 'confirmation',
        statusLabel: 'Bitte bestätigen',
        title: 'Den Entwurf als Vorschau kennzeichnen?',
        kind: KAgentQuestionKind.confirmation,
        state: confirmation == null
            ? KAgentResolutionState.pending
            : KAgentResolutionState.answered,
        options: const [
          KAgentQuestionOption(id: 'yes', label: 'Als Vorschau'),
          KAgentQuestionOption(id: 'no', label: 'Als Arbeitsstand'),
        ],
        selectedOptionIds: confirmation?.optionIds ?? [],
        answerSummary: confirmation == null
            ? null
            : confirmation.optionIds.firstOrNull == 'yes'
            ? 'Als Vorschau'
            : 'Als Arbeitsstand',
        submitLabel: 'Kennzeichnung übernehmen',
      ),
    ]),
    agent('configuration', 45, [
      KAgentFormPart(
        id: 'release-config',
        title: 'Vorschau konfigurieren',
        description:
            'Pflichtfelder müssen ausgefüllt sein. Alle Werte bleiben lokal.',
        state: form == null
            ? KAgentResolutionState.pending
            : form.submit
            ? KAgentResolutionState.answered
            : KAgentResolutionState.cancelled,
        fields: const [
          KAgentFormField(
            id: 'name',
            kind: KAgentFormFieldKind.text,
            label: 'Release-Name',
            required: true,
            placeholder: 'Agent UI Vorschau',
          ),
          KAgentFormField(
            id: 'channel',
            kind: KAgentFormFieldKind.singleChoice,
            label: 'Kanal',
            required: true,
            defaultValue: 'preview',
            options: [
              KAgentQuestionOption(id: 'preview', label: 'Vorschau'),
              KAgentQuestionOption(
                id: 'internal',
                label: 'Interner Arbeitsstand',
              ),
            ],
          ),
          KAgentFormField(
            id: 'reviewers',
            kind: KAgentFormFieldKind.number,
            label: 'Anzahl Reviewer',
            minimum: 1,
            maximum: 5,
            defaultValue: 2,
          ),
          KAgentFormField(
            id: 'include-checklist',
            kind: KAgentFormFieldKind.boolean,
            label: 'Checkliste beilegen',
            defaultValue: true,
          ),
        ],
        submitLabel: 'Angaben übernehmen',
        cancelLabel: 'Überspringen',
        responseSummary: form == null
            ? null
            : form.submit
            ? '${form.values['name']} · ${form.values['channel']} · ${form.values['reviewers']} Reviewer'
            : 'Konfiguration übersprungen',
      ),
      KAgentExternalActionPart(
        id: 'review-space',
        title: 'Review-Raum vorbereiten',
        description:
            'Lokale Simulation: Es wird kein Browserfenster geöffnet und keine Verbindung aufgebaut.',
        url: Uri.parse('https://example.invalid/review'),
        actionLabel: 'Verbindung simulieren',
        cancelLabel: 'Überspringen',
        state: external == null
            ? KAgentResolutionState.pending
            : external.open
            ? KAgentResolutionState.answered
            : KAgentResolutionState.cancelled,
        responseSummary: external == null
            ? null
            : external.open
            ? 'Verbindung lokal simuliert'
            : 'Übersprungen',
      ),
      KAgentAttachmentRequestPart(
        id: 'screenshot-request',
        title: 'Vorschau-Bild ergänzen',
        description:
            'Fügt ein lokales Demo-Bild hinzu; es öffnet sich keine Dateiauswahl.',
        actionLabel: 'Demo-Bild hinzufügen',
        accept: 'image/*',
        maxFiles: 1,
        state: attachment == null
            ? KAgentResolutionState.pending
            : KAgentResolutionState.answered,
        attachments: attachment == null
            ? []
            : const [
                KChatAttachmentPart(
                  id: 'preview-image',
                  title: 'Agent-UI-Vorschau.png',
                  description: 'PNG · Beispieldatei',
                  state: KChatAttachmentPartState.complete,
                ),
              ],
        responseSummary: attachment == null ? null : 'Demo-Bild hinzugefügt',
      ),
    ]),
    agent('review', 46, [
      const KAgentArtifactPart(
        id: 'draft-artifact',
        title: 'Agent-UI-Release.md',
        description: 'Vorbereiteter Entwurf · lokal ansehen',
        artifactType: 'Markdown',
        reference: 'local:agent-ui-release',
      ),
      const KChatAttachmentPart(
        id: 'draft-file',
        title: 'Release-Checkliste.pdf',
        description: 'PDF · vorbereitete Beispieldatei',
        state: KChatAttachmentPartState.complete,
      ),
      KAgentApprovalPart(
        id: 'release-approval',
        title: 'Diesen Entwurf freigeben?',
        description:
            'Die Freigabe ändert nur den lokalen Demo-Status. Es wird nichts veröffentlicht.',
        detail: 'Ziel: interne Vorschau\nArtefakt: Agent-UI-Release.md',
        state: approval == null
            ? KAgentResolutionState.pending
            : approval.optionId == 'approve'
            ? KAgentResolutionState.approved
            : KAgentResolutionState.rejected,
        options: const [
          KAgentApprovalOption(id: 'reject', label: 'Überarbeiten'),
          KAgentApprovalOption(
            id: 'approve',
            label: 'Entwurf freigeben',
            primary: true,
          ),
        ],
        selectedOptionId: approval?.optionId,
        responseSummary: approval == null
            ? null
            : approval.optionId == 'approve'
            ? 'Entwurf lokal freigegeben'
            : 'Überarbeitung angefordert',
      ),
    ]),
  ];
}
