import { useState } from "react";
import {
  KButton,
  KChatComposer,
  KChatConversation,
  KInline,
  KSegmentedControl,
  KStack,
  KText,
  type KChatAttachmentPart,
  type KChatMessageValue,
  type KChatRunState,
} from "@k-design-system/ui";
import {
  completeMessages,
  demoBrief,
  initialCompleteResponses,
} from "./agent-ui-complete-data.js";

export type CompleteScenario = "empty" | "history" | "streaming";

export function AgentUiCompleteFixture({
  scenario = "history",
}: {
  scenario?: CompleteScenario;
}) {
  // A Storybook arg change starts a fresh local scenario, including child drafts.
  return <CompleteSession key={scenario} initialScenario={scenario} />;
}

function CompleteSession({
  initialScenario,
}: {
  initialScenario: CompleteScenario;
}) {
  const [scenario, setScenario] = useState(initialScenario);
  const [responses, setResponses] = useState(initialCompleteResponses);
  const [draft, setDraft] = useState("");
  const [attachments, setAttachments] = useState<KChatAttachmentPart[]>([]);
  const [sent, setSent] = useState<KChatMessageValue[]>([]);
  const [runState, setRunState] = useState<KChatRunState>(
    initialScenario === "streaming" ? "streaming" : "idle",
  );
  const [notice, setNotice] = useState("");
  const [resetKey, setResetKey] = useState(0);
  const [model, setModel] = useState("fast");
  const running = runState === "streaming";
  const reset = (next: CompleteScenario) => {
    setScenario(next);
    setResponses(initialCompleteResponses());
    setDraft("");
    setAttachments([]);
    setSent([]);
    setRunState(next === "streaming" ? "streaming" : "idle");
    setNotice("");
    setResetKey((current) => current + 1);
  };
  const messages: KChatMessageValue[] = [
    ...(scenario === "empty" ? [] : completeMessages(responses)),
    ...sent,
    ...(running || runState === "stopped" || runState === "completed"
      ? [
          {
            id: "live-answer",
            role: "assistant" as const,
            authorLabel: "Design-System Agent",
            parts: [
              {
                id: "live-activity",
                type: "activity" as const,
                title: running
                  ? "Übergabe wird formuliert"
                  : runState === "stopped"
                    ? "Antwort gestoppt"
                    : "Übergabe formuliert",
                summary:
                  "Lokale Simulation ohne Timer. Stoppen oder Abschließen verändert diesen Zustand.",
                active: running,
              },
              {
                id: "live-text",
                type: "text" as const,
                text:
                  runState === "completed"
                    ? "Die **lokale Übergabe** ist formuliert. Der Entwurf und deine Eingaben bleiben in dieser Vorschau erhalten."
                    : "Ich formuliere die **Übergabe** aus dem Entwurf und deinen Angaben…",
                streaming: running,
              },
            ],
          },
        ]
      : []),
  ];

  return (
    <section
      className="k-agent-ui-fixture"
      aria-label="Agent UI Complete – lokale Demo"
    >
      <header
        style={{
          padding: "var(--k-space-control-gap) var(--k-space-layout-gutter)",
        }}
      >
        <KStack gap="control" align="stretch">
          <KInline gap="action" wrap>
            <KText variant="label">Agent UI Complete</KText>
            <KSegmentedControl<CompleteScenario>
              label="Demo-Szenario"
              segments={[
                { value: "empty", label: "Leer" },
                { value: "history", label: "Verlauf" },
                { value: "streaming", label: "Antwort läuft" },
              ]}
              value={scenario}
              onValueChange={reset}
            />
            <KButton variant="secondary" onClick={() => reset(scenario)}>
              Zurücksetzen
            </KButton>
            {running ? (
              <KButton
                variant="secondary"
                onClick={() => setRunState("completed")}
              >
                Antwort abschließen
              </KButton>
            ) : null}
            {attachments.some((part) => part.state === "uploading") ? (
              <KButton
                variant="secondary"
                onClick={() =>
                  setAttachments((current) =>
                    current.map((part) => ({
                      ...part,
                      state: "ready",
                      progress: undefined,
                    })),
                  )
                }
              >
                Demo-Upload abschließen
              </KButton>
            ) : null}
          </KInline>
          <KText variant="caption" role="status">
            {notice ||
              (running
                ? "Simulierte Antwort läuft · mit Stopp anhalten oder manuell abschließen."
                : "Lokale Beispieldaten · keine Verbindung, Aufnahme oder Veröffentlichung.")}
          </KText>
        </KStack>
      </header>
      <KChatConversation
        key={resetKey}
        messages={messages}
        runState={runState}
        metadataMode="grouped"
        metadataByRole={{ user: "hidden", system: "hidden" }}
        labels={{
          assistant: "Agent",
          user: "Du",
          emptyTitle: "Womit möchtest du starten?",
          emptyDescription:
            "Sende eine Nachricht oder wähle den vorbereiteten Verlauf.",
          newContent: "Zur neuesten Nachricht",
          sending: "Wird gesendet…",
          sent: "Gesendet",
          failed: "Nicht gesendet",
          approvalNote: "Notiz ergänzen (optional)",
        }}
        onQuestionResponse={(response) =>
          setResponses((current) => ({
            ...current,
            questions: {
              ...current.questions,
              [response.questionId]: response,
            },
          }))
        }
        onApprovalResponse={(response) =>
          setResponses((current) => ({
            ...current,
            approvals: {
              ...current.approvals,
              [response.approvalId]: response,
            },
          }))
        }
        onFormResponse={(response) =>
          setResponses((current) => ({
            ...current,
            forms: { ...current.forms, [response.formId]: response },
          }))
        }
        onExternalAction={(response) =>
          setResponses((current) => ({
            ...current,
            external: { ...current.external, [response.actionId]: response },
          }))
        }
        onAttachmentRequest={(response) =>
          setResponses((current) => ({
            ...current,
            attachments: {
              ...current.attachments,
              [response.requestId]: response,
            },
          }))
        }
        onArtifactActivate={() =>
          setNotice(
            "Agent-UI-Release.md: Der Entwurf ist oben als Markdown im Verlauf sichtbar.",
          )
        }
        onAttachmentActivate={(part) =>
          setNotice(
            `${part.title}: Beispieldatei ohne Dateiinhalt; kein Download.`,
          )
        }
        onSourceActivate={() =>
          setNotice(
            "Lokale Quelle: Release-Brief, Abschnitt 2. Kein externes Dokument verbunden.",
          )
        }
        onLinkActivate={() =>
          setNotice(
            "Demo-Link ausgewählt. Es wird keine externe Seite geöffnet.",
          )
        }
        markdownOptions={{
          copyLabel: "Kopieren",
          tableLabel: "Tabelle",
          onCopy: (text) => {
            if (!navigator.clipboard) {
              setNotice(
                "Die Zwischenablage ist in diesem Browser nicht verfügbar.",
              );
              return;
            }
            void navigator.clipboard.writeText(text).then(
              () => setNotice("In die Zwischenablage kopiert."),
              () =>
                setNotice(
                  "Die Zwischenablage ist in diesem Browser nicht verfügbar.",
                ),
            );
          },
        }}
      />
      <KChatComposer
        value={draft}
        onValueChange={setDraft}
        runState={runState}
        labels={{
          input: "Nachricht",
          placeholder: "Nachricht an den Agenten…",
          send: "Nachricht senden",
          stop: "Antwort stoppen",
          attach: "Demo-Datei anhängen",
          removeAttachment: "Anhang entfernen",
          model: "Demo-Modell",
        }}
        attachments={attachments}
        onAttach={() =>
          setAttachments([{ ...demoBrief, state: "uploading", progress: 0.45 }])
        }
        onAttachmentActivate={(part) =>
          setNotice(`${part.title}: Lokale Beispieldatei ohne Dateiinhalt.`)
        }
        onAttachmentRemove={(part) =>
          setAttachments((current) =>
            current.filter((item) => item.id !== part.id),
          )
        }
        models={[
          { value: "fast", label: "K Fast · Demo" },
          { value: "quality", label: "K Quality · Demo" },
        ]}
        model={model}
        onModelChange={setModel}
        onStop={() => setRunState("stopped")}
        submitEnabled={!attachments.some((part) => part.state === "uploading")}
        onSubmit={(text) => {
          setSent((current) => [
            ...current,
            {
              id: `local-${current.length}`,
              role: "user",
              authorLabel: "Du",
              status: "sent",
              parts: [
                { id: `local-text-${current.length}`, type: "text", text },
                ...attachments,
              ],
            },
          ]);
          setDraft("");
          setAttachments([]);
          setRunState("streaming");
          setNotice("");
        }}
      />
    </section>
  );
}
