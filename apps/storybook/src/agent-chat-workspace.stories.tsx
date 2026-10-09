import type { Meta, StoryObj } from "@storybook/react-vite";
import { AgentChatWorkspaceFixture } from "./agent-chat-workspace-fixture.js";

const meta = {
  title: "Patterns/AgentChatWorkspace",
  component: AgentChatWorkspaceFixture,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof AgentChatWorkspaceFixture>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Fullscreen: Story = {
  args: { variant: "fullscreen" },
  parameters: { fixtureId: "agent-chat-workspace-fullscreen" },
};

export const NeedsInput: Story = {
  args: { variant: "needs-input" },
  parameters: { fixtureId: "agent-chat-workspace-needs-input" },
};

export const Offline: Story = {
  args: { variant: "offline" },
  parameters: { fixtureId: "agent-chat-workspace-offline" },
};

export const Mobile: Story = {
  args: { variant: "mobile" },
  parameters: {
    fixtureId: "agent-chat-workspace-mobile",
    viewport: { defaultViewport: "mobile1" },
  },
};
