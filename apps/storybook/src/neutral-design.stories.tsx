import type { Meta, StoryObj } from "@storybook/react-vite";
import { KButton, KInline, KStack, KText } from "@k-design-system/ui";
import { OverlayFixture } from "./overlay-fixture.js";
import { SettingsPageFixture } from "./settings-page-fixture.js";

const meta = {
  title: "Patterns/NeutralDesign",
  parameters: { layout: "fullscreen" },
} satisfies Meta;
export default meta;
type Story = StoryObj<typeof meta>;

export const ControlsAndDialog: Story = {
  name: "Buttons und Dialog",
  render: () => (
    <KStack gap="section" className="k-foundation-preview">
      <KStack>
        <KText variant="heading3">Ruhige Flächen. Klare Aktionen.</KText>
        <KText>
          Neutrale Aktionsfarben und Radien von 6, 8 und 12 px. Über die Toolbar
          zwischen Hell und Dunkel wechseln.
        </KText>
      </KStack>
      <KInline wrap align="center">
        <KButton variant="secondary">Standardaktion</KButton>
        <KButton variant="primary">Änderungen speichern</KButton>
        <KButton variant="ghost">Abbrechen</KButton>
      </KInline>
      <KInline wrap align="center">
        <KButton variant="primary" disabled>
          Nicht verfügbar
        </KButton>
        <KButton variant="primary" loading>
          Wird gespeichert
        </KButton>
      </KInline>
      <OverlayFixture />
    </KStack>
  ),
};

export const Settings: Story = {
  name: "Einstellungen",
  render: () => <SettingsPageFixture />,
};
