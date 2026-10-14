import { useEffect, useRef, useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KCallBar,
  KButton,
  KChatComposer,
  KChatConversation,
} from "@k-design-system/ui";
import { AgentWorkspaceAvatar } from "./agent-workspace-avatar.js";
import "./call-bar-fixture.css";
type State = "connecting" | "listening" | "speaking" | "muted" | "ending";
const statuses = {
  connecting: "Verbindung wird aufgebaut …",
  listening: "Hört zu",
  speaking: "Spricht",
  muted: "Mikrofon stumm",
  ending: "Anruf wird beendet …",
};
function CallFixture({
  state = "listening",
  composition = false,
  mobile = false,
}: {
  state?: State;
  composition?: boolean;
  mobile?: boolean;
}) {
  const [muted, setMuted] = useState(state === "muted");
  const [expanded, setExpanded] = useState(true);
  const [ended, setEnded] = useState(false);
  const [activity, setActivity] = useState<"tool" | "delegation" | undefined>();
  const [draft, setDraft] = useState("");
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  useEffect(() => () => clearTimeout(timer.current), []);
  const runActivity = (kind: "tool" | "delegation") => {
    clearTimeout(timer.current);
    setActivity(kind);
    timer.current = setTimeout(() => setExpanded(false), 900);
  };
  const bar = (
    <KCallBar
      name="Alex"
      status={
        ended
          ? "Anruf beendet"
          : activity
            ? activity === "tool"
              ? "Prüft deinen Kalender"
              : "Arbeitet mit Mira"
            : muted
              ? statuses.muted
              : statuses[state]
      }
      duration={state === "connecting" ? "00:00" : "02:14"}
      muted={muted}
      microphoneLevel={state === "listening" ? 0.7 : 0.15}
      onMutedChange={setMuted}
      muteDisabled={ended || state === "connecting" || state === "ending"}
      expanded={composition && expanded && !ended}
      avatar={
        composition ? (
          <AgentWorkspaceAvatar
            shape="squircle"
            color="#8c9cf0"
            status={state === "speaking" ? "speaking" : "idle"}
            size={240}
            label="Alex"
          />
        ) : undefined
      }
      onExpandedChange={composition ? setExpanded : undefined}
      onEndCall={
        composition && !ended
          ? () => {
              clearTimeout(timer.current);
              setEnded(true);
              setExpanded(false);
            }
          : undefined
      }
      labels={{
        region: "Anruf",
        duration: "Anrufdauer",
        mute: "Mikrofon stummschalten",
        unmute: "Mikrofon einschalten",
        minimize: "Anruf minimieren",
        expand: "Zum Anruf zurückkehren",
        end: "Auflegen",
      }}
    />
  );
  if (!composition) return bar;
  return (
    <div className="call-pattern-fixture" data-mobile={mobile}>
      <div className="call-pattern-stage" data-expanded={expanded && !ended}>
        {bar}
        <KChatConversation
          messages={[
            {
              id: "request",
              role: "user",
              parts: [
                { id: "question", type: "text", text: "Was steht heute an?" },
              ],
            },
            {
              id: "reply",
              role: "assistant",
              parts: [
                {
                  id: "answer",
                  type: "text",
                  text:
                    activity === "delegation"
                      ? "Mira prüft die Aufgaben. Du kannst währenddessen weitersprechen."
                      : "Ich schaue in deinen Kalender und sortiere die nächsten Schritte.",
                },
                ...(activity
                  ? [
                      {
                        id: "activity",
                        type: "text" as const,
                        text:
                          activity === "tool"
                            ? "Kalender · Termine werden geladen …"
                            : "Mira · Aufgaben werden geprüft …",
                      },
                    ]
                  : []),
              ],
            },
          ]}
          renderAvatar={() => null}
          showTimestamps={false}
        />
      </div>
      <div className="call-pattern-demo">
        <KButton
          variant="secondary"
          disabled={ended}
          onClick={() => runActivity("tool")}
        >
          Tool starten
        </KButton>
        <KButton
          variant="secondary"
          disabled={ended}
          onClick={() => runActivity("delegation")}
        >
          An Mira delegieren
        </KButton>
      </div>
      <KChatComposer
        value={draft}
        onValueChange={setDraft}
        onSubmit={() => setDraft("")}
        labels={{ input: "Nachricht", placeholder: "Nachricht an Alex …" }}
      />
    </div>
  );
}
const meta = {
  title: "Chat/CallBar",
  component: CallFixture,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof CallFixture>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Connecting: Story = {
  args: { state: "connecting" },
  parameters: { fixtureId: "call-bar-connecting" },
};
export const Listening: Story = {
  args: { state: "listening" },
  parameters: { fixtureId: "call-bar-listening" },
};
export const Speaking: Story = {
  args: { state: "speaking" },
  parameters: { fixtureId: "call-bar-speaking" },
};
export const Muted: Story = {
  args: { state: "muted" },
  parameters: { fixtureId: "call-bar-muted" },
};
export const Ending: Story = {
  args: { state: "ending" },
  parameters: { fixtureId: "call-bar-ending" },
};
export const ChatCall: Story = {
  args: { state: "speaking", composition: true },
  parameters: { fixtureId: "chat-call-speaking" },
};
export const ChatCallMobile: Story = {
  args: { state: "listening", composition: true, mobile: true },
  parameters: {
    fixtureId: "chat-call-mobile",
    viewport: { defaultViewport: "mobile1" },
  },
};
