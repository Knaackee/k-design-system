import type { Meta, StoryObj } from "@storybook/react-vite";
import { ToastFixture } from "./notification-fixture.js";
export default {
  title: "Feedback/Toast",
  component: ToastFixture,
} satisfies Meta<typeof ToastFixture>;
export const Notification: StoryObj<typeof ToastFixture> = {
  name: "toast-notification",
  parameters: { fixtureId: "toast-notification" },
};
