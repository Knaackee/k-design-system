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

export const BrandNavigation: StoryObj = {
  name: "app-shell-brand-navigation",
  parameters: { fixtureId: "app-shell-brand-navigation" },
  render: () => <AppShellFixture initial="inbox" brandNavigation />,
};
