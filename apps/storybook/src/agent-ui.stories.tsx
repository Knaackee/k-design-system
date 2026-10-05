import type { Meta, StoryObj } from "@storybook/react-vite";
import { AgentUiFixture } from "./agent-ui-fixture.js";
import { AgentQuestionDictationFixture } from "./agent-question-dictation-fixture.js";

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

export const TextQuestion: Story = {
  name: "agent-ui-text-question",
  args: { kind: "text-question" },
  parameters: { fixtureId: "agent-ui-text-question" },
};

export const TextQuestionDictation: Story = {
  name: "agent-ui-text-question-dictation",
  render: () => <AgentQuestionDictationFixture />,
  parameters: { fixtureId: "agent-ui-text-question-dictation" },
};

export const MultipleChoice: Story = {
  name: "agent-ui-multiple-choice",
  args: { kind: "multiple-choice" },
  parameters: { fixtureId: "agent-ui-multiple-choice" },
};

export const Confirmation: Story = {
  name: "agent-ui-confirmation",
  args: { kind: "confirmation" },
  parameters: { fixtureId: "agent-ui-confirmation" },
};

export const Form: Story = {
  name: "agent-ui-form",
  args: { kind: "form" },
  parameters: { fixtureId: "agent-ui-form" },
};

export const ExternalAction: Story = {
  name: "agent-ui-external-action",
  args: { kind: "external-action" },
  parameters: { fixtureId: "agent-ui-external-action" },
};

export const AttachmentRequest: Story = {
  name: "agent-ui-attachment-request",
  args: { kind: "attachment-request" },
  parameters: { fixtureId: "agent-ui-attachment-request" },
};

export const AskTools: Story = {
  name: "agent-ui-ask-tools",
  args: { kind: "ask-tools" },
  parameters: { fixtureId: "agent-ui-ask-tools" },
};
