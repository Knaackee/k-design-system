import type { Meta, StoryObj } from "@storybook/react-vite";
import { AppOverhaulFixture } from "./app-overhaul-fixture.js";
const meta = {
  title: "Review/AppOverhaul/Arbeitsalltag",
  component: AppOverhaulFixture,
  render: (args, context) => (
    <AppOverhaulFixture
      {...args}
      dark={args.dark || context.globals.theme === "dark"}
    />
  ),
  parameters: { layout: "fullscreen" },
  args: { initialScreen: "home", empty: false, dark: false },
  argTypes: {
    initialScreen: {
      control: "select",
      options: [
        "home",
        "day",
        "calendar",
        "bookings",
        "inbox",
        "customers",
        "assistant",
      ],
    },
  },
} satisfies Meta<typeof AppOverhaulFixture>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Heute: Story = {};
export const HeuteLeer: Story = { args: { empty: true } };
export const HeuteDark: Story = {
  args: { dark: true },
  globals: { theme: "dark" },
};
export const MeinTag: Story = { args: { initialScreen: "day" } };
export const MeinTagLeer: Story = {
  args: { initialScreen: "day", empty: true },
};
export const TagAnpassen: Story = {
  args: { initialScreen: "day", initialOverlay: "day" },
};
export const Kalender: Story = { args: { initialScreen: "calendar" } };
export const KalenderLeer: Story = {
  args: { initialScreen: "calendar", empty: true },
};
export const Buchungen: Story = { args: { initialScreen: "bookings" } };
export const BuchungenLeer: Story = {
  args: { initialScreen: "bookings", empty: true },
};
export const Buchungsdetails: Story = {
  args: { initialScreen: "bookings", initialOverlay: "booking" },
};
export const Buchungszahlung: Story = {
  args: { initialScreen: "bookings", initialOverlay: "payment" },
};
export const BuchungAbsagen: Story = {
  args: { initialScreen: "bookings", initialOverlay: "cancel" },
};
export const Posteingang: Story = { args: { initialScreen: "inbox" } };
export const PosteingangLeer: Story = {
  args: { initialScreen: "inbox", empty: true },
};
export const Kunden: Story = { args: { initialScreen: "customers" } };
export const KundenLeer: Story = {
  args: { initialScreen: "customers", empty: true },
};
export const Kundendetails: Story = {
  args: { initialScreen: "customers", initialOverlay: "customer" },
};
export const KundeBearbeiten: Story = {
  args: { initialScreen: "customers", initialOverlay: "editCustomer" },
};
export const KundeLoeschen: Story = {
  args: { initialScreen: "customers", initialOverlay: "deleteCustomer" },
};
export const Fotoauswahl: Story = {
  args: { initialScreen: "customers", initialOverlay: "photo" },
};
export const Assistent: Story = { args: { initialScreen: "assistant" } };
export const AssistentLeer: Story = {
  args: { initialScreen: "assistant", empty: true },
};
