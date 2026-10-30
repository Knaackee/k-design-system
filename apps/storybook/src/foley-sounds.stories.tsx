import type { Meta, StoryObj } from "@storybook/react-vite";
import { FoleySoundsFixture } from "./foley-sounds-fixture.js";
import { SoundOnboardingFixture } from "./sound-onboarding-fixture.js";

export default {
  title: "Patterns/FoleySounds",
  component: FoleySoundsFixture,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof FoleySoundsFixture>;

export const Review: StoryObj<typeof FoleySoundsFixture> = {
  name: "foley-sounds-review",
  parameters: { fixtureId: "foley-sounds-review" },
};

export const Onboarding: StoryObj = {
  name: "sound-onboarding",
  parameters: { fixtureId: "sound-onboarding" },
  render: () => <SoundOnboardingFixture />,
};
