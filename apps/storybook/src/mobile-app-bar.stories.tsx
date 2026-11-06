import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KButton,
  KIcon,
  KMobileAppBar,
  KStack,
  KText,
  type KGlassQuality,
  type KMobileAppBarItem,
  type KMobileAppBarVariant,
} from "@k-design-system/ui";
import "./mobile-app-bar.stories.css";

function AppMark() {
  return (
    <svg aria-hidden="true" width="32" height="32" viewBox="12 32 104 72">
      <path d="M14 102V90l24-14v26H14Z" fill="#EFA24C" />
      <path d="M44 102V74l26-18v46H44Z" fill="#A9A29A" />
      <path d="M76 102V50l19-14 19 14v52H76Z" fill="currentColor" />
    </svg>
  );
}
const items: readonly KMobileAppBarItem[] = [
  {
    id: "portfolios",
    label: "Portfolios",
    icon: <KIcon name="building" size={24} />,
  },
  { id: "chat", label: "Chat", icon: <AppMark /> },
  {
    id: "settings",
    label: "Settings",
    icon: <KIcon name="settings" size={24} />,
  },
];
function MobileAppBarFixture({
  quality,
  variant,
}: {
  quality: KGlassQuality;
  variant: KMobileAppBarVariant;
}) {
  const [selectedId, setSelectedId] = useState("chat");
  const [collapsed, setCollapsed] = useState(false);
  const [message, setMessage] = useState("");
  const action = variant === "action";
  return (
    <div className="mobile-app-bar-preview">
      <main className="mobile-app-bar-preview__viewport">
        <header className="mobile-app-bar-preview__header">
          <KStack gap="control">
            <KText variant="caption">KMobileAppBar</KText>
            <KText variant="heading3">{variant.replaceAll("-", " ")}</KText>
          </KStack>
        </header>
        <section className="mobile-app-bar-preview__state" aria-live="polite">
          <KStack gap="control" align="center">
            <KText variant="heading2">
              {items.find((item) => item.id === selectedId)?.label}
            </KText>
            <KText variant="bodySmall">
              {message || "Choose a destination below."}
            </KText>
            {variant === "collapsible" && (
              <KButton
                variant="secondary"
                onClick={() => setCollapsed(!collapsed)}
              >
                {collapsed ? "Show navigation" : "Hide navigation"}
              </KButton>
            )}
          </KStack>
        </section>
        <KMobileAppBar
          items={action ? items.filter((item) => item.id !== "chat") : items}
          variant={variant}
          quality={quality}
          visibility="always"
          selectedId={selectedId}
          collapsed={collapsed}
          onSelectionChange={setSelectedId}
          primaryAction={
            action ? (
              <KButton
                aria-label="Chat"
                aria-pressed={selectedId === "chat"}
                variant={selectedId === "chat" ? "primary" : "secondary"}
                onClick={() => setSelectedId("chat")}
              >
                <AppMark />
              </KButton>
            ) : undefined
          }
          contextualContent={
            <>
              <KText variant="label">3 selected</KText>
              <KButton
                variant="ghost"
                onClick={() => setMessage("Move selected")}
              >
                Move
              </KButton>
              <KButton
                variant="ghost"
                onClick={() => setMessage("Delete selected")}
              >
                Delete
              </KButton>
            </>
          }
        />
      </main>
    </div>
  );
}
const meta = {
  title: "Navigation/MobileAppBar",
  component: MobileAppBarFixture,
  parameters: { layout: "fullscreen" },
  args: { quality: "solid", variant: "fixed" },
  argTypes: {
    quality: {
      control: "select",
      options: ["auto", "liquid", "frosted", "solid"],
    },
    variant: {
      control: "select",
      options: [
        "fixed",
        "floating-dock",
        "action",
        "fixed-line",
        "floating-glass",
        "labeled",
        "collapsible",
        "contextual",
      ],
    },
  },
} satisfies Meta<typeof MobileAppBarFixture>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Fixed: Story = {};
export const FloatingDock: Story = { args: { variant: "floating-dock" } };
export const Action: Story = { args: { variant: "action" } };
export const FixedLine: Story = { args: { variant: "fixed-line" } };
export const FloatingGlass: Story = {
  args: { variant: "floating-glass", quality: "frosted" },
};
export const Labeled: Story = { args: { variant: "labeled" } };
export const Collapsible: Story = { args: { variant: "collapsible" } };
export const Contextual: Story = { args: { variant: "contextual" } };
