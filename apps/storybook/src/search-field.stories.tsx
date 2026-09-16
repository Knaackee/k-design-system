import type { Meta, StoryObj } from "@storybook/react-vite";
import { FormFixture } from "./form-fixture.js";
const meta = {
  title: "Forms/SearchField",
  component: FormFixture,
  parameters: { fixtureId: "search-field-states" },
} satisfies Meta<typeof FormFixture>;
export default meta;
export const States: StoryObj<typeof meta> = {
  name: "search-field-states",
  args: { kind: "search-field" },
};
