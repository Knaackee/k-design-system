import type {
  KAgentApprovalResponse,
  KAgentAttachmentRequestResponse,
  KAgentExternalActionResponse,
  KAgentFormResponse,
  KAgentQuestionResponse,
  KChatAttachmentPart,
  KChatMessageValue,
} from "@k-design-system/ui";

export const demoBrief: KChatAttachmentPart = {
  id: "release-brief",
  type: "attachment",
  title: "Release-Brief.pdf",
  description: "PDF · lokale Beispieldatei",
  state: "ready",
};

export interface CompleteResponses {
  questions: Record<string, KAgentQuestionResponse>;
  approvals: Record<string, KAgentApprovalResponse>;
  forms: Record<string, KAgentFormResponse>;
  external: Record<string, KAgentExternalActionResponse>;
  attachments: Record<string, KAgentAttachmentRequestResponse>;
}

export function initialCompleteResponses(): CompleteResponses {
  return {
    questions: { audience: { questionId: "audience", optionIds: ["team"] } },
    approvals: {},
    forms: {},
    external: {},
    attachments: {},
  };
}

const summary = `Ich habe den Brief ausgewertet und einen **lokalen Entwurf** vorbereitet.

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

\`\`\`json
{
  "release": "Agent UI",
  "channel": "preview",
  "publish": false
}
\`\`\`

Alle Angaben sind Beispieldaten; es wird nichts veröffentlicht.`;

export function completeMessages(
  state: CompleteResponses,
): KChatMessageValue[] {
  const checks = state.questions.checks;
  const note = state.questions.note;
  const confirmation = state.questions.confirmation;
  const form = state.forms["release-config"];
  const approval = state.approvals["release-approval"];
  const external = state.external["review-space"];
  const attachment = state.attachments["screenshot-request"];
  return [
    {
      id: "request",
      role: "user",
      authorLabel: "Du",
      timestamp: "10:42",
      status: "sent",
      parts: [
        {
          id: "request-text",
          type: "text",
          text: "Bereite aus diesem Brief eine Vorschau für das Agent-UI-Release vor. Zeige mir den Entwurf, bevor etwas veröffentlicht wird.",
        },
        demoBrief,
      ],
    },
    {
      id: "analysis",
      role: "assistant",
      authorLabel: "Design-System Agent",
      timestamp: "10:42",
      parts: [
        {
          id: "analysis-activity",
          type: "activity",
          title: "Brief und Komponenten geprüft",
          summary:
            "Den Brief gelesen, die öffentlichen Web-Komponenten zugeordnet und einen Vorschau-Entwurf erstellt.",
          active: false,
        },
        {
          id: "read-brief",
          type: "tool",
          toolName: "read_file",
          title: "Dateien gelesen",
          state: "succeeded",
          arguments: { path: "Release-Brief.pdf" },
          result: { sections: 4, release: "Agent UI" },
        },
        {
          id: "read-catalog",
          type: "tool",
          toolName: "read_file",
          title: "Dateien gelesen",
          state: "succeeded",
          arguments: { path: "component-catalog.md" },
          result: {
            components: ["KChatConversation", "KAgentQuestion", "KAgentForm"],
          },
        },
        {
          id: "audience",
          type: "question",
          title: "Für wen ist die Vorschau?",
          kind: "single-choice",
          state: "answered",
          options: [
            { id: "team", label: "Internes Team" },
            { id: "public", label: "Öffentlich" },
          ],
          selectedOptionIds: state.questions.audience.optionIds,
          answerSummary: "Internes Team",
        },
      ],
    },
    {
      id: "draft",
      role: "assistant",
      authorLabel: "Design-System Agent",
      timestamp: "10:43",
      parts: [
        { id: "summary", type: "text", text: summary },
        {
          id: "plan",
          type: "tasks",
          title: "Release vorbereiten",
          items: [
            { id: "read", title: "Brief auswerten", state: "completed" },
            {
              id: "configure",
              title: "Prüfumfang und Angaben bestätigen",
              state: form?.action === "submit" ? "completed" : "active",
            },
            {
              id: "approve",
              title: "Entwurf freigeben",
              state: approval?.optionId === "approve" ? "completed" : "pending",
            },
          ],
        },
        {
          id: "source",
          type: "source",
          title: "Release-Brief · Abschnitt 2",
          description: "Lokale Quelle für den Vorschau-Entwurf",
        },
      ],
    },
    {
      id: "questions",
      role: "assistant",
      authorLabel: "Design-System Agent",
      timestamp: "10:44",
      parts: [
        {
          id: "checks",
          type: "question",
          statusLabel: "Wartet auf deine Eingabe",
          title: "Welche Prüfungen gehören in die Übergabe?",
          description:
            "Die Auswahl bleibt in dieser Demo und startet keine Prüfprogramme.",
          kind: "multiple-choice",
          state: checks ? "answered" : "pending",
          options: [
            { id: "web", label: "Web", description: "Storybook und Typecheck" },
            {
              id: "flutter",
              label: "Flutter",
              description: "Für den späteren Galerie-Abgleich",
            },
            { id: "a11y", label: "Barrierefreiheit" },
          ],
          selectedOptionIds: checks?.optionIds,
          answerSummary: checks?.optionIds?.join(", "),
          submitLabel: "Prüfumfang übernehmen",
        },
        {
          id: "note",
          type: "question",
          statusLabel: "Wartet auf deine Eingabe",
          title: "Was soll in den Release-Hinweis?",
          kind: "text",
          state: note ? "answered" : "pending",
          placeholder: "Kurze Beschreibung für das Team…",
          answerSummary: note?.text,
          submitLabel: "Hinweis übernehmen",
        },
        {
          id: "confirmation",
          type: "question",
          statusLabel: "Bitte bestätigen",
          title: "Den Entwurf als Vorschau kennzeichnen?",
          kind: "confirmation",
          state: confirmation ? "answered" : "pending",
          options: [
            { id: "yes", label: "Als Vorschau" },
            { id: "no", label: "Als Arbeitsstand" },
          ],
          selectedOptionIds: confirmation?.optionIds,
          answerSummary:
            confirmation?.optionIds?.[0] === "yes"
              ? "Als Vorschau"
              : confirmation
                ? "Als Arbeitsstand"
                : undefined,
          submitLabel: "Kennzeichnung übernehmen",
        },
      ],
    },
    {
      id: "configuration",
      role: "assistant",
      authorLabel: "Design-System Agent",
      timestamp: "10:45",
      parts: [
        {
          id: "release-config",
          type: "form",
          title: "Vorschau konfigurieren",
          description:
            "Pflichtfelder müssen ausgefüllt sein. Alle Werte bleiben lokal.",
          state: form
            ? form.action === "submit"
              ? "answered"
              : "cancelled"
            : "pending",
          fields: [
            {
              id: "name",
              kind: "text",
              label: "Release-Name",
              required: true,
              placeholder: "Agent UI Vorschau",
            },
            {
              id: "channel",
              kind: "single-choice",
              label: "Kanal",
              required: true,
              defaultValue: "preview",
              options: [
                { id: "preview", label: "Vorschau" },
                { id: "internal", label: "Interner Arbeitsstand" },
              ],
            },
            {
              id: "reviewers",
              kind: "number",
              label: "Anzahl Reviewer",
              minimum: 1,
              maximum: 5,
              defaultValue: 2,
            },
            {
              id: "include-checklist",
              kind: "boolean",
              label: "Checkliste beilegen",
              defaultValue: true,
            },
          ],
          submitLabel: "Angaben übernehmen",
          cancelLabel: "Überspringen",
          responseSummary:
            form?.action === "submit"
              ? `${String(form.values.name)} · ${String(form.values.channel)} · ${String(form.values.reviewers)} Reviewer`
              : form
                ? "Konfiguration übersprungen"
                : undefined,
        },
        {
          id: "review-space",
          type: "external-action",
          title: "Review-Raum vorbereiten",
          description:
            "Lokale Simulation: Es wird kein Browserfenster geöffnet und keine Verbindung aufgebaut.",
          url: "https://example.invalid/review",
          actionLabel: "Verbindung simulieren",
          cancelLabel: "Überspringen",
          state: external
            ? external.action === "open"
              ? "answered"
              : "cancelled"
            : "pending",
          responseSummary:
            external?.action === "open"
              ? "Verbindung lokal simuliert"
              : external
                ? "Übersprungen"
                : undefined,
        },
        {
          id: "screenshot-request",
          type: "attachment-request",
          title: "Vorschau-Bild ergänzen",
          description:
            "Fügt ein lokales Demo-Bild hinzu; es öffnet sich keine Dateiauswahl.",
          actionLabel: "Demo-Bild hinzufügen",
          accept: "image/*",
          multiple: false,
          maxFiles: 1,
          state: attachment ? "answered" : "pending",
          attachments: attachment
            ? [
                {
                  id: "preview-image",
                  type: "attachment",
                  title: "Agent-UI-Vorschau.png",
                  description: "PNG · Beispieldatei",
                  state: "complete",
                },
              ]
            : [],
          responseSummary: attachment ? "Demo-Bild hinzugefügt" : undefined,
        },
      ],
    },
    {
      id: "review",
      role: "assistant",
      authorLabel: "Design-System Agent",
      timestamp: "10:46",
      parts: [
        {
          id: "draft-artifact",
          type: "artifact",
          title: "Agent-UI-Release.md",
          description: "Vorbereiteter Entwurf · lokal ansehen",
          artifactType: "Markdown",
          reference: "local:agent-ui-release",
        },
        {
          id: "draft-file",
          type: "attachment",
          title: "Release-Checkliste.pdf",
          description: "PDF · vorbereitete Beispieldatei",
          state: "complete",
        },
        {
          id: "release-approval",
          type: "approval",
          title: "Diesen Entwurf freigeben?",
          description:
            "Die Freigabe ändert nur den lokalen Demo-Status. Es wird nichts veröffentlicht.",
          detail: "Ziel: interne Vorschau\nArtefakt: Agent-UI-Release.md",
          state: approval
            ? approval.optionId === "approve"
              ? "approved"
              : "rejected"
            : "pending",
          options: [
            { id: "reject", label: "Überarbeiten", tone: "secondary" },
            { id: "approve", label: "Entwurf freigeben", tone: "primary" },
          ],
          selectedOptionId: approval?.optionId,
          responseSummary:
            approval?.optionId === "approve"
              ? "Entwurf lokal freigegeben"
              : approval
                ? "Überarbeitung angefordert"
                : undefined,
        },
      ],
    },
  ];
}
