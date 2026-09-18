import { DataTableCellsFixture } from "./data-table-cells-fixture.js";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { DataTableFixture } from "./data-table-fixture.js";
const meta = {
  title: "Patterns/DataTable",
  component: DataTableFixture,
} satisfies Meta<typeof DataTableFixture>;
export default meta;
export const Rows: StoryObj<typeof meta> = {
  name: "data-table-rows",
  parameters: { fixtureId: "data-table-rows" },
  args: { grouped: false },
};
export const Groups: StoryObj<typeof meta> = {
  name: "data-table-groups",
  parameters: { fixtureId: "data-table-groups" },
  args: { grouped: true },
};

export const Cells = {
  name: "data-table-cells",
  parameters: { fixtureId: "data-table-cells" },
  render: () => <DataTableCellsFixture />,
};

export const SingleColumn = {
  name: "data-table-single-column",
  parameters: { fixtureId: "data-table-single-column" },
  render: () => <DataTableFixture grouped singleColumn allowCreate />,
};
