import type { Meta } from "@storybook/react-vite";
import { useState } from "react";
import {
  KAlert,
  KAvatarPicker,
  KButton,
  KDisclosure,
  KIcon,
  KInput,
  KList,
  KSaveBar,
  KSegmentedControl,
  KSelect,
  KSettingsDialog,
  KSettingsDialogPanel,
  KSettingsRow,
  KStack,
  KSwitch,
  KText,
  KTextarea,
  type KIconName,
  type KSettingsDialogSection,
} from "@k-design-system/ui";

// Decision 0017: KSettingsDialog, KSaveBar, KAvatarPicker.
// Widgetbook twins: lib/settings_dialog_fixtures.dart (same fixture ids).

export default {
  title: "Patterns/Settings dialog",
  parameters: { layout: "padded" },
} satisfies Meta;

const avatarShapes: { id: string; label: string; icon: KIconName }[] = [
  { id: "circle", label: "Circle", icon: "circle" },
  { id: "squircle", label: "Squircle", icon: "squircle" },
  { id: "triangle", label: "Triangle", icon: "triangle" },
  { id: "star", label: "Star", icon: "star" },
  { id: "drop", label: "Drop", icon: "droplet" },
  { id: "cloud", label: "Cloud", icon: "cloud" },
  { id: "hexagon", label: "Hexagon", icon: "hexagon" },
  { id: "ghost", label: "Ghost", icon: "ghost" },
  { id: "heart", label: "Heart", icon: "heart" },
  { id: "egg", label: "Egg", icon: "egg" },
  { id: "diamond", label: "Diamond", icon: "diamond" },
  { id: "flower", label: "Flower", icon: "flower" },
];

const avatarColors = [
  { value: "#f43f5e", label: "Rose" },
  { value: "#f97316", label: "Orange" },
  { value: "#eab308", label: "Yellow" },
  { value: "#22c55e", label: "Green" },
  { value: "#14b8a6", label: "Teal" },
  { value: "#22d3ee", label: "Cyan" },
  { value: "#3b82f6", label: "Blue" },
  { value: "#8b5cf6", label: "Violet" },
];

const initial = {
  name: "Rocky",
  shape: "drop",
  color: "#22d3ee",
  team: "none",
  tempo: "normal",
  dropbox: true,
  gmail: true,
  postiz: true,
  web: false,
  tailscale: true,
  model: "luna",
  effort: "medium",
  instructions: "",
};
type State = typeof initial;
const keysOf: Record<string, (keyof State)[]> = {
  profile: ["name", "shape", "color", "team"],
  voice: ["tempo"],
  integrations: ["dropbox", "gmail", "postiz"],
  access: ["web", "tailscale"],
  model: ["model", "effort", "instructions"],
};

function useAgentSettings() {
  const [saved, setSaved] = useState(initial);
  const [state, setState] = useState(initial);
  const changed = (Object.keys(state) as (keyof State)[]).filter(
    (key) => state[key] !== saved[key],
  );
  const set = <K extends keyof State>(key: K, value: State[K]) =>
    setState((current) => ({ ...current, [key]: value }));
  const dirty = (id: string) =>
    (keysOf[id] ?? []).some((key) => changed.includes(key));
  const sw = (
    key: "dropbox" | "gmail" | "postiz" | "web" | "tailscale",
    label: string,
  ) => (
    <KSwitch
      label={label}
      showLabel={false}
      checked={state[key]}
      onCheckedChange={(value) => set(key, value)}
    />
  );
  const sections: KSettingsDialogSection[] = [
    {
      id: "profile",
      icon: "user",
      group: "Agent",
      title: "Profile",
      summary: "Drop · No team",
      description: "Name, look and team. Shown in chats and notifications.",
      dirty: dirty("profile"),
      content: (
        <KStack gap="section">
          <KInput
            aria-label="Name"
            value={state.name}
            onChange={(event) => set("name", event.target.value)}
          />
          <KAvatarPicker
            shapes={avatarShapes.map((shape) => ({
              ...shape,
              icon: <KIcon name={shape.icon} size={20} />,
            }))}
            colors={avatarColors}
            shape={state.shape}
            color={state.color}
            onShapeChange={(value) => set("shape", value)}
            onColorChange={(value) => set("color", value)}
          />
          <KList>
            <KSettingsRow
              title="Team"
              description="A team shares its knowledge with the agent."
              control={
                <KSelect
                  label="Team"
                  value={state.team}
                  onValueChange={(value) => set("team", value)}
                  options={[
                    { value: "none", label: "No team" },
                    { value: "test", label: "Test" },
                  ]}
                />
              }
            />
          </KList>
        </KStack>
      ),
    },
    {
      id: "voice",
      icon: "audio-lines",
      group: "Agent",
      title: "Voice",
      status: "warning",
      summary: "No voice server ready",
      description:
        "Voice and speaking rate apply in the app, on the web and on Prompt-Boy.",
      dirty: dirty("voice"),
      content: (
        <KStack gap="section">
          <KAlert
            tone="warning"
            icon="triangle-alert"
            title="No voice server ready"
            description="Check the connection and reload the voices."
            action={<KButton variant="secondary">Reload</KButton>}
          />
          <KList>
            <KSettingsRow
              title="Voice"
              description="No voice selected"
              control={
                <KSelect
                  label="Voice"
                  disabled
                  placeholder="Choose voice"
                  options={[]}
                />
              }
            />
            <KSettingsRow
              title="Speaking rate"
              control={
                <KSelect
                  label="Speaking rate"
                  value={state.tempo}
                  onValueChange={(value) => set("tempo", value)}
                  options={[
                    { value: "slow", label: "Slow" },
                    { value: "normal", label: "Normal" },
                    { value: "fast", label: "Fast" },
                  ]}
                />
              }
            />
          </KList>
        </KStack>
      ),
    },
    {
      id: "knowledge",
      icon: "book-open",
      group: "Capabilities",
      title: "Knowledge & skills",
      status: "warning",
      summary: "1 entry unavailable · 0 skills",
      content: (
        <KStack gap="section">
          <KAlert
            tone="warning"
            icon="triangle-alert"
            title="A knowledge entry is no longer available"
            description="It was deleted or removed from the team."
          />
          <KList title="Team knowledge">
            <KSettingsRow
              title="Memories"
              description="What Rocky remembers from conversations."
              control={<KButton variant="secondary">Open</KButton>}
            />
          </KList>
          <KList title="Skills">
            <KSettingsRow
              title="No skills in this area yet"
              description="Save a version in the skill library first."
              control={<KButton variant="secondary">Skill library</KButton>}
            />
          </KList>
        </KStack>
      ),
    },
    {
      id: "integrations",
      icon: "plug",
      group: "Capabilities",
      title: "Integrations",
      summary: `${[state.dropbox, state.gmail, state.postiz].filter(Boolean).length} of 3 active`,
      description:
        "Connected services the agent may use. You still confirm writing actions.",
      dirty: dirty("integrations"),
      content: (
        <KList>
          <KSettingsRow
            title="Dropbox"
            description="Connected"
            control={sw("dropbox", "Dropbox")}
          />
          <KSettingsRow
            title="Gmail"
            description="Connected"
            control={sw("gmail", "Gmail")}
          />
          <KSettingsRow
            title="Postiz"
            description="Connected"
            control={sw("postiz", "Postiz")}
          />
        </KList>
      ),
    },
    {
      id: "access",
      icon: "shield",
      group: "Capabilities",
      title: "Access",
      summary: `Web ${state.web ? "on" : "off"} · Tailscale ${state.tailscale ? "on" : "off"}`,
      dirty: dirty("access"),
      content: (
        <KStack gap="section">
          <KList title="Web and browser">
            <KSettingsRow
              title="Web access"
              description="Reads websites with Firecrawl."
              control={sw("web", "Web access")}
            />
            <KSettingsRow
              title="Browser permissions"
              description="None yet. Permissions from the browser chat appear here."
              control={<KButton variant="secondary">Refresh</KButton>}
            />
          </KList>
          <KList title="Network">
            <KSettingsRow
              title="Tailscale"
              description="Own identity in your tailnet."
              control={sw("tailscale", "Tailscale")}
            />
          </KList>
          <KList title="Code and secrets">
            <KSettingsRow
              title="GitHub repositories"
              description="None connected in this area."
              control={null}
            />
            <KSettingsRow
              title="Secrets"
              description="None in this area."
              control={null}
            />
          </KList>
        </KStack>
      ),
    },
    {
      id: "model",
      icon: "cpu",
      group: "Runtime",
      title: "Model",
      summary: "GPT-5.6-Luna · Medium",
      dirty: dirty("model"),
      content: (
        <KStack gap="section">
          <KList>
            <KSettingsRow
              title="Model"
              description="The runtime checks support when it prepares."
              control={
                <KSelect
                  label="Model"
                  value={state.model}
                  onValueChange={(value) => set("model", value)}
                  options={[
                    { value: "luna", label: "GPT-5.6-Luna" },
                    { value: "mini", label: "GPT-5.6-mini" },
                  ]}
                />
              }
            />
            <KSettingsRow
              title="Reasoning effort"
              control={
                <KSegmentedControl
                  label="Reasoning effort"
                  value={state.effort}
                  onValueChange={(value) => set("effort", value)}
                  segments={[
                    { value: "low", label: "Low" },
                    { value: "medium", label: "Medium" },
                    { value: "high", label: "High" },
                  ]}
                />
              }
            />
          </KList>
          <KTextarea
            aria-label="Personality and instructions"
            placeholder="For example: answer briefly, ask before sending mail."
            value={state.instructions}
            onChange={(event) => set("instructions", event.target.value)}
          />
        </KStack>
      ),
    },
    {
      id: "runtime",
      icon: "server",
      group: "Runtime",
      title: "Runtime",
      status: "error",
      summary: "Environment unavailable",
      content: (
        <KStack gap="section">
          <KAlert
            tone="error"
            icon="circle-alert"
            title="Environment unavailable"
            description="Running work keeps its resources. The new configuration applies once it is idle."
            action={<KButton variant="secondary">Resume agent</KButton>}
          />
          <KList>
            <KSettingsRow
              title="Update runtime environment"
              description="Reinstalls the environment. Agent state and working directory stay."
              control={<KButton variant="secondary">Update</KButton>}
            />
          </KList>
          <KDisclosure title="Technical details">
            <KText variant="caption">
              Applied revision sha256:af6cb9ac…730ab67f
            </KText>
          </KDisclosure>
        </KStack>
      ),
    },
  ];
  const footer = (
    <KSaveBar
      changes={changed.length}
      onDiscard={() => setState(saved)}
      onSave={() => setSaved(state)}
    />
  );
  return { state, sections, footer };
}

function Avatar({ shape, color }: { shape: string; color: string }) {
  const icon = avatarShapes.find((item) => item.id === shape)?.icon ?? "circle";
  return (
    <span style={{ color, display: "inline-flex" }}>
      <KIcon name={icon} size={32} />
    </span>
  );
}

/** Inline: the panel follows its width (600 px breakpoint). */
export function SettingsDialogFixture() {
  const { state, sections, footer } = useAgentSettings();
  return (
    <div style={{ height: 640, width: "100%", maxWidth: 820 }}>
      <KSettingsDialogPanel
        title={state.name || "Untitled"}
        subtitle="Personal · Orbit Agent Runtime"
        leading={<Avatar shape={state.shape} color={state.color} />}
        sections={sections}
        footer={footer}
        onClose={() => {}}
      />
    </div>
  );
}

/** As an overlay: dialog on tablets and desktops, bottom sheet on phones. */
export function SettingsDialogOverlay() {
  const [open, setOpen] = useState(false);
  const [selected, setSelected] = useState<string | null>(null);
  const { state, sections, footer } = useAgentSettings();
  return (
    <>
      <KButton onClick={() => setOpen(true)}>Configure agent</KButton>
      <KSettingsDialog
        open={open}
        onOpenChange={setOpen}
        title={state.name || "Untitled"}
        subtitle="Personal · Orbit Agent Runtime"
        leading={<Avatar shape={state.shape} color={state.color} />}
        headerAction={
          <KButton variant="ghost" onClick={() => setSelected("runtime")}>
            Runtime unavailable
          </KButton>
        }
        selectedId={selected}
        onSelectedIdChange={setSelected}
        sections={sections}
        footer={footer}
      />
    </>
  );
}
