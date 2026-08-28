import type { Meta, StoryObj } from "@storybook/react-vite";
import { KSurface, KText, type KSurfaceRadius } from "@k-design-system/ui";

const meta = {
  title: "Primitives/Shape",
  parameters: { fixtureId: "shape-radius-scale" },
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

const radii: Array<[KSurfaceRadius, string]> = [
  ["none", "None · 0"],
  ["small", "Small · 4"],
  ["medium", "Medium · 6"],
  ["large", "Large · 8"],
  ["extraLarge", "Extra large · 12"],
  ["full", "Full"],
];

export const RadiusScale: Story = {
  render: () => (
    <div className="k-shape-grid">
      {radii.map(([radius, label]) => (
        <div className="k-foundation-swatch" key={radius}>
          <KSurface className="k-radius-sample" radius={radius} />
          <KText variant="caption">{label}</KText>
        </div>
      ))}
    </div>
  ),
};
