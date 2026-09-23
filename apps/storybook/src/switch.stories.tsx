import type { Meta, StoryObj } from "@storybook/react-vite";
import { SwitchFixture } from "./extended-component-fixtures.js";
export default {
  title: "Forms/Switch",
  component: SwitchFixture,
} satisfies Meta<typeof SwitchFixture>;
export const Toggle: StoryObj<typeof SwitchFixture> = {
  name: "switch-toggle",
  parameters: { fixtureId: "switch-toggle" },
};
