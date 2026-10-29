import type { Meta, StoryObj } from "@storybook/react-vite";
import { SortableTreeFixture } from "./sortable-tree-fixture.js";

export default {
  title: "Patterns/SortableTree",
  component: SortableTreeFixture,
} satisfies Meta<typeof SortableTreeFixture>;
type Story = StoryObj<typeof SortableTreeFixture>;
export const Categories: Story = {
  parameters: { fixtureId: "sortable-tree-categories" },
};
export const Mobile: Story = {
  args: { mobile: true },
  parameters: { fixtureId: "sortable-tree-mobile" },
};
export const Flat: Story = {
  args: { initial: "flat" },
  parameters: { fixtureId: "sortable-tree-flat" },
};
export const Ungrouped: Story = {
  args: { mobile: true, ungrouped: true },
  parameters: { fixtureId: "sortable-tree-ungrouped" },
};
export const Tablet: Story = {
  parameters: { fixtureId: "sortable-tree-tablet" },
};
export const Deep: Story = {
  args: { deep: true },
  parameters: { fixtureId: "sortable-tree-deep" },
};
export const Empty: Story = {
  args: { empty: true },
  parameters: { fixtureId: "sortable-tree-empty" },
};
