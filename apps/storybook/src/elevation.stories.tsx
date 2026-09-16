import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KSurface,
  KText,
  KStack,
  KInline,
  type KSurfaceElevation,
} from "@k-design-system/ui";

const meta = {
  title: "Primitives/Elevation",
  parameters: { fixtureId: "elevation-levels" },
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

const levels: Array<[KSurfaceElevation, string, string]> = [
  ["none", "None", "Default cards and in-flow surfaces"],
  ["low", "Low", "Floating utility controls"],
  ["medium", "Medium", "Menus and popovers"],
  ["overlay", "Overlay", "Dialogs and modal layers"],
];

export const Levels: Story = {
  render: () => (
    <KInline wrap gap="section" className="k-fixture-grid">
      {levels.map(([elevation, name, purpose]) => (
        <KSurface
          border={elevation === "none" ? "default" : "none"}
          className="k-elevation-sample"
          elevation={elevation}
          key={elevation}
          radius={elevation === "overlay" ? "overlay" : "medium"}
        >
          <KStack>
            <KText variant="label">{name}</KText>
            <KText variant="bodySmall">{purpose}</KText>
          </KStack>
        </KSurface>
      ))}
    </KInline>
  ),
};
