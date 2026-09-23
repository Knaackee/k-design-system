import type { Meta, StoryObj } from "@storybook/react-vite";
import { CarouselFixture } from "./basic-component-fixtures.js";
const meta = {
  title: "Data display/Carousel",
  component: CarouselFixture,
} satisfies Meta<typeof CarouselFixture>;
export default meta;
export const Slides: StoryObj<typeof meta> = {
  name: "carousel-slides",
  parameters: { fixtureId: "carousel-slides" },
};
