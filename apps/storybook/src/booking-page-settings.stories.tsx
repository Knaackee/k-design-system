import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KBookingPageLayout,
  KBookingPageActions,
  KButton,
  KIcon,
  KBookingThemePicker,
  KColorSwatches,
  KList,
  KListItem,
  KSegmentedControl,
  KStack,
} from "@k-design-system/ui";
function SettingsControls() {
  const [theme, setTheme] = useState("2");
  const [color, setColor] = useState(
    "var(--k-color-action-primary-background)",
  );
  const [shape, setShape] = useState("square");
  return (
    <div style={{ containerType: "inline-size" }}>
      <KBookingPageLayout
        presentation="settings"
        previewTitle="Live-Vorschau"
        preview={<p>Preview: {theme}</p>}
      >
        <KStack gap="section" align="stretch">
          <KList><KListItem title="Online" description="example.test/u/business"/><KBookingPageActions previewAction={<KButton fullWidth variant="secondary"><KIcon name="eye"/>Vorschau</KButton>}>
            <KButton fullWidth><KIcon name="share"/>Teilen</KButton>
            <KButton fullWidth variant="secondary"><KIcon name="copy"/>Kopieren</KButton>
            <KButton fullWidth variant="secondary"><KIcon name="qr-code"/>QR-Code</KButton>
          </KBookingPageActions></KList>
          <KBookingThemePicker
            layout="carousel"
            value={theme}
            onChange={setTheme}
            options={[
              "clear",
              "editorial",
              "handwritten",
              "bold",
              "soft",
              "natural",
              "immersive",
              "night",
              "postcard",
              "bento",
              "monogram",
            ].map((id, index) => ({
              id: String(index),
              label: id,
              image: `/booking-themes/${id}.webp`,
            }))}
            footer={
              <KColorSwatches
                label="Farbe"
                value={color}
                onValueChange={setColor}
                options={[
                  {
                    value: "var(--k-color-action-primary-background)",
                    label: "Marke",
                  },
                  {
                    value: "var(--k-color-status-error-foreground)",
                    label: "Rot",
                  },
                ]}
              />
            }
          />
          <KList title="Bilder">
            <KListItem
              title="Bildform"
              trailing={
                <KSegmentedControl
                  label="Bildform"
                  showLabels={false}
                  value={shape}
                  onValueChange={setShape}
                  segments={[
                    { value: "square", label: "Eckig", icon: "square" },
                    { value: "round", label: "Rund", icon: "circle" },
                  ]}
                />
              }
            />
          </KList>
        </KStack>
      </KBookingPageLayout>
    </div>
  );
}
const meta = {
  title: "Patterns/BookingPageSettings",
  component: SettingsControls,
  parameters: { layout: "padded" },
} satisfies Meta<typeof SettingsControls>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Review: Story = {};
