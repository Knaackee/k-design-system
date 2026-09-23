import type { Meta, StoryObj } from "@storybook/react-vite";
import { SpinnerFixture } from "./extended-component-fixtures.js";
export default {
  title: "Feedback/Spinner",
  component: SpinnerFixture,
} satisfies Meta<typeof SpinnerFixture>;
export const Loading: StoryObj<typeof SpinnerFixture> = {
  name: "spinner-loading",
  parameters: { fixtureId: "spinner-loading" },
};
