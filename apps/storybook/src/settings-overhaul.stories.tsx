import type { Meta, StoryObj } from "@storybook/react-vite";
import { SettingsOverhaul } from "./settings-overhaul-fixture.js";

const meta = {
  title: "Review/SettingsOverhaul",
  component: SettingsOverhaul,
  parameters: { layout: "fullscreen" },
  globals: { windowClass: "expanded" },
  args: { initialPage: "profile", empty: false, admin: true },
} satisfies Meta<typeof SettingsOverhaul>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Profile: Story = {};
export const ProfileDesktop: Story = { globals: { windowClass: "expanded" } };
export const ProfileMobile: Story = {
  globals: { windowClass: "compact" },
  decorators: [
    (Story) => (
      <div className="so-mobile-preview">
        <Story />
      </div>
    ),
  ],
};
export const Overview: Story = { args: { initialPage: "overview" } };
export const Appearance: Story = { args: { initialPage: "appearance" } };
export const Language: Story = { args: { initialPage: "language" } };
export const Payments: Story = { args: { initialPage: "payments" } };
export const PaymentsEmpty: Story = {
  args: { initialPage: "payments", empty: true },
};
export const Integrations: Story = { args: { initialPage: "integrations" } };
export const About: Story = { args: { initialPage: "about" } };
export const Access: Story = { args: { initialPage: "access" } };
export const AccessEmpty: Story = {
  args: { initialPage: "access", empty: true },
};
export const Assistant: Story = { args: { initialPage: "assistant" } };
export const Server: Story = { args: { initialPage: "server" } };
export const Password: Story = { args: { initialDialog: "Passwort ändern" } };
export const Logout: Story = { args: { initialDialog: "Abmelden?" } };
export const DeleteAccount: Story = {
  args: { initialDialog: "Konto löschen?" },
};
export const Update: Story = {
  args: { initialPage: "about", initialDialog: "Update verfügbar" },
};
export const ProfileDark: Story = { globals: { theme: "dark" } };
export const Member: Story = {
  args: { admin: false, initialPage: "overview" },
};

export const EditName: Story = { args: { initialDialog: "Name bearbeiten" } };
export const EditEmail: Story = { args: { initialDialog: "E-Mail ändern" } };
