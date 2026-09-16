import type { Meta, StoryObj } from "@storybook/react-vite";
import { KContainer, KCard, KStack, KText } from "@k-design-system/ui";
const meta = {
  title: "Primitives/Container",
  parameters: { fixtureId: "container-bounds" },
} satisfies Meta;
export default meta;
type Story = StoryObj<typeof meta>;
export const Bounds: Story = {
  render: () => (
    <div className="k-primitive-fixture">
      <KContainer>
        <KStack align="stretch" gap="section">
          <KText variant="heading4">Contained content</KText>
          <KCard>
            <KText>Centered content with shared gutters.</KText>
          </KCard>
        </KStack>
      </KContainer>
    </div>
  ),
};
