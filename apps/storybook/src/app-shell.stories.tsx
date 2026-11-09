import type { Meta, StoryObj } from "@storybook/react-vite";
import { AppShellFixture } from "./core-components-fixtures.js";
import { useState } from "react";
import {
  KAppShell,
  KSidebarToggle,
  KSidebarExpandedContent,
  KSidebarItem,
  KIcon,
  KPage,
  KPageHeader,
} from "@k-design-system/ui";

function CollapsibleShell() {
  const [mode, setMode] = useState<"expanded" | "rail">("expanded");
  const [selected, setSelected] = useState("home");
  return (
    <KAppShell
      destinations={[
        { id: "home", label: "Home", icon: "house" },
        { id: "settings", label: "Settings", icon: "settings" },
      ]}
      selectedId={selected}
      onSelectedChange={setSelected}
      sidebarMode={mode}
      onSidebarModeChange={setMode}
      sidebarHeader={
        <>
          <KSidebarExpandedContent>Workspace</KSidebarExpandedContent>
          <KSidebarToggle
            expandedContent={<KIcon name="menu" />}
            railContent={<KIcon name="menu" />}
          />
        </>
      }
      sidebarContent={
        <KSidebarItem
          label="Additional destination"
          leading={<KIcon name="calendar" />}
          onSelect={() => setSelected("calendar")}
        />
      }
      style={{ height: "100dvh" }}
    >
      <KPage>
        <KPageHeader title={selected} />
      </KPage>
    </KAppShell>
  );
}

export const ReviewCollapsible: StoryObj = {
  name: "app-shell-collapsible",
  render: () => <CollapsibleShell />,
};

export default {
  title: "Navigation/AppShell",
  parameters: { layout: "fullscreen" },
} satisfies Meta;

export const Review: StoryObj = {
  name: "app-shell",
  parameters: { fixtureId: "app-shell" },
  render: () => <AppShellFixture />,
};

export const ReviewPortfolios: StoryObj = {
  name: "app-shell-portfolios",
  parameters: { fixtureId: "app-shell-portfolios" },
  render: () => <AppShellFixture initial="portfolios" />,
};

export const ReviewAssistant: StoryObj = {
  name: "app-shell-assistant",
  parameters: { fixtureId: "app-shell-assistant" },
  render: () => <AppShellFixture initial="home" />,
};

export const ReviewCustomSidebar: StoryObj = {
  name: "app-shell-custom-sidebar",
  parameters: { fixtureId: "app-shell-custom-sidebar" },
  render: () => <AppShellFixture initial="home" customSidebar />,
};

export const ReviewIconOnly: StoryObj = {
  name: "app-shell-icon-only",
  parameters: { fixtureId: "app-shell-icon-only" },
  render: () => <AppShellFixture iconOnlyTabs />,
};
