import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KButton,
  KChatConversation,
  type KAgentToolState,
  type KChatMessageValue,
} from "@k-design-system/ui";

function CompactToolActivity({
  phone = false,
  question = false,
}: {
  phone?: boolean;
  question?: boolean;
}) {
  const [state, setState] = useState<KAgentToolState>("running");
  const [showQuestion, setShowQuestion] = useState(question);
  const [project, setProject] = useState<string>();
  const [approval, setApproval] = useState<"pending" | "approved" | "rejected">(
    "pending",
  );
  const messages: KChatMessageValue[] = [
    {
      id: "activity-review",
      role: "assistant",
      parts: [
        {
          id: "intro",
          type: "text",
          text: "Ich prüfe die passenden Projekte und bereite dein Issue vor.",
        },
        ...[1, 2, 3].map((index) => ({
          id: `search-${index}`,
          type: "tool" as const,
          toolName: "search_issues",
          title: "Issues durchsuchen",
          state: index === 3 ? state : ("succeeded" as const),
          arguments: { project: "Orbit", page: index },
          result:
            index === 3 && state === "running" ? undefined : { matches: 4 },
          error:
            index === 3 && state === "failed"
              ? "Die Suche konnte nicht abgeschlossen werden. Bitte erneut versuchen."
              : undefined,
        })),
        {
          id: "result",
          type: "text",
          text: "Die technischen Details kannst du bei Bedarf aufklappen.",
        },
        showQuestion
          ? {
              id: "project-question",
              type: "question",
              title: "In welchem Projekt soll das Issue entstehen?",
              description:
                "Wähle ein Projekt oder lege das Issue in deinem privaten Bereich an.",
              kind: "single-choice",
              state: project ? "answered" : "pending",
              answerSummary: project ? `Ausgewählt: ${project}` : undefined,
              submitLabel: "Auswahl übernehmen",
              options: [
                {
                  id: "Orbit",
                  label: "Orbit",
                  description: "Agent Runtime und Delegationen",
                },
                {
                  id: "Tasks",
                  label: "Tasks",
                  description: "Web- und Flutter-Anwendung",
                },
                {
                  id: "Privat",
                  label: "Privater Bereich",
                  description: "Ohne Projekt · Nur für dich",
                },
              ],
            }
          : {
              id: "approval",
              type: "approval",
              title: "Issue erstellen?",
              description: "Projekt Orbit · Morgen · Dir zugewiesen",
              state: approval,
              options: [
                { id: "approve", label: "Issue erstellen", tone: "primary" },
                { id: "reject", label: "Abbrechen" },
              ],
            },
      ],
    },
  ];
  return (
    <div
      style={{
        maxWidth: phone ? 390 : 760,
        margin: "auto",
        height: "90vh",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <div
        style={{
          display: "flex",
          flexWrap: "wrap",
          gap: "var(--k-space-control-gap)",
          padding: "var(--k-space-control-inset-inline)",
        }}
      >
        <KButton
          variant="secondary"
          onClick={() => {
            setShowQuestion(true);
            setProject(undefined);
          }}
        >
          Rückfrage
        </KButton>
        <KButton
          variant="secondary"
          onClick={() => {
            setShowQuestion(false);
            setApproval("pending");
          }}
        >
          Freigabe
        </KButton>
        <KButton variant="secondary" onClick={() => setState("running")}>
          Läuft
        </KButton>
        <KButton variant="secondary" onClick={() => setState("succeeded")}>
          Abgeschlossen
        </KButton>
        <KButton variant="secondary" onClick={() => setState("failed")}>
          Fehler
        </KButton>
      </div>
      <KChatConversation
        messages={messages}
        metadataMode="hidden"
        showTimestamps={false}
        runState={state === "running" ? "streaming" : "awaiting-input"}
        onQuestionResponse={(response) => setProject(response.optionIds?.[0])}
        labels={{ approvalNote: "Anmerkung hinzufügen (optional)" }}
        onApprovalResponse={(response) =>
          setApproval(response.optionId === "approve" ? "approved" : "rejected")
        }
      />
    </div>
  );
}

const meta = {
  title: "Patterns/AgentUI/Compact activity",
  component: CompactToolActivity,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof CompactToolActivity>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Tools: Story = {
  parameters: { fixtureId: "agent-ui-compact-tools" },
};
export const Phone: Story = {
  args: { phone: true },
  parameters: { fixtureId: "agent-ui-compact-tools-phone" },
};
export const ProjectSelection: Story = {
  args: { question: true },
  parameters: { fixtureId: "agent-ui-project-selection" },
};
