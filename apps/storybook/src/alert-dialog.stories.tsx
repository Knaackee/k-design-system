import type { Meta, StoryObj } from "@storybook/react-vite";
import { AlertDialogFixture } from "./basic-component-fixtures.js";
const meta = {
  title: "Overlays/AlertDialog",
  component: AlertDialogFixture,
} satisfies Meta<typeof AlertDialogFixture>;
export default meta;
export const Confirmation: StoryObj<typeof meta> = {
  name: "alert-dialog-confirmation",
  parameters: { fixtureId: "alert-dialog-confirmation" },
};
