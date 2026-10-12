import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { KAgentSingleChoice } from "@k-design-system/ui";
import "./browser-permissions.css";

function BrowserPermissionAsk({
  onceOnly = false,
  manual = false,
  submitted = false,
}: {
  onceOnly?: boolean;
  manual?: boolean;
  submitted?: boolean;
}) {
  const [answer, setAnswer] = useState(submitted ? "Einmal erlauben" : "");
  const [notice, setNotice] = useState("");
  const options = manual
    ? [
        {
          id: "takeover",
          label: "Browser übernehmen",
          description: "Pausiert den Agenten. Du führst die Aktion selbst aus.",
        },
        { id: "block", label: "Blockieren" },
      ]
    : [
        {
          id: "allow-once",
          label: "Einmal erlauben",
          description: "Führt nur diese angefragte Aktion aus.",
        },
        ...(!onceOnly
          ? [
              {
                id: "allow",
                label: "Erlauben und merken",
                description:
                  "Speichert die Freigabe für diese Adresse und Aktion.",
              },
            ]
          : []),
        {
          id: "ask",
          label: "Immer fragen",
          description:
            "Speichert die Rückfrage. Diese Aktion wartet weiterhin auf deine Entscheidung.",
        },
        {
          id: "block",
          label: "Blockieren",
          description: "Speichert die Sperre für diese Adresse und Aktion.",
        },
        {
          id: "takeover",
          label: "Browser übernehmen",
          description: "Pausiert den Agenten. Du führst die Aktion selbst aus.",
        },
      ];
  return (
    <main className="browser-permissions-demo">
      <KAgentSingleChoice
        part={{
          id: "browser-permission",
          type: "question",
          kind: "single-choice",
          state: answer ? "answered" : "pending",
          title: manual
            ? "Bestellung selbst abschließen"
            : "Hotelsuche erlauben?",
          description: manual
            ? "shop.example · /checkout · Käufe, Zahlungen und Nachrichten schließt du selbst ab. Dein Agent wartet."
            : "stay.example · /hotels/search · Nur diese Aktion auf diesem Pfad für Nova.",
          options,
          answerSummary: answer || undefined,
          submitLabel: "Entscheidung senden",
        }}
        onResponse={(response) => {
          if (response.optionIds?.[0] === "ask") {
            setNotice("Diese Aktion wartet weiterhin auf deine Entscheidung.");
            return;
          }
          setNotice("");
          setAnswer(
            options.find((option) => option.id === response.optionIds?.[0])
              ?.label ?? "",
          );
        }}
      />
      {notice ? (
        <p role="status" className="browser-permissions-demo__status">
          {notice}
        </p>
      ) : null}
    </main>
  );
}

const meta = {
  title: "Patterns/AgentUI/BrowserPermissionAsk",
  component: BrowserPermissionAsk,
  parameters: { layout: "centered" },
} satisfies Meta<typeof BrowserPermissionAsk>;
export default meta;
type Story = StoryObj<typeof meta>;

export const Request: Story = {
  parameters: { fixtureId: "browser-permission" },
};
export const OnceOnly: Story = {
  args: { onceOnly: true },
  parameters: { fixtureId: "browser-permission-once-only" },
};
export const Manual: Story = {
  args: { manual: true },
  parameters: { fixtureId: "browser-permission-manual" },
};
export const Submitted: Story = {
  args: { submitted: true },
  parameters: { fixtureId: "browser-permission-submitted" },
};
