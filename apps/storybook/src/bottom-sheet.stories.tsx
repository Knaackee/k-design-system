import type { Meta } from "@storybook/react-vite";
import { OverlayFixture } from "./overlay-fixture.js";

const meta = {
  title: "Overlays/BottomSheet",
  component: OverlayFixture,
} satisfies Meta<typeof OverlayFixture>;
export default meta;
export const Modal = {
  name: "bottom-sheet-modal",
  parameters: { fixtureId: "bottom-sheet-modal" },
  render: () => <OverlayFixture sheet />,
};
