import type { Meta, StoryObj } from "@storybook/react-vite";
import { KanbanFixture } from "./kanban-fixture.js";

const meta = {
  title: "Patterns/Kanban",
  component: KanbanFixture,
} satisfies Meta<typeof KanbanFixture>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Board: Story = {
  name: "kanban-board",
  parameters: { fixtureId: "kanban-board", layout: "fullscreen" },
};

export const Selection: Story = {
  name: "kanban-selection",
  parameters: { fixtureId: "kanban-selection", layout: "fullscreen" },
  args: { selection: true },
};

export const Mobile: Story = {
  name: "kanban-mobile",
  globals: {
    viewport: { value: "compact", isRotated: false },
  },
  parameters: {
    fixtureId: "kanban-mobile",
    layout: "fullscreen",
    viewport: {
      options: {
        compact: {
          name: "Compact · 375",
          styles: { width: "375px", height: "812px" },
          type: "mobile",
        },
      },
    },
  },
};
