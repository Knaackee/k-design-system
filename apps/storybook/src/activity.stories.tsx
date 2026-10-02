import type { Meta, StoryObj } from "@storybook/react-vite";
import { ActivityFixture } from "./activity-fixture.js";

const meta = {
  title: "Patterns/Activity",
  component: ActivityFixture,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof ActivityFixture>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Completed: Story = {
  name: "activity-completed",
  args: { initialMode: "completed" },
};
export const Phone: Story = {
  name: "activity-phone",
  args: { phone: true },
};
export const Empty: Story = {
  name: "activity-empty",
  args: { empty: true },
};
