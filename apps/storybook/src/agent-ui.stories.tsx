import type { Meta, StoryObj } from "@storybook/react-vite";
import { AgentUiFixture } from "./agent-ui-fixture.js";

const meta = {
  title: "Patterns/AgentUI",
  component: AgentUiFixture,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof AgentUiFixture>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Conversation: Story = {
  name: "agent-ui-conversation",
  args: { kind: "conversation" },
  parameters: { fixtureId: "agent-ui-conversation" },
};

export const Messages: Story = {
  name: "agent-ui-messages",
  args: {
    kind: "messages",
    metadataMode: "grouped",
    showTimestamps: true,
  },
  argTypes: {
    metadataMode: {
      control: "inline-radio",
      options: ["always", "grouped", "hidden"],
    },
    showTimestamps: { control: "boolean" },
  },
  parameters: { fixtureId: "agent-ui-messages" },
};

export const Tools: Story = {
  name: "agent-ui-tools",
  args: { kind: "tools" },
  parameters: { fixtureId: "agent-ui-tools" },
};

export const Approval: Story = {
  name: "agent-ui-approval",
  args: { kind: "approval" },
  parameters: { fixtureId: "agent-ui-approval" },
};

export const Question: Story = {
  name: "agent-ui-question",
  args: { kind: "question" },
  parameters: { fixtureId: "agent-ui-question" },
};
