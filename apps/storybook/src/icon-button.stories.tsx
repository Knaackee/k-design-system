import type { Meta, StoryObj } from "@storybook/react-vite";
import { ActionFixture } from "./action-fixture.js";
const meta = {
  title: "Actions/IconButton",
  component: ActionFixture,
  parameters: { fixtureId: "icon-button-actions" },
} satisfies Meta<typeof ActionFixture>;
export default meta;
export const Actions: StoryObj<typeof meta> = {
  name: "icon-button-actions",
  args: { kind: "icon" },
};
