import type { Meta, StoryObj } from "@storybook/react-vite";
import { TableFixture } from "./table-fixture.js";
const meta = {
  title: "Data display/Table",
  component: TableFixture,
} satisfies Meta<typeof TableFixture>;
export default meta;
export const Basic: StoryObj<typeof meta> = {
  name: "table-basic",
  parameters: { fixtureId: "table-basic" },
  args: { kind: "basic" },
};
export const Cells: StoryObj<typeof meta> = {
  name: "table-cells",
  parameters: { fixtureId: "table-cells" },
  args: { kind: "cells" },
};
