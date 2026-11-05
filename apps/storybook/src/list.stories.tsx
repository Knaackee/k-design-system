import type { Meta, StoryObj } from "@storybook/react-vite";
import { ListFixture } from "./core-components-fixtures.js";

export default {
  title: "Data display/List",
  parameters: { layout: "fullscreen" },
} satisfies Meta;

export const Review: StoryObj = {
  name: "list",
  parameters: { fixtureId: "list" },
  render: () => <ListFixture />,
};
