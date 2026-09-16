import type { Meta, StoryObj } from "@storybook/react-vite";
import { ActionFixture } from "./action-fixture.js";
const meta = {
  title: "Actions/MenuButton",
  component: ActionFixture,
  parameters: { fixtureId: "menu-button-actions" },
} satisfies Meta<typeof ActionFixture>;
export default meta;
export const Actions: StoryObj<typeof meta> = {
  name: "menu-button-actions",
  args: { kind: "menu" },
};
