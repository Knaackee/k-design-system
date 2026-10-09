import { AgentWorkspaceAvatar } from "./agent-workspace-avatar.js";
import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KFab,
  KIcon,
  KButton,
  KInline,
  type KFabAttention,
} from "@k-design-system/ui";

const meta = {
  title: "Patterns/ChatBubble",
  component: KFab,
  args: {
    label: "Hauptaktion",
    activation: "longPress",
    items: [],
    size: 64,
    itemGap: 8,
    visible: true,
    attentionPeekFraction: 0.5,
    attentionHoldMs: 324,
    children: <KIcon name="message-circle" size={28} />,
  },
  argTypes: {
    itemGap: { control: { type: "range", min: 0, max: 32, step: 2 } },
    attentionPeekFraction: {
      control: { type: "range", min: 0, max: 1, step: 0.05 },
    },
    attentionHoldMs: { control: { type: "number", min: 0, step: 100 } },
  },
  parameters: { layout: "fullscreen", fixtureId: "chat-bubble-basic" },
} satisfies Meta<typeof KFab>;
export default meta;
type Story = StoryObj<typeof meta>;

export const Basic: Story = {
  render: function Demo(args) {
    const [count, setCount] = useState(0);
    const [attention, setAttention] = useState<KFabAttention[]>([]);
    const [sequence, setSequence] = useState(0);
    const signal = (itemId: string) => {
      setSequence((value) => value + 1);
      setAttention((value) => [
        ...value.filter((notice) => notice.itemId !== itemId),
        { id: `${itemId}-${sequence}`, itemId },
      ]);
    };
    return (
      <div
        style={{ padding: 24, minHeight: "100dvh", boxSizing: "border-box" }}
      >
        <KInline wrap>
          <KButton variant="secondary" onClick={() => signal("one")}>
            Stern anstupsen
          </KButton>
          <KButton variant="secondary" onClick={() => signal("two")}>
            Herz anstupsen
          </KButton>
          <KButton variant="ghost" onClick={() => setAttention([])}>
            Alle bestätigen
          </KButton>
        </KInline>
        <p>
          {attention.length} offene Hinweise · Anklicken einer auftauchenden
          Bubble bestätigt sie in dieser Demo.
        </p>
        <p role="status">
          {count
            ? `Aktion ausgelöst: ${count}`
            : args.activation === "press"
              ? "Kurz drücken: weitere Bubbles."
              : "Kurz drücken: Hauptaktion. Lange drücken: weitere Bubbles."}
        </p>
        <div style={{ position: "fixed", right: 24, bottom: 24 }}>
          <KFab
            {...args}
            attention={attention}
            onAttentionSelect={(notice) =>
              setAttention((value) =>
                value.filter((entry) => entry.id !== notice.id),
              )
            }
            onPress={() => setCount(count + 1)}
            items={[
              {
                id: "one",
                label: "Bubble 1",
                content: <KIcon name="star" size={28} />,
                onSelect: () => setCount(1),
              },
              {
                id: "two",
                label: "Bubble 2",
                content: <KIcon name="heart" size={28} />,
                onSelect: () => setCount(2),
              },
              {
                id: "three",
                label: "Bubble 3",
                content: <KIcon name="sparkles" size={28} />,
                onSelect: () => setCount(3),
              },
            ]}
          />
        </div>
      </div>
    );
  },
};

export const CustomContent: Story = {
  ...Basic,
  parameters: { fixtureId: "chat-bubble-custom-content" },
  args: {
    children: (
      <span style={{ fontSize: 28 }} aria-hidden="true">
        ✦
      </span>
    ),
  },
};

export const Standard: Story = { ...Basic, args: { activation: "press" } };

/** Real asynchronous canvas content, loaded before the first menu opening. */
export const PreloadedCharacters: Story = {
  render: function Demo(args) {
    const [gap, setGap] = useState(args.itemGap ?? 8);
    const [selected, setSelected] = useState("Noch keine Aktion");
    return (
      <div
        style={{ padding: 24, minHeight: "100dvh", boxSizing: "border-box" }}
      >
        <label>
          Bubble-Abstand: {gap} px{" "}
          <input
            aria-label="Bubble-Abstand"
            type="range"
            min={0}
            max={32}
            step={2}
            value={gap}
            onChange={(event) => setGap(Number(event.target.value))}
          />
        </label>
        <p>
          Rechtsklick oder langes Drücken öffnet und schließt das Menü. Die
          Charaktere werden bereits beim Laden dieser Seite vorbereitet und
          bleiben erhalten.
        </p>
        <p role="status">{selected}</p>
        <div style={{ position: "fixed", right: 24, bottom: 24 }}>
          <KFab
            {...args}
            itemGap={gap}
            onPress={() => setSelected("Hauptaktion")}
            items={["circle", "squircle", "star"].map((shape, index) => ({
              id: shape,
              label: `Charakter ${index + 1}`,
              content: (
                <span style={{ display: "block", width: 48, height: 48 }}>
                  <AgentWorkspaceAvatar
                    shape={shape}
                    color={["#74b9b1", "#b28ade", "#e4b75d"][index]}
                    size={64}
                  />
                </span>
              ),
              onSelect: () => setSelected(`Charakter ${index + 1}`),
            }))}
          />
        </div>
      </div>
    );
  },
};
