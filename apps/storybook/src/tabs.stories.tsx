import type { Meta, StoryObj } from "@storybook/react-vite";
import { TabsFixture } from "./extended-component-fixtures.js";
export default {
  title: "Navigation/Tabs",
  component: TabsFixture,
} satisfies Meta<typeof TabsFixture>;
export const Panels: StoryObj<typeof TabsFixture> = {
  name: "tabs-panels",
  parameters: { fixtureId: "tabs-panels" },
};
