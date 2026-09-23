import type { Meta, StoryObj } from "@storybook/react-vite";
import { BadgeFixture } from "./basic-component-fixtures.js";
const meta = {
  title: "Data display/Badge",
  component: BadgeFixture,
} satisfies Meta<typeof BadgeFixture>;
export default meta;
export const Variants: StoryObj<typeof meta> = {
  name: "badge-variants",
  parameters: { fixtureId: "badge-variants" },
};
