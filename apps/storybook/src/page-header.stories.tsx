import type { Meta, StoryObj } from "@storybook/react-vite";
import { PageHeaderFixture } from "./core-components-fixtures.js";

export default {
  title: "Navigation/PageHeader",
  parameters: { layout: "fullscreen" },
} satisfies Meta;

export const Review: StoryObj = {
  name: "page-header",
  parameters: { fixtureId: "page-header" },
  render: () => <PageHeaderFixture />,
};
