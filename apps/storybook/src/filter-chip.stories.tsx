import type { Meta, StoryObj } from "@storybook/react-vite";
import { FormFixture } from "./form-fixture.js";
const meta = {
  title: "Forms/FilterChip",
  component: FormFixture,
  parameters: { fixtureId: "filter-chip-states" },
} satisfies Meta<typeof FormFixture>;
export default meta;
export const States: StoryObj<typeof meta> = {
  name: "filter-chip-states",
  args: { kind: "filter-chip" },
};
