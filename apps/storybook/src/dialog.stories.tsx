import type { Meta } from "@storybook/react-vite";
import { OverlayFixture } from "./overlay-fixture.js";

const meta = {
  title: "Overlays/Dialog",
  component: OverlayFixture,
} satisfies Meta<typeof OverlayFixture>;
export default meta;
export const Modal = {
  name: "dialog-modal",
  parameters: { fixtureId: "dialog-modal" },
  render: () => <OverlayFixture />,
};

export const Phone = {
  name: "adaptive-dialog-phone",
  globals: { viewport: { value: "mobile1", isRotated: false } },
  parameters: {
    fixtureId: "adaptive-dialog-phone",
    viewport: { defaultViewport: "mobile1" },
  },
  render: () => <OverlayFixture />,
};
export const Tablet = {
  name: "adaptive-dialog-tablet",
  globals: { viewport: { value: "tablet", isRotated: false } },
  parameters: {
    fixtureId: "adaptive-dialog-tablet",
    viewport: { defaultViewport: "tablet" },
  },
  render: () => <OverlayFixture />,
};
