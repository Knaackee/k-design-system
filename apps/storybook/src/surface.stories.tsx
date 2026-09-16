import type { Meta, StoryObj } from "@storybook/react-vite";
import { KSurface, KText, KStack, KInline } from "@k-design-system/ui";

const meta = {
  title: "Primitives/Surface",
  component: KSurface,
  tags: ["autodocs"],
  args: { children: "Surface", tone: "raised" },
  parameters: { fixtureId: "surface-tones" },
} satisfies Meta<typeof KSurface>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Tones: Story = {
  render: () => (
    <KInline wrap gap="section" className="k-fixture-grid">
      <KSurface className="k-surface-sample" tone="canvas">
        <KStack>
          <KText variant="label">Canvas</KText>
          <KText variant="bodySmall">Application background</KText>
        </KStack>
      </KSurface>
      <KSurface className="k-surface-sample" tone="raised">
        <KStack>
          <KText variant="label">Raised</KText>
          <KText variant="bodySmall">Cards and panels</KText>
        </KStack>
      </KSurface>
      <KSurface className="k-surface-sample" tone="subtle">
        <KStack>
          <KText variant="label">Subtle</KText>
          <KText variant="bodySmall">Quiet grouping and selection</KText>
        </KStack>
      </KSurface>
    </KInline>
  ),
};
