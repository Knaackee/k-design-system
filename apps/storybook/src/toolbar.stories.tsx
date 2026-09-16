import type { Meta, StoryObj } from "@storybook/react-vite";
import { ActionFixture } from "./action-fixture.js";
const meta = {
  title: "Patterns/Toolbar",
  component: ActionFixture,
  parameters: { fixtureId: "toolbar-actions" },
} satisfies Meta<typeof ActionFixture>;
export default meta;
export const Actions: StoryObj<typeof meta> = {
  name: "toolbar-actions",
  args: { kind: "toolbar" },
};
