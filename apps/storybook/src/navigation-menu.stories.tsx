import type { Meta, StoryObj } from "@storybook/react-vite";
import { NavigationMenuFixture } from "./extended-component-fixtures.js";
export default {
  title: "Navigation/NavigationMenu",
  component: NavigationMenuFixture,
} satisfies Meta<typeof NavigationMenuFixture>;
export const Links: StoryObj<typeof NavigationMenuFixture> = {
  name: "navigation-menu-links",
  parameters: { fixtureId: "navigation-menu-links" },
};
