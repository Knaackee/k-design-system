import type { Meta, StoryObj } from "@storybook/react-vite";
import { SettingsAppFixture } from "./settings-app-fixture.js";
import { OnboardingAppFixture } from "./onboarding-app-fixture.js";
const meta = {
  title: "App Shells/Settings App",
  component: SettingsAppFixture,
  parameters: { layout: "fullscreen" },
  args: { initialState: "ready" },
  argTypes: {
    initialState: { control: "select", options: ["ready", "loading", "error"] },
  },
} satisfies Meta<typeof SettingsAppFixture>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Workspace: Story = {
  parameters: { fixtureId: "settings-app-workspace" },
};
export const FormPage: Story = {
  args: { initialPage: "New project" },
  parameters: { fixtureId: "app-shell-form-page" },
};
export const ListDetail: Story = {
  args: { initialPage: "Projects" },
  parameters: { fixtureId: "app-shell-list-detail" },
};
export const Loading: Story = { args: { initialState: "loading" } };
export const Error: Story = { args: { initialState: "error" } };

export const Onboarding: Story = {
  render: () => <OnboardingAppFixture />,
  parameters: { fixtureId: "app-shell-onboarding" },
};
export const EmptyWorkspace: Story = {
  args: { emptyWorkspace: true },
  parameters: { fixtureId: "app-shell-empty-workspace" },
};
