import type { Meta, StoryObj } from "@storybook/react-vite";
import { PaginationFixture } from "./extended-component-fixtures.js";
export default {
  title: "Navigation/Pagination",
  component: PaginationFixture,
} satisfies Meta<typeof PaginationFixture>;
export const Pages: StoryObj<typeof PaginationFixture> = {
  name: "pagination-pages",
  parameters: { fixtureId: "pagination-pages" },
};
