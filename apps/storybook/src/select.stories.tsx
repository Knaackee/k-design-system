import type { Meta, StoryObj } from "@storybook/react-vite";
import { FormFixture } from "./form-fixture.js";
const meta = {
  title: "Forms/Select",
  component: FormFixture,
  parameters: { fixtureId: "select-states" },
} satisfies Meta<typeof FormFixture>;
export default meta;
export const States: StoryObj<typeof meta> = {
  name: "select-states",
  args: { kind: "select" },
};
