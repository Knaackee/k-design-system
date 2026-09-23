import type { Meta, StoryObj } from "@storybook/react-vite";
import { SymbolPickerFixture } from "./symbol-picker-fixture.js";
export default {
  title: "Forms/EmojiPicker",
  parameters: { fixtureId: "emoji-picker-reactions" },
} satisfies Meta;
export const Reactions: StoryObj = {
  name: "emoji-picker-reactions",
  render: () => <SymbolPickerFixture emoji />,
};
