import type { Meta, StoryObj } from "@storybook/react-vite";
import { AgentChatWorkspaceFixture } from "./agent-chat-workspace-fixture.js";

const meta = {
  title: "Patterns/AgentChatWorkspace",
  component: AgentChatWorkspaceFixture,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof AgentChatWorkspaceFixture>;

export default meta;
type Story = StoryObj<typeof meta>;

export const EmptySession: Story = {
  name: "Chat & Anruf – interaktiv",
  args: { variant: "empty" },
  parameters: { fixtureId: "agent-chat-workspace-empty-session" },
};
