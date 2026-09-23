import type { Meta, StoryObj } from "@storybook/react-vite";
import { ProgressFixture } from "./extended-component-fixtures.js";
export default {
  title: "Feedback/Progress",
  component: ProgressFixture,
} satisfies Meta<typeof ProgressFixture>;
export const States: StoryObj<typeof ProgressFixture> = {
  name: "progress-states",
  parameters: { fixtureId: "progress-states" },
};
