import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  PickerFixture,
  pickerControls,
  pickerDefaults,
} from "./picker-fixture.js";
const meta = {
  title: "Forms/DatePicker",
  component: PickerFixture,
  parameters: { fixtureId: "date-picker-states" },
  args: { ...pickerDefaults, kind: "date" },
  argTypes: pickerControls,
} satisfies Meta<typeof PickerFixture>;
export default meta;
export const States: StoryObj<typeof meta> = { name: "date-picker-states" };
