import type { Meta, StoryObj } from "@storybook/react-vite";
import { CommandPaletteFixture } from "./command-palette-fixture.js";

const meta = {
  title: "Actions/CommandPalette",
  component: CommandPaletteFixture,
  parameters: { fixtureId: "command-palette-actions", layout: "fullscreen" },
} satisfies Meta<typeof CommandPaletteFixture>;

export default meta;
export const Actions: StoryObj<typeof meta> = {
  name: "command-palette-actions",
};
