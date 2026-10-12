import type { CSSProperties } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KActivityDot,
  type KActivityDotProps,
  type KActivityDotState,
} from "@k-design-system/ui";

const states: readonly KActivityDotState[] = [
  "idle",
  "working",
  "question",
  "error",
];

const examples: ReadonlyArray<{ name: string; state: KActivityDotState }> = [
  { name: "Alex", state: "idle" },
  { name: "Sam", state: "working" },
  { name: "Robin", state: "question" },
  { name: "Taylor", state: "error" },
];

function AllStatesFixture(props: Omit<KActivityDotProps, "state">) {
  return (
    <div
      style={{
        display: "grid",
        gap: "var(--k-space-control-gap)",
        width: "min(280px, 100%)",
      }}
    >
      {examples.map(({ name, state }) => (
        <div
          key={name}
          style={{
            display: "flex",
            alignItems: "center",
            gap: "var(--k-space-control-gap)",
            minHeight: "var(--k-size-control)",
            paddingInline: "var(--k-space-control-inset-inline)",
          }}
        >
          <KActivityDot {...props} state={state} label={`${state} activity`} />
          <span style={{ fontSize: "var(--k-font-body-size)" }}>{name}</span>
        </div>
      ))}
    </div>
  );
}

const meta = {
  title: "Feedback/Activity dot",
  component: KActivityDot,
  args: {
    state: "working",
    size: "16px",
    coreSize: "8px",
    ringWidth: "2px",
    animation: "auto",
    animationDuration: "1000ms",
    animationTimingFunction: "linear",
    animationIterationCount: "infinite",
    reducedMotion: false,
    label: "Working activity",
  },
  argTypes: {
    state: { control: "select", options: states },
    animation: {
      control: "select",
      options: ["auto", "none", "spin", "pulse"],
    },
    dotColor: { control: "color" },
    ringColor: { control: "color" },
    ringTrackColor: { control: "color" },
    animationIterationCount: {
      control: "select",
      options: [1, 2, 3, "infinite"],
    },
  },
} satisfies Meta<typeof KActivityDot>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Playground: Story = {
  parameters: { fixtureId: "activity-dot-playground" },
};

export const AllStates: Story = {
  name: "activity-dot-states",
  parameters: { fixtureId: "activity-dot-states" },
  args: { dotColor: "#8b5cf6" },
  render: (args) => <AllStatesFixture {...args} />,
};

export const ConsumerTheme: Story = {
  name: "activity-dot-consumer-theme",
  parameters: { fixtureId: "activity-dot-consumer-theme" },
  args: {
    state: "question",
    dotColor: "#8b5cf6",
    ringColor: "#22d3ee",
    ringTrackColor: "#cbd5e1",
    animation: "pulse",
    animationDuration: "1600ms",
    animationTimingFunction: "cubic-bezier(0.22, 1, 0.36, 1)",
  },
  render: (args) => (
    <div
      style={
        {
          display: "grid",
          placeItems: "center",
          minWidth: "180px",
          minHeight: "120px",
          borderRadius: "var(--k-radius-card)",
          background: "var(--k-color-surface-raised)",
        } satisfies CSSProperties
      }
    >
      <KActivityDot {...args} />
    </div>
  ),
};

export const ReducedMotion: Story = {
  name: "activity-dot-reduced-motion",
  parameters: { fixtureId: "activity-dot-reduced-motion" },
  args: { state: "working", reducedMotion: true },
};
