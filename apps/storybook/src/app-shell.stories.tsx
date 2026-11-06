import type { Meta, StoryObj } from "@storybook/react-vite";
import { AppShellFixture } from "./core-components-fixtures.js";

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
