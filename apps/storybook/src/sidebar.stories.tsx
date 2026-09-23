import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  SidebarDrawerFixture,
  SidebarFixture,
  SettingsSidebarFixture,
} from "./sidebar-fixture.js";

export default {
  title: "Navigation/Sidebar",
  component: SidebarFixture,
  parameters: { layout: "centered" },
} satisfies Meta<typeof SidebarFixture>;

export const Expanded: StoryObj<typeof SidebarFixture> = {
  name: "sidebar-expanded",
  parameters: { fixtureId: "sidebar-expanded" },
};

export const Rail: StoryObj<typeof SidebarFixture> = {
  name: "sidebar-rail",
  args: { initialMode: "rail" },
  parameters: { fixtureId: "sidebar-rail" },
};

export const InDrawer: StoryObj<typeof SidebarDrawerFixture> = {
  name: "sidebar-drawer",
  render: () => <SidebarDrawerFixture />,
  parameters: { fixtureId: "sidebar-drawer" },
};

export const Settings: StoryObj<typeof SettingsSidebarFixture> = {
  name: "sidebar-settings",
  render: () => <SettingsSidebarFixture />,
  parameters: { fixtureId: "sidebar-settings" },
};
