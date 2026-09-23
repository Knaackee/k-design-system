import type { Meta, StoryObj } from "@storybook/react-vite";
import { SliderFixture } from "./extended-component-fixtures.js";
export default {
  title: "Forms/Slider",
  component: SliderFixture,
} satisfies Meta<typeof SliderFixture>;
export const Range: StoryObj<typeof SliderFixture> = {
  name: "slider-range",
  parameters: { fixtureId: "slider-range" },
};
