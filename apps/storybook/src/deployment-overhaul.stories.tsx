import type { Meta, StoryObj } from "@storybook/react-vite";
import { DeploymentOverhaul } from "./deployment-overhaul-view";

const meta = {
  title: "Review/DeploymentOverhaul",
  component: DeploymentOverhaul,
  render: (args, context) => (
    <DeploymentOverhaul {...args} dark={context.globals.theme === "dark"} />
  ),
  parameters: { layout: "fullscreen" },
  args: { initialPage: "times", empty: false, dark: false },
} satisfies Meta<typeof DeploymentOverhaul>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Times: Story = {};
export const TimesDark: Story = {
  args: { dark: true },
  globals: { theme: "dark" },
};
export const TimesEmpty: Story = { args: { empty: true } };
export const Zones: Story = { args: { initialPage: "zones" } };
export const ZonesDark: Story = {
  args: { initialPage: "zones", dark: true },
  globals: { theme: "dark" },
};
export const ZonesEmpty: Story = {
  args: { initialPage: "zones", empty: true },
};
export const History: Story = { args: { initialPage: "history" } };
export const HistoryDark: Story = {
  args: { initialPage: "history", dark: true },
  globals: { theme: "dark" },
};
export const HistoryEmpty: Story = {
  args: { initialPage: "history", empty: true },
};
export const PrivateAppointment: Story = { args: { initialSheet: "private" } };
export const TransportChange: Story = { args: { initialSheet: "transport" } };
export const HolidayImport: Story = { args: { initialSheet: "holidays" } };
export const ZoneEditor: Story = {
  args: { initialPage: "zones", initialSheet: "zone" },
};
export const HistoryDetail: Story = {
  args: { initialPage: "history", initialSheet: "history" },
};
export const HistoricalPreview: Story = {
  args: { initialPage: "history", initialSheet: "historyPreview" },
};
export const UndoConfirmation: Story = {
  args: { initialPage: "history", initialSheet: "undo" },
};
