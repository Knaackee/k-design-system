import type { Meta, StoryObj } from "@storybook/react-vite";
import { KContainer, KLink, KStack, KText } from "@k-design-system/ui";

const meta = {
  title: "Primitives/Link",
  parameters: { fixtureId: "link-variants" },
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const Variants: Story = {
  name: "link-variants",
  render: () => (
    <div className="k-primitive-fixture">
      <KContainer>
        <KStack align="start" gap="section">
          <KText variant="heading4">Links</KText>
          <KText>
            Read the <KLink href="#inline">component documentation</KLink> for
            details.
          </KText>
          <KLink href="#standalone" variant="standalone">
            Standalone action
          </KLink>
          <KLink href="https://example.com" external variant="standalone">
            External resource
          </KLink>
        </KStack>
      </KContainer>
    </div>
  ),
};
