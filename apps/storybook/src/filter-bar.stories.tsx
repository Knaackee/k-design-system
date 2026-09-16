import type { Meta, StoryObj } from "@storybook/react-vite";
import { FormFixture } from "./form-fixture.js";
const meta = {
  title: "Patterns/FilterBar",
  component: FormFixture,
  parameters: { fixtureId: "filter-bar-filters" },
} satisfies Meta<typeof FormFixture>;
export default meta;
export const Filters: StoryObj<typeof meta> = {
  name: "filter-bar-filters",
  args: { kind: "filter-bar" },
};
