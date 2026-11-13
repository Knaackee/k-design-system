import type { Meta, StoryObj } from "@storybook/react-vite";
import { AgentEmailDraftFixture } from "./agent-email-draft-fixture.js";

const meta = {
  title: "Patterns/AgentUI/Email draft",
  component: AgentEmailDraftFixture,
  parameters: { layout: "fullscreen" },
  args: { scenario: "pending", border: "aurora", toolbar: false },
  argTypes: {
    scenario: {
      control: "select",
      options: ["pending", "validation", "submitting", "sent", "discarded"],
    },
    border: { control: "inline-radio", options: ["none", "aurora"] },
    toolbar: { control: "boolean" },
  },
} satisfies Meta<typeof AgentEmailDraftFixture>;
export default meta;
type Story = StoryObj<typeof meta>;

export const Review: Story = {
  name: "agent-email-draft",
  parameters: { fixtureId: "agent-email-draft" },
};
export const Validation: Story = {
  args: { scenario: "validation" },
  parameters: { fixtureId: "agent-email-draft-validation" },
};
export const Sending: Story = {
  args: { scenario: "submitting" },
  parameters: { fixtureId: "agent-email-draft-sending" },
};
export const Sent: Story = {
  args: { scenario: "sent" },
  parameters: { fixtureId: "agent-email-draft-sent" },
};
export const Discarded: Story = {
  args: { scenario: "discarded" },
  parameters: { fixtureId: "agent-email-draft-discarded" },
};
