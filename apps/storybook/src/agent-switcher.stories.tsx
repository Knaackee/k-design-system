import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  AgentSwitcherFixture,
  AgentSwitcherShowcaseFixture,
} from "./agent-switcher-fixture.js";

const meta = {
  title: "Patterns/AgentSwitcher",
  component: AgentSwitcherFixture,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof AgentSwitcherFixture>;

export default meta;
type Story = StoryObj<typeof meta>;

export const PersonalAgents: Story = {
  name: "agent-chat-switcher",
  parameters: { fixtureId: "agent-chat-switcher" },
};

export const CustomContent: StoryObj<typeof AgentSwitcherShowcaseFixture> = {
  name: "agent-switcher-custom-content",
  render: (args) => <AgentSwitcherShowcaseFixture {...args} />,
  args: {
    showConnections: true,
    showActivity: true,
    showUnread: true,
    customColors: true,
    reorderable: true,
  },
  parameters: { fixtureId: "agent-switcher-custom-content" },
};

export const Reorder: StoryObj<typeof AgentSwitcherShowcaseFixture> = {
  name: "agent-switcher-reorder",
  render: (args) => <AgentSwitcherShowcaseFixture {...args} />,
  args: {
    showConnections: true,
    showActivity: true,
    showUnread: true,
    customColors: true,
    reorderable: true,
  },
  parameters: { fixtureId: "agent-switcher-reorder" },
};
