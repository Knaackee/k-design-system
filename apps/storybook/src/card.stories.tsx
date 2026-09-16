import type { Meta, StoryObj } from "@storybook/react-vite";
import { KButton, KCard, KInline, KStack, KText } from "@k-design-system/ui";

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
    <KInline wrap gap="section" className="k-fixture-grid">
      <KCard className="k-card-sample">
        <KStack gap="action">
          <KStack>
            <KText variant="heading4">Project settings</KText>
            <KText variant="bodySmall">
              Default cards use a fine border and no shadow.
            </KText>
          </KStack>
          <KButton variant="secondary">Configure</KButton>
        </KStack>
      </KCard>
      <KCard className="k-card-sample" tone="subtle">
        <KStack gap="action">
          <KStack>
            <KText variant="heading4">Quiet grouping</KText>
            <KText variant="bodySmall">
              Subtle tone separates content without added depth.
            </KText>
          </KStack>
          <KButton variant="ghost">View details</KButton>
        </KStack>
      </KCard>
    </KInline>
  ),
};
