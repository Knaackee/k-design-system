import type { Meta, StoryObj } from "@storybook/react-vite";
import { KButton, KInline, KStack, KText } from "@k-design-system/ui";

const meta = {
  title: "Primitives/Button",
  component: KButton,
  tags: ["autodocs"],
  args: { children: "Continue", variant: "primary" },
  argTypes: {
    variant: { control: "select", options: ["primary", "secondary", "ghost"] },
  },
  parameters: { fixtureId: "button-primary" },
} satisfies Meta<typeof KButton>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Primary: Story = {};
export const Variants: Story = {
  parameters: { fixtureId: "button-variants" },
  render: () => (
    <KInline wrap align="center">
      <KButton>Create issue</KButton>
      <KButton variant="secondary">Cancel</KButton>
      <KButton variant="ghost">Dismiss</KButton>
    </KInline>
  ),
};
export const States: Story = {
  parameters: { fixtureId: "button-states" },
  render: () => (
    <KStack gap="section" className="k-foundation-preview">
      <KStack className="k-foundation-preview__copy">
        <KText variant="heading3">Adaptive foundation</KText>
        <KText>
          Compare density, typography, input target and window spacing with the
          controls.
        </KText>
      </KStack>
      <KStack>
        {(["primary", "secondary", "ghost"] as const).map((variant) => (
          <KInline
            wrap
            align="center"
            key={variant}
            className="k-button-state-row"
          >
            <KText variant="caption">{variant.toUpperCase()}</KText>
            <KButton variant={variant}>Continue</KButton>
            <KButton variant={variant} disabled>
              Disabled
            </KButton>
            <KButton variant={variant} loading>
              Saving
            </KButton>
          </KInline>
        ))}
      </KStack>
    </KStack>
  ),
};
