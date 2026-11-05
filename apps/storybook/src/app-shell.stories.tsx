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
