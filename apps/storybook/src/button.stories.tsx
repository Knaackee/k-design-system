import type { Meta, StoryObj } from "@storybook/react-vite";
import { KButton } from "@k-design-system/ui";

const meta = {
  title: "Primitives/Button",
  component: KButton,
  tags: ["autodocs"],
  args: {
    children: "Continue",
    variant: "primary",
  },
  argTypes: {
    variant: {
      control: "select",
      options: ["primary", "secondary", "ghost"],
    },
  },
  parameters: {
    fixtureId: "button-primary",
  },
} satisfies Meta<typeof KButton>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Primary: Story = {};

export const Variants: Story = {
  parameters: {
    fixtureId: "button-variants",
  },
  render: () => (
    <div className="k-button-grid">
      <KButton variant="primary">Create issue</KButton>
      <KButton variant="secondary">Cancel</KButton>
      <KButton variant="ghost">Dismiss</KButton>
    </div>
  ),
};

export const States: Story = {
  parameters: {
    fixtureId: "button-states",
  },
  render: () => (
    <div className="k-foundation-preview">
      <div className="k-foundation-preview__copy">
        <h2>Adaptive foundation</h2>
        <p>
          Compare density, typography, presentation, input target and window
          spacing with the toolbar controls.
        </p>
      </div>
      <div className="k-button-state-grid">
        {(["primary", "secondary", "ghost"] as const).map((variant) => (
          <section className="k-button-state-row" key={variant}>
            <span>{variant}</span>
            <KButton variant={variant}>Continue</KButton>
            <KButton variant={variant} disabled>
              Disabled
            </KButton>
            <KButton variant={variant} loading>
              Saving
            </KButton>
          </section>
        ))}
      </div>
    </div>
  ),
};
