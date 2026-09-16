import type { Meta, StoryObj } from "@storybook/react-vite";
import { FormFixture } from "./form-fixture.js";
const meta = {
  title: "Forms/Combobox",
  component: FormFixture,
  parameters: { fixtureId: "combobox-states" },
} satisfies Meta<typeof FormFixture>;
export default meta;
export const States: StoryObj<typeof meta> = {
  name: "combobox-states",
  args: { kind: "combobox" },
};
