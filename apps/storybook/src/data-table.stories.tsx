import { DataTableCellsFixture } from "./data-table-cells-fixture.js";
import { DataTableOverflowFixture } from "./data-table-overflow-fixture.js";
import { expect, userEvent, waitFor, within } from "storybook/test";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { DataTableFixture } from "./data-table-fixture.js";
const meta = {
  title: "Patterns/DataTable",
  component: DataTableFixture,
} satisfies Meta<typeof DataTableFixture>;
export default meta;
export const Overflow = {
  name: "data-table-overflow",
  parameters: { fixtureId: "data-table-overflow" },
  render: () => <DataTableOverflowFixture />,
  play: async ({ canvasElement }: { canvasElement: HTMLElement }) => {
    const canvas = within(canvasElement);
    const name = canvas.getByText(
      "Wohnquartier Am Sonnenhang mit langem Namen",
      { selector: ".k-truncated__content" },
    );
    await waitFor(() =>
      expect(name.scrollWidth).toBeGreaterThan(name.clientWidth),
    );
    expect(getComputedStyle(name).whiteSpace).toBe("nowrap");
    expect(getComputedStyle(name).textOverflow).toBe("ellipsis");
    const open = canvas.getByRole("button", {
      name: "Wirtschaftseinheit öffnen",
    });
    open.focus();
    await waitFor(() =>
      expect(
        canvasElement.querySelector("[popover]:popover-open"),
      ).not.toBeNull(),
    );
    expect(
      canvas.getByRole("button", {
        name: "Wirtschaftseinheit öffnen",
      }),
    ).toBe(open);
    await userEvent.keyboard("{Escape}");
    await waitFor(() =>
      expect(canvasElement.querySelector("[popover]:popover-open")).toBeNull(),
    );
    await userEvent.click(
      canvas.getByRole("button", { name: "Wirtschaftseinheit" }),
    );
    expect(
      canvas.getByRole("columnheader", {
        name: "Wirtschaftseinheit",
      }),
    ).toHaveAttribute("aria-sort", "descending");
    const description = canvas
      .getByRole("table", { name: "Multiline description" })
      .querySelector("td")!;
    expect(getComputedStyle(description).whiteSpace).toBe("normal");
    open.blur();
  },
};
export const Headers: StoryObj<typeof meta> = {
  name: "data-table-headers",
  parameters: { fixtureId: "data-table-headers" },
  args: { showHeader: true },
};
export const GroupedHeaders: StoryObj<typeof meta> = {
  name: "data-table-grouped-headers",
  parameters: { fixtureId: "data-table-grouped-headers" },
  args: { showHeader: true, grouped: true },
};
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
