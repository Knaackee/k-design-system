import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  PickerFixture,
  pickerControls,
  pickerDefaults,
} from "./picker-fixture.js";
const meta = {
  title: "Forms/TimePicker",
  component: PickerFixture,
  parameters: { fixtureId: "time-picker-states" },
  args: { ...pickerDefaults, kind: "time" },
  argTypes: pickerControls,
} satisfies Meta<typeof PickerFixture>;
export default meta;
export const States: StoryObj<typeof meta> = { name: "time-picker-states" };
