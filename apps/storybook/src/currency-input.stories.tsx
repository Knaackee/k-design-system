import type { Meta, StoryObj } from "@storybook/react-vite";
import { CurrencyFixture } from "./currency-fixture.js";
const meta = {
  title: "Forms/CurrencyInput",
  component: CurrencyFixture,
  parameters: { fixtureId: "currency-input-states" },
} satisfies Meta<typeof CurrencyFixture>;
export default meta;
export const States: StoryObj<typeof meta> = { name: "currency-input-states" };
