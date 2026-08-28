import type { Meta, StoryObj } from "@storybook/react-vite";
import { KButton, KCard, KText } from "@k-design-system/ui";

const meta = {
  title: "Primitives/Card",
  component: KCard,
  tags: ["autodocs"],
  args: { children: "Card" },
  parameters: { fixtureId: "card-variants" },
} satisfies Meta<typeof KCard>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Variants: Story = {
  render: () => (
    <div className="k-card-grid">
      <KCard className="k-card-sample">
        <KText variant="heading4">Project settings</KText>
        <KText variant="bodySmall">
          Default cards use a fine border and no shadow.
        </KText>
        <KButton variant="secondary">Configure</KButton>
      </KCard>
      <KCard className="k-card-sample" tone="subtle">
        <KText variant="heading4">Quiet grouping</KText>
        <KText variant="bodySmall">
          Subtle tone separates content without added depth.
        </KText>
        <KButton variant="ghost">View details</KButton>
      </KCard>
    </div>
  ),
};
