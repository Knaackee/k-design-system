import type { Meta, StoryObj } from "@storybook/react-vite";
import { BreadcrumbFixture } from "./basic-component-fixtures.js";
const meta = {
  title: "Navigation/Breadcrumb",
  component: BreadcrumbFixture,
} satisfies Meta<typeof BreadcrumbFixture>;
export default meta;
export const Navigation: StoryObj<typeof meta> = {
  name: "breadcrumb-navigation",
  parameters: { fixtureId: "breadcrumb-navigation" },
};
