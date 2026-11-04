import type { Meta, StoryObj } from "@storybook/react-vite";
import { OfferOverview } from "./offer-overview-fixture.js";
const meta = {
  title: "Patterns/OfferOverview",
  component: OfferOverview,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof OfferOverview>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Overview: Story = {};
export const Dark: Story = { globals: { theme: "dark" } };
export const Services: Story = { args: { initialFilter: "service" } };
export const Products: Story = { args: { initialFilter: "product" } };
export const Archived: Story = { args: { initialFilter: "archive" } };
export const Empty: Story = { args: { empty: true } };
const phone = {
  parameters: {
    viewport: {
      options: {
        phone: {
          name: "Phone · 390 × 844",
          styles: { width: "390px", height: "844px" },
        },
      },
    },
  },
  globals: {
    viewport: { value: "phone", isRotated: false },
    inputMode: "touch",
  },
};
export const Mobile: Story = { ...phone };
export const MobileDark: Story = {
  ...phone,
  globals: { ...phone.globals, theme: "dark" },
};
