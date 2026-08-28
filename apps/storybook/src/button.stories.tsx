import type { Meta, StoryObj } from "@storybook/react-vite";
import { KButton } from "@k-design-system/ui";

const meta = {
  title: "Primitives/Button",
  component: KButton,
  tags: ["autodocs"],
  args: {
    children: "Continue",
  },
  parameters: {
    fixtureId: "button-primary",
  },
} satisfies Meta<typeof KButton>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Primary: Story = {};

export const States: Story = {
  parameters: {
    fixtureId: "button-states",
  },
  render: () => (
    <div className="k-button-grid">
      <KButton>Continue</KButton>
      <KButton disabled>Disabled</KButton>
      <KButton loading>Saving</KButton>
    </div>
  ),
};
