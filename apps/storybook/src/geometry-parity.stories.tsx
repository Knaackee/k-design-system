import type { Meta, StoryObj } from "@storybook/react-vite";
import { GeometryParityFixture } from "./geometry-parity-fixture";

const meta = {
  title: "Review/GeometryParity",
  component: GeometryParityFixture,
} satisfies Meta<typeof GeometryParityFixture>;

export default meta;

/** Fixture ID matches Widgetbook `review/geometryparity/reference`. */
export const Reference: StoryObj<typeof meta> = {
  name: "reference",
};
