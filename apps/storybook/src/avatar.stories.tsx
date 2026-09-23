import type { Meta, StoryObj } from "@storybook/react-vite";
import { AvatarFixture } from "./basic-component-fixtures.js";
const meta = {
  title: "Data display/Avatar",
  component: AvatarFixture,
} satisfies Meta<typeof AvatarFixture>;
export default meta;
export const Variants: StoryObj<typeof meta> = {
  name: "avatar-variants",
  parameters: { fixtureId: "avatar-variants" },
};
