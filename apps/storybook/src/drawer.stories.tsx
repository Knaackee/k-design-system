import type { Meta, StoryObj } from "@storybook/react-vite";
import { DrawerFixture } from "./extended-component-fixtures.js";
export default {
  title: "Overlays/Drawer",
  component: DrawerFixture,
} satisfies Meta<typeof DrawerFixture>;
export const Responsive: StoryObj<typeof DrawerFixture> = {
  name: "drawer-responsive",
  parameters: { fixtureId: "drawer-responsive" },
};
