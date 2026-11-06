import type { Meta, StoryObj } from "@storybook/react-vite";
import { OnboardingFixture } from "./core-components-fixtures";

export default {
  title: "Navigation/Onboarding",
  parameters: { layout: "fullscreen" },
} satisfies Meta;

export const Review: StoryObj = {
  name: "onboarding",
  parameters: { fixtureId: "onboarding" },
  render: () => <OnboardingFixture />,
};
