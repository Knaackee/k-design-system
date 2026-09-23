import type { Meta, StoryObj } from "@storybook/react-vite";
import { AlertFixture } from "./basic-component-fixtures.js";
const meta = {
  title: "Feedback/Alert",
  component: AlertFixture,
} satisfies Meta<typeof AlertFixture>;
export default meta;
export const States: StoryObj<typeof meta> = {
  name: "alert-states",
  parameters: { fixtureId: "alert-states" },
};
