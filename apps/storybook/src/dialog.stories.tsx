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
