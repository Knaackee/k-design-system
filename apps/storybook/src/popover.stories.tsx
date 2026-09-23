import type { Meta, StoryObj } from "@storybook/react-vite";
import { PopoverFixture } from "./extended-component-fixtures.js";
export default {
  title: "Overlays/Popover",
  component: PopoverFixture,
} satisfies Meta<typeof PopoverFixture>;
export const Content: StoryObj<typeof PopoverFixture> = {
  name: "popover-content",
  parameters: { fixtureId: "popover-content" },
};
