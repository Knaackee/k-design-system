import type { Meta, StoryObj } from "@storybook/react-vite";
import { SettingsPageFixture } from "./settings-page-fixture.js";

const meta = {
  title: "Patterns/SettingsPage",
  component: SettingsPageFixture,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof SettingsPageFixture>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Responsive: Story = {
  name: "settings-page-responsive",
  parameters: { fixtureId: "settings-page-responsive" },
};
