import type { Meta, StoryObj } from "@storybook/react-vite";
import { KCard, KInline, KStack, KText } from "@k-design-system/ui";

const meta = {
  title: "Primitives/Layout",
  parameters: { fixtureId: "layout-composition" },
} satisfies Meta;
export default meta;
type Story = StoryObj<typeof meta>;

export const Composition: Story = {
  render: () => (
    <KInline wrap gap="section" className="k-fixture-grid">
      <KCard>
        <KStack gap="section">
          <KText variant="heading4">Shared composition</KText>
          <KInline wrap gap="action">
            <KText>First</KText>
            <KText>Second</KText>
            <KText>Third</KText>
          </KInline>
          <KText variant="bodySmall">
            Density updates every semantic gap without replacing children.
          </KText>
        </KStack>
      </KCard>
    </KInline>
  ),
};
