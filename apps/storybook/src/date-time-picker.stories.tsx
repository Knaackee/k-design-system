import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  PickerFixture,
  pickerControls,
  pickerDefaults,
} from "./picker-fixture.js";
const meta = {
  title: "Forms/DateTimePicker",
  component: PickerFixture,
  parameters: { fixtureId: "date-time-picker-states" },
  args: { ...pickerDefaults, kind: "date-time" },
  argTypes: pickerControls,
} satisfies Meta<typeof PickerFixture>;
export default meta;
export const States: StoryObj<typeof meta> = {
  name: "date-time-picker-states",
};
