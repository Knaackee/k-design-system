import type { Meta, StoryObj } from "@storybook/react-vite";
import { SymbolPickerFixture } from "./symbol-picker-fixture.js";
export default {
  title: "Forms/IconPicker",
  parameters: { fixtureId: "icon-picker-icons" },
} satisfies Meta;
export const Icons: StoryObj = {
  name: "icon-picker-icons",
  render: () => <SymbolPickerFixture />,
};
