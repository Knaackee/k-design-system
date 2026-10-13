import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KCallBar,
  KAgentChatWorkspace,
  KIcon,
  KIconButton,
  KChatComposer,
  KChatConversation,
} from "@k-design-system/ui";
import "./call-bar-fixture.css";

type State = "connecting" | "listening" | "speaking" | "muted" | "ending";
const status = {
  connecting: "Verbindung wird aufgebaut …",
  listening: "Hört zu",
  speaking: "Spricht",
  muted: "Mikrofon stumm",
  ending: "Anruf wird beendet …",
};
function CallFixture({
  state = "listening",
  composition = false,
}: {
  state?: State;
  composition?: boolean;
}) {
  const [muted, setMuted] = useState(state === "muted"),
    [draft, setDraft] = useState("");
  const bar = (
    <KCallBar
      name="Alex"
      status={muted ? status.muted : status[state]}
      duration={state === "connecting" ? "00:00" : "02:14"}
      muted={muted}
      microphoneLevel={state === "listening" ? 0.7 : 0.15}
      onMutedChange={setMuted}
      muteDisabled={state === "connecting" || state === "ending"}
      labels={{
        region: "Anruf",
        duration: "Anrufdauer",
        mute: "Mikrofon stummschalten",
        unmute: "Mikrofon einschalten",
      }}
    />
  );
  if (!composition) return bar;
  return (
    <div className="call-pattern-fixture">
      <KAgentChatWorkspace
        title="Alex"
        avatar={
          <span
            className="call-pattern-avatar"
            data-speaking={state === "speaking"}
          >
            <KIcon name="bot" size={96} />
          </span>
        }
        avatarLabel="Alex"
        sidebar={<p>Persönliche Agenten</p>}
        defaultSidebarCollapsed
        actions={
          <KIconButton icon="phone-off" label="Auflegen" onClick={() => {}} />
        }
        composer={
          <KChatComposer
            value={draft}
            onValueChange={setDraft}
            onSubmit={() => {}}
            labels={{ input: "Nachricht", placeholder: "Nachricht …" }}
          />
        }
      >
        <div className="call-pattern-stage">
          {bar}
          <KChatConversation
            messages={Array.from({ length: 12 }, (_, i) => ({
              id: String(i),
              role: i % 2 ? ("assistant" as const) : ("user" as const),
              parts: [
                {
                  id: `text-${i}`,
                  type: "text" as const,
                  text:
                    i % 2
                      ? "Ich schaue mir die Aufgabe an."
                      : "Was steht heute an?",
                },
              ],
            }))}
            renderAvatar={() => null}
            showTimestamps={false}
          />
        </div>
      </KAgentChatWorkspace>
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
  args: { state: "listening", composition: true },
  parameters: {
    fixtureId: "chat-call-mobile",
    viewport: { defaultViewport: "mobile1" },
  },
};
