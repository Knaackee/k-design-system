import type { Meta, StoryObj } from "@storybook/react-vite";
import { DashboardShellFixture } from "./dashboard-shell-fixture.js";
export default {
  title: "Showcase/Dashboard App Shell",
  component: DashboardShellFixture,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof DashboardShellFixture>;
export const Dashboard: StoryObj<typeof DashboardShellFixture> = {
  parameters: { fixtureId: "showcase-dashboard-shell" },
};
export const WithInspector: StoryObj<typeof DashboardShellFixture> = {
  args: { initialInspector: true },
  parameters: { fixtureId: "showcase-dashboard-shell-inspector" },
};
export const Expanded: StoryObj<typeof DashboardShellFixture> = {
  args: { initialMode: "expanded" },
  parameters: { fixtureId: "showcase-dashboard-shell-expanded" },
};
