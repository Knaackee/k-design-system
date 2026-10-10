import type { Meta, StoryObj } from "@storybook/react-vite";
import { WebSearchFixture } from "./web-search-fixture.js";

const meta = {
  title: "Patterns/AgentUI/Web search",
  component: WebSearchFixture,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof WebSearchFixture>;
export default meta;
type Story = StoryObj<typeof meta>;

export const Review: Story = {
  args: { variant: "review" },
  parameters: { fixtureId: "web-search-review" },
};
export const Running: Story = {
  args: { variant: "running" },
  parameters: { fixtureId: "web-search-running" },
};
export const AnimatedLoading: Story = {
  args: { variant: "animated-loading" },
  parameters: { fixtureId: "web-search-animated-loading" },
};
export const Empty: Story = {
  args: { variant: "empty" },
  parameters: { fixtureId: "web-search-empty" },
};
export const Error: Story = {
  args: { variant: "error" },
  parameters: { fixtureId: "web-search-error" },
};
export const Mobile: Story = {
  args: { variant: "mobile" },
  parameters: { fixtureId: "web-search-mobile" },
};
