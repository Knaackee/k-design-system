import type { Meta, StoryObj } from "@storybook/react-vite";
import { ContextMenuFixture } from "./context-menu-fixture.js";

const meta = {
  title: "Actions/ContextMenu",
  component: ContextMenuFixture,
  parameters: { fixtureId: "context-menu-actions" },
} satisfies Meta<typeof ContextMenuFixture>;

export default meta;
export const Actions: StoryObj<typeof meta> = {
  name: "context-menu-actions",
};
