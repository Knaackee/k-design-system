import type { Meta, StoryObj } from "@storybook/react-vite";
import { FormFixture } from "./form-fixture.js";
const meta = {
  title: "Forms/Field",
  component: FormFixture,
  parameters: { fixtureId: "field-states" },
} satisfies Meta<typeof FormFixture>;
export default meta;
export const States: StoryObj<typeof meta> = {
  name: "field-states",
  args: { kind: "field" },
};
