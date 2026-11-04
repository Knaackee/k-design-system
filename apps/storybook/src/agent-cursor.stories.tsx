import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { KAgentCursor, KAvatar, KButton } from "@k-design-system/ui";

interface AgentCursorFixtureProps {
  variant?: string;
  glowEnabled?: boolean;
  glowIntensity?: number;
  glowColor?: string;
  showAvatar?: boolean;
  avatarText?: string;
  label?: string;
}
function AgentCursorFixture({
  variant = "Default",
  glowEnabled = true,
  glowIntensity = 1,
  glowColor,
  showAvatar = false,
  avatarText = "A",
  label = "",
}: AgentCursorFixtureProps) {
  const [saved, setSaved] = useState(false);
  const dark = variant === "DarkSurface";
  return (
    <div style={{ padding: 40 }}>
      <div
        data-theme={dark ? "dark" : undefined}
        data-brand={dark ? "orbit" : undefined}
        style={{
          position: "relative",
          width: 480,
          maxWidth: "100%",
          minHeight: 260,
          border: "1px solid var(--k-color-border-default)",
          borderRadius: "var(--k-radius-overlay)",
          background: "var(--k-color-surface-raised)",
          color: "var(--k-color-text-primary)",
        }}
      >
        <div
          style={{
            borderBottom: "1px solid var(--k-color-border-default)",
            padding: "12px 20px",
            color: "var(--k-color-text-muted)",
            fontSize: 13,
          }}
        >
          ◌ &nbsp; Workspace / Notes
        </div>
        <div style={{ padding: 28 }}>
          <h3 style={{ margin: "0 0 12px" }}>Research notes</h3>
          <p style={{ color: "var(--k-color-text-muted)", margin: "0 0 24px" }}>
            A small change, ready to save.
          </p>
          <KButton onClick={() => setSaved(!saved)}>
            {saved ? "Saved" : "Save notes"}
          </KButton>
        </div>
        <div style={{ position: "absolute", left: 112, top: 172 }}>
          <KAgentCursor
            visible={variant !== "Hidden"}
            state={variant === "Clicking" ? "clicking" : "pointing"}
            glowEnabled={glowEnabled}
            glowIntensity={glowIntensity}
            glowColor={glowColor}
            avatar={
              showAvatar ? (
                <KAvatar
                  alt={label || "Agent"}
                  fallback={avatarText}
                  size="small"
                />
              ) : undefined
            }
            label={label}
          />
        </div>
      </div>
      <p style={{ color: "var(--k-color-text-muted)", fontSize: 13 }}>
        The arrow tip marks the supplied position. The button remains
        interactive.
      </p>
    </div>
  );
}
const meta = {
  title: "Components/AgentCursor",
  component: AgentCursorFixture,
  args: {
    glowEnabled: true,
    glowIntensity: 1,
    showAvatar: false,
    avatarText: "A",
    label: "",
  },
  argTypes: {
    variant: { control: false },
    glowEnabled: { control: "boolean" },
    glowIntensity: { control: { type: "range", min: 0, max: 1, step: 0.05 } },
    glowColor: { control: "color" },
    showAvatar: { control: "boolean" },
    avatarText: { control: "text" },
    label: { control: "text" },
  },
} satisfies Meta<typeof AgentCursorFixture>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Default: Story = {
  args: { variant: "Default" },
  parameters: { fixtureId: "Default" },
};
export const WithAvatar: Story = {
  args: { variant: "WithAvatar", showAvatar: true, label: "Agent" },
  parameters: { fixtureId: "WithAvatar" },
};
export const Clicking: Story = {
  args: { variant: "Clicking" },
  parameters: { fixtureId: "Clicking" },
};
export const DarkSurface: Story = {
  args: { variant: "DarkSurface" },
  parameters: { fixtureId: "DarkSurface" },
};
export const ReducedMotion: Story = {
  args: { variant: "ReducedMotion" },
  parameters: { fixtureId: "ReducedMotion" },
};
export const Hidden: Story = {
  args: { variant: "Hidden" },
  parameters: { fixtureId: "Hidden" },
};
