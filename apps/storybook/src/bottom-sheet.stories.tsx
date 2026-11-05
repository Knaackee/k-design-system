import type { Meta } from "@storybook/react-vite";
import { OverlayFixture } from "./overlay-fixture.js";
import { CompactSheetFixture } from "./compact-sheet-fixture.js";

const meta = {
  title: "Overlays/BottomSheet",
  component: OverlayFixture,
} satisfies Meta<typeof OverlayFixture>;
export default meta;
export const CompactFixedActions = {
  name: "compact-sheet-fixed-actions",
  parameters: { fixtureId: "compact-sheet-fixed-actions" },
  render: () => <CompactSheetFixture />,
};
export const Modal = {
  name: "bottom-sheet-modal",
  parameters: { fixtureId: "bottom-sheet-modal" },
  render: () => <OverlayFixture sheet />,
};

import { SheetScrollHandoffFixture } from "./sheet-scroll-handoff-fixture.js";
export const ScrollHandoff = {
  name: "bottom-sheet-scroll-handoff",
  parameters: { fixtureId: "bottom-sheet-scroll-handoff" },
  render: () => <SheetScrollHandoffFixture />,
};
