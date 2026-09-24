import type { Meta, StoryObj } from "@storybook/react-vite";
import { WorkflowFixture } from "./workflow-fixture.js";

const meta = {
  title: "Patterns/Workflow",
  component: WorkflowFixture,
  parameters: { layout: "fullscreen" },
  argTypes: {
    presentation: {
      control: "inline-radio",
      options: ["auto", "detailed", "compact"],
    },
    showTechnicalEventsInCompact: { control: "boolean" },
  },
} satisfies Meta<typeof WorkflowFixture>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Responsive: Story = {
  name: "workflow-responsive",
  args: {
    presentation: "auto",
    showTechnicalEventsInCompact: false,
  },
  parameters: { fixtureId: "workflow-responsive" },
};
