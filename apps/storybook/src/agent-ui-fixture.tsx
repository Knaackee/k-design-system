import { useMemo, useState } from "react";
import {
  KChatComposer,
  KChatConversation,
  type KAgentApprovalResponse,
  type KAgentQuestionResponse,
  type KChatMessageValue,
  type KChatRunState,
  type KChatAttachmentPart,
  type KChatMessageMetadataMode,
} from "@k-design-system/ui";

export type AgentUiFixtureKind =
  "conversation" | "messages" | "tools" | "approval" | "question";

export function AgentUiFixture({
  kind = "conversation",
  metadataMode = "grouped",
  showTimestamps = true,
}: {
  kind?: AgentUiFixtureKind;
  metadataMode?: KChatMessageMetadataMode;
  showTimestamps?: boolean;
}) {
  const [draft, setDraft] = useState("");
  const [runState, setRunState] = useState<KChatRunState>("awaiting-input");
  const [approval, setApproval] = useState<KAgentApprovalResponse>();
  const [answer, setAnswer] = useState<KAgentQuestionResponse>();
  const [sentMessages, setSentMessages] = useState<KChatMessageValue[]>([]);
  const [attachments, setAttachments] = useState<KChatAttachmentPart[]>([]);
  const [voiceActive, setVoiceActive] = useState(false);
  const [model, setModel] = useState("fast");

  const messages = useMemo(
    () => [...fixtureMessages(kind, approval, answer), ...sentMessages],
    [answer, approval, kind, sentMessages],
  );

  const submit = (text: string) => {
    setSentMessages((current) => [
      ...current,
      {
        id: `user-${current.length}`,
        role: "user",
        authorLabel: "Du",
        timestamp: "gerade eben",
        parts: [{ id: `text-${current.length}`, type: "text", text }],
      },
    ]);
    setDraft("");
    setRunState("streaming");
  };

  return (
    <section
      className="k-agent-ui-fixture"
      aria-label="Design-System Agent demo"
    >
      <header className="k-agent-ui-fixture__header">
        <div>
          <strong>Design-System Agent</strong>
          <span>{runState === "streaming" ? "Antwortet…" : "Bereit"}</span>
        </div>
      </header>
      <KChatConversation
        messages={messages}
        runState={runState}
        onApprovalResponse={(response) => {
          setApproval(response);
          setRunState("idle");
        }}
        onQuestionResponse={(response) => {
          setAnswer(response);
          setRunState("idle");
        }}
        onSourceActivate={(source) =>
          source.url && window.open(source.url, "_blank", "noopener")
        }
        onArtifactActivate={(artifact) =>
          window.alert(`Artefakt: ${artifact.title}`)
        }
        onLinkActivate={(url) => window.open(url, "_blank", "noopener")}
        labels={{
          assistant: "Agent",
          user: "Du",
          loadOlder: "Frühere Nachrichten laden",
          sending: "Wird gesendet…",
          sent: "Gesendet",
          failed: "Nicht gesendet",
        }}
        metadataMode={metadataMode}
        metadataByRole={
          kind === "conversation"
            ? { user: "hidden", system: "hidden" }
            : undefined
        }
        showTimestamps={showTimestamps}
      />
      <KChatComposer
        value={draft}
        onValueChange={setDraft}
        onSubmit={submit}
        onStop={() => setRunState("stopped")}
        runState={runState}
        labels={{ placeholder: "Nachricht an den Agenten…" }}
        attachments={attachments}
        onAttachmentRemove={(attachment) =>
          setAttachments((current) =>
            current.filter((item) => item.id !== attachment.id),
          )
        }
        onAttach={() =>
          setAttachments((current) =>
            current.length
              ? current
              : [
                  {
                    id: "brief.pdf",
                    type: "attachment",
                    title: "Release-Brief.pdf",
                    description: "PDF · 1,8 MB",
                    state: "ready",
                  },
                ],
          )
        }
        voiceActive={voiceActive}
        onVoiceInput={() => setVoiceActive((current) => !current)}
        models={[
          { value: "fast", label: "K Fast" },
          { value: "quality", label: "K Quality" },
        ]}
        model={model}
        onModelChange={setModel}
      />
    </section>
  );
}

function fixtureMessages(
  kind: AgentUiFixtureKind,
  approval?: KAgentApprovalResponse,
  answer?: KAgentQuestionResponse,
): KChatMessageValue[] {
  const intro: KChatMessageValue[] = [
    {
      id: "request",
      role: "user",
      authorLabel: "Du",
      timestamp: "10:42",
      parts: [
        {
          id: "request-text",
          type: "text",
          text: "Prüfe die neue Chat-Komponente und bereite die Veröffentlichung vor.",
        },
      ],
    },
    {
      id: "agent",
      role: "assistant",
      authorLabel: "Agent",
      timestamp: "10:42",
      parts: [
        {
          id: "agent-text",
          type: "text",
          text: "Ich prüfe **Web und Flutter** mit denselben Zuständen. Die Komponenten bleiben transportneutral und senden nur typisierte Events an den Host.",
        },
        {
          id: "tasks",
          type: "tasks",
          title: "Veröffentlichung vorbereiten",
          items: [
            { id: "task-1", title: "Komponenten prüfen", state: "completed" },
            { id: "task-2", title: "Galerien abgleichen", state: "active" },
            { id: "task-3", title: "Release freigeben", state: "pending" },
          ],
        },
      ],
    },
  ];

  const tools: KChatMessageValue = {
    id: "tools",
    role: "assistant",
    authorLabel: "Agent",
    timestamp: "10:43",
    parts: [
      {
        id: "tool-read",
        type: "tool",
        toolName: "read_design_tokens",
        title: "Design Tokens gelesen",
        description:
          "Die Agentenoberfläche nutzt ausschließlich öffentliche semantische Tokens.",
        state: "succeeded",
        arguments: { theme: "Orbit Dark" },
        result: { tokens: 184, violations: 0 },
      },
      {
        id: "activity",
        type: "activity",
        title: "Galerien werden verglichen",
        summary:
          "Storybook und Widgetbook erhalten identische Fixture-Zustände.",
        active: true,
      },
      {
        id: "source",
        type: "source",
        title: "Agent-UI-Spezifikation",
        description: "Transportneutrale Agent-UI-Entscheidung",
        url: "https://sdk.vercel.ai/docs/ai-sdk-ui",
      },
    ],
  };

  const approvalMessage: KChatMessageValue = {
    id: "approval-message",
    role: "assistant",
    authorLabel: "Agent",
    parts: [
      {
        id: "release-approval",
        type: "approval",
        title: "Veröffentlichung freigeben?",
        description:
          "Die sichtbare Demo ist bereit. Der Host entscheidet, was die Aktion ausführt.",
        detail: "Ziel: design-system-preview\nUmfang: Chat + Agent UI",
        state: approval
          ? approval.optionId === "approve"
            ? "approved"
            : "rejected"
          : "pending",
        options: [
          { id: "reject", label: "Ablehnen", tone: "secondary" },
          { id: "approve", label: "Freigeben", tone: "primary" },
        ],
        responseSummary: approval
          ? approval.optionId === "approve"
            ? "Freigegeben"
            : "Abgelehnt"
          : undefined,
      },
    ],
  };

  const questionMessage: KChatMessageValue = {
    id: "question-message",
    role: "assistant",
    authorLabel: "Agent",
    parts: [
      {
        id: "density-question",
        type: "question",
        title: "Welche Dichte soll die Vorschau verwenden?",
        description:
          "Die Antwort wird als typisiertes Event an die Anwendung übergeben.",
        kind: "single-choice",
        state: answer ? "answered" : "pending",
        options: [
          {
            id: "dense",
            label: "Dense",
            description: "Für produktive Desktop-Oberflächen",
          },
          {
            id: "comfortable",
            label: "Comfortable",
            description: "Mehr Raum für Touch-Eingaben",
          },
        ],
        answerSummary: answer
          ? `Ausgewählt: ${answer.optionIds?.[0] ?? "–"}`
          : undefined,
        submitLabel: "Übernehmen",
      },
    ],
  };

  const messageStates: KChatMessageValue[] = [
    {
      id: "message-user-sent",
      role: "user",
      authorLabel: "Du",
      timestamp: "10:44",
      status: "sent",
      parts: [
        {
          id: "message-user-sent-text",
          type: "text",
          text: "Fasse die Unterschiede zwischen Web und Flutter zusammen.",
        },
      ],
    },
    {
      id: "message-agent-answer",
      role: "assistant",
      authorLabel: "Agent",
      timestamp: "10:44",
      parts: [
        {
          id: "message-agent-answer-text",
          type: "text",
          text: "Beide Plattformen verwenden dieselben Zustände. Metadaten können vollständig, gruppiert oder ausgeblendet dargestellt werden.",
        },
      ],
    },
    {
      id: "message-user-sending",
      role: "user",
      authorLabel: "Du",
      timestamp: "10:45",
      status: "sending",
      parts: [
        {
          id: "message-user-sending-text",
          type: "text",
          text: "Zeige auch den Versandstatus.",
        },
      ],
    },
    {
      id: "message-user-failed",
      role: "user",
      authorLabel: "Du",
      timestamp: "10:45",
      status: "failed",
      parts: [
        {
          id: "message-user-failed-text",
          type: "text",
          text: "Diese Nachricht konnte nicht gesendet werden.",
        },
      ],
    },
  ];

  if (kind === "tools") return [...intro, tools];
  if (kind === "messages") return messageStates;
  if (kind === "approval") return [...intro, approvalMessage];
  if (kind === "question") return [...intro, questionMessage];
  return [...intro, tools, approvalMessage, questionMessage];
}
