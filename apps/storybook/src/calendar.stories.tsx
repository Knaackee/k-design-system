import type { Meta, StoryObj } from "@storybook/react-vite";
import { CalendarFixture } from "./calendar-fixture.js";

const meta = {
  title: "Patterns/Calendar",
  component: CalendarFixture,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof CalendarFixture>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Day: Story = {
  name: "calendar-day",
  args: { initialView: "day" },
  parameters: { fixtureId: "calendar-day" },
};
export const ThreeDay: Story = {
  name: "calendar-three-day",
  args: { initialView: "three-day" },
  parameters: { fixtureId: "calendar-three-day" },
};
export const Week: Story = {
  name: "calendar-week",
  args: { initialView: "week" },
  parameters: { fixtureId: "calendar-week" },
};
export const Month: Story = {
  name: "calendar-month",
  args: { initialView: "month" },
  parameters: { fixtureId: "calendar-month" },
};
