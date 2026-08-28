import type { Meta, StoryObj } from "@storybook/react-vite";
import { KSurface, KText } from "@k-design-system/ui";

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
    <div className="k-surface-grid">
      <KSurface className="k-surface-sample" tone="canvas">
        <KText variant="label">Canvas</KText>
        <KText variant="bodySmall">Application background</KText>
      </KSurface>
      <KSurface className="k-surface-sample" tone="raised">
        <KText variant="label">Raised</KText>
        <KText variant="bodySmall">Cards and panels</KText>
      </KSurface>
      <KSurface className="k-surface-sample" tone="subtle">
        <KText variant="label">Subtle</KText>
        <KText variant="bodySmall">Quiet grouping and selection</KText>
      </KSurface>
    </div>
  ),
};
