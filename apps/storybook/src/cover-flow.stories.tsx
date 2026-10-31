import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KCoverFlow,
  KText,
  KButton,
  type KCoverFlowProps,
} from "@k-design-system/ui";
import { useState } from "react";

const characters = [
  { id: "comet", label: "Komet" },
  { id: "sun", label: "Sonne" },
  { id: "saturn", label: "Saturn" },
].map((item) => ({
  ...item,
  content: (
    <img
      src={`/cover-flow/orbit-${item.id}.svg`}
      alt=""
      draggable={false}
      style={{ width: "100%", height: "100%" }}
    />
  ),
}));

function Fixture(props: KCoverFlowProps) {
  const [replay, setReplay] = useState(0);
  const [selected, setSelected] = useState(props.initialIndex ?? 1);
  return (
    <div
      style={{
        width: "min(100%, 1200px)",
        margin: "auto",
        paddingBlock: "var(--k-space-control-gap)",
      }}
    >
      <div style={{ textAlign: "center" }}>
        <KText variant="heading2">Wähle deinen ersten Agenten</KText>
      </div>
      {props.reveal && (
        <KButton onClick={() => setReplay((value) => value + 1)}>
          Replay
        </KButton>
      )}
      <KCoverFlow
        {...props}
        revealKey={replay}
        selectedIndex={selected}
        onIndexChange={setSelected}
      />
    </div>
  );
}

const meta = {
  title: "Data display/CoverFlow",
  component: KCoverFlow,
  render: (props) => <Fixture {...props} />,
  parameters: { layout: "fullscreen" },
  args: {
    items: characters,
    label: "Charakter auswählen",
    initialIndex: 1,
    previousLabel: "Vorheriger Charakter",
    nextLabel: "Nächster Charakter",
    itemWidth: 500,
    itemWidthFraction: 0.66,
    height: "60dvh",
    contentPadding: 16,
    clipSides: true,
    sideAngle: 55,
    depth: 120,
    spacing: 28,
    perspective: 1100,
    showCaption: true,
    showControls: true,
    reducedMotion: false,
  },
  argTypes: {
    reveal: { control: "boolean" },
    revealDurationMs: {
      control: { type: "range", min: 0, max: 2000, step: 50 },
    },
    revealStaggerMs: { control: { type: "range", min: 0, max: 400, step: 10 } },
    revealDistance: { control: { type: "range", min: 0, max: 100, step: 1 } },
    revealScale: { control: { type: "range", min: 0.5, max: 1, step: 0.01 } },
    items: { control: false },
    contentPadding: { control: { type: "range", min: 0, max: 80, step: 1 } },
    clipSides: { control: "boolean" },
    itemWidth: { control: { type: "range", min: 160, max: 700, step: 10 } },
    itemWidthFraction: {
      control: { type: "range", min: 0.1, max: 1, step: 0.01 },
    },
    sideAngle: { control: { type: "range", min: 0, max: 80, step: 1 } },
    sideOffset: { control: { type: "range", min: 40, max: 150, step: 1 } },
    sideScale: { control: { type: "range", min: 0.3, max: 1, step: 0.01 } },
    depth: { control: { type: "range", min: 0, max: 300, step: 10 } },
    spacing: { control: { type: "range", min: 10, max: 70, step: 1 } },
    perspective: { control: { type: "range", min: 600, max: 2000, step: 50 } },
  },
} satisfies Meta<typeof KCoverFlow>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Characters: Story = {
  name: "cover-flow-characters",
  args: { sideAngle: 0, sideOffset: 100, sideScale: 0.72, depth: 180 },
  parameters: { fixtureId: "cover-flow-characters" },
};
export const Covers: Story = {
  name: "cover-flow-covers",
  parameters: { fixtureId: "cover-flow-covers" },
  args: {
    initialIndex: 5,
    itemWidth: 340,
    items: Array.from({ length: 12 }, (_, index) => ({
      id: `cover-${index}`,
      label: `Cover ${index + 1}`,
      content: (
        <div
          style={{
            width: "100%",
            aspectRatio: "1",
            display: "grid",
            placeItems: "center",
            borderRadius: "var(--k-radius-card)",
            border:
              "var(--k-border-width-default) solid var(--k-color-border-default)",
            background:
              index % 2
                ? "var(--k-color-surface-raised)"
                : "var(--k-color-action-primary-background)",
            color:
              index % 2
                ? "var(--k-color-text-primary)"
                : "var(--k-color-action-primary-foreground)",
          }}
        >
          <KText variant="heading1">{String(index + 1).padStart(2, "0")}</KText>
        </div>
      ),
    })),
  },
};
export const ReducedMotion: Story = {
  args: { reducedMotion: true },
  parameters: { fixtureId: "cover-flow-reduced-motion" },
};

export const Reveal: Story = {
  name: "cover-flow-reveal",
  args: {
    reveal: true,
    revealDurationMs: 1100,
    revealStaggerMs: 200,
    revealDistance: 36,
    revealScale: 0.94,
  },
  parameters: { fixtureId: "cover-flow-reveal" },
};
