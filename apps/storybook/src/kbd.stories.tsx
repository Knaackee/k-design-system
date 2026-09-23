import type { Meta, StoryObj } from "@storybook/react-vite";
import { KbdFixture } from "./extended-component-fixtures.js";
export default {
  title: "Data display/Kbd",
  component: KbdFixture,
} satisfies Meta<typeof KbdFixture>;
export const Shortcuts: StoryObj<typeof KbdFixture> = {
  name: "kbd-shortcuts",
  parameters: { fixtureId: "kbd-shortcuts" },
};
