import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KContainer,
  KSeparator,
  KInline,
  KStack,
  KText,
} from "@k-design-system/ui";
const meta = {
  title: "Primitives/Separator",
  parameters: { fixtureId: "separator-orientations" },
} satisfies Meta;
export default meta;
type Story = StoryObj<typeof meta>;
export const Orientations: Story = {
  render: () => (
    <div className="k-primitive-fixture">
      <KContainer>
        <KStack align="stretch" gap="section">
          <KText variant="heading4">Separators</KText>
          <KText>Above the line</KText>
          <KSeparator />
          <KInline gap="section" align="center">
            <KText>First</KText>
            <KSeparator orientation="vertical" length={48} />
            <KText>Second</KText>
          </KInline>
          <KSeparator length={120} />
          <KText>Below the line</KText>
        </KStack>
      </KContainer>
    </div>
  ),
};
