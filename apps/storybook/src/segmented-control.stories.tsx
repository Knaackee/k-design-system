import type { Meta, StoryObj } from "@storybook/react-vite";
import { SegmentedControlFixture } from "./core-components-fixtures.js";

export default {
  title: "Navigation/SegmentedControl",
  parameters: { layout: "fullscreen" },
} satisfies Meta;

export const Review: StoryObj = {
  name: "segmented-control",
  parameters: { fixtureId: "segmented-control" },
  render: () => <SegmentedControlFixture />,
};
