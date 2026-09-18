import type { Meta, StoryObj } from "@storybook/react-vite";
import { DataTableVirtualFixture } from "./data-table-virtual-fixture.js";
const meta = {
  title: "Patterns/DataTableVirtual",
  component: DataTableVirtualFixture,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof DataTableVirtualFixture>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Virtual: Story = {
  name: "data-table-virtual",
  args: { external: false },
  parameters: { fixtureId: "data-table-virtual" },
};
export const External: Story = {
  name: "data-table-external",
  args: { external: true },
  parameters: { fixtureId: "data-table-external" },
};
