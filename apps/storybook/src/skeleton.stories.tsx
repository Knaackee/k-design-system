import type { Meta, StoryObj } from "@storybook/react-vite";
import { SkeletonFixture } from "./extended-component-fixtures.js";
export default {
  title: "Feedback/Skeleton",
  component: SkeletonFixture,
} satisfies Meta<typeof SkeletonFixture>;
export const Loading: StoryObj<typeof SkeletonFixture> = {
  name: "skeleton-loading",
  parameters: { fixtureId: "skeleton-loading" },
};
