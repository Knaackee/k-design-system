import type { Meta, StoryObj } from "@storybook/react-vite";
import { SnackbarFixture } from "./notification-fixture.js";
export default {
  title: "Feedback/Snackbar",
  component: SnackbarFixture,
} satisfies Meta<typeof SnackbarFixture>;
export const Message: StoryObj<typeof SnackbarFixture> = {
  name: "snackbar-message",
  parameters: { fixtureId: "snackbar-message" },
};
