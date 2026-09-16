import type { Meta, StoryObj } from "@storybook/react-vite";
import { FormFixture } from "./form-fixture.js";
const meta = {
  title: "Forms/Checkbox",
  component: FormFixture,
  parameters: { fixtureId: "checkbox-states" },
} satisfies Meta<typeof FormFixture>;
export default meta;
export const States: StoryObj<typeof meta> = {
  name: "checkbox-states",
  args: { kind: "checkbox" },
};
