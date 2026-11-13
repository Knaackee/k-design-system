import { useState } from "react";
import {
  KButton,
  KIcon,
  KDialog,
  KList,
  KListItem,
  KMenuButton,
} from "@k-design-system/ui";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { OfferOverview } from "./offer-overview-fixture.js";
const meta = {
  title: "Patterns/OfferOverview",
  component: OfferOverview,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof OfferOverview>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Overview: Story = {};
export const Dark: Story = { globals: { theme: "dark" } };
export const Services: Story = { args: { initialFilter: "service" } };
export const Products: Story = { args: { initialFilter: "product" } };
export const Archived: Story = { args: { initialFilter: "archive" } };
export const Empty: Story = { args: { empty: true } };
const phone = {
  parameters: {
    viewport: {
      options: {
        phone: {
          name: "Phone · 390 × 844",
          styles: { width: "390px", height: "844px" },
        },
      },
    },
  },
  globals: {
    viewport: { value: "phone", isRotated: false },
    inputMode: "touch",
  },
};
export const Mobile: Story = { ...phone };
export const MobileDark: Story = {
  ...phone,
  globals: { ...phone.globals, theme: "dark" },
};

const quickCreateOptions = [
  ["Termin", "calendar"],
  ["Kund:in", "users"],
  ["Leistung", "clock"],
  ["Produkt", "package"],
  ["Privater Termin", "lock"],
] as const;

function QuickCreateReview({ mobile = false }: { mobile?: boolean }) {
  const [open, setOpen] = useState(false);
  const [selected, setSelected] = useState("");
  return (
    <>
      <OfferOverview
        headerAction={
          mobile ? (
            <KButton aria-label="Neu erstellen" onClick={() => setOpen(true)}>
              <KIcon name="plus" />
            </KButton>
          ) : (
            <KMenuButton
              label="Neu erstellen"
              triggerContent={<KIcon name="plus" />}
              actions={quickCreateOptions.map(([label, icon]) => ({
                id: label,
                label,
                icon,
                onSelect: () => setSelected(label),
              }))}
            />
          )
        }
      />
      <KDialog
        open={open}
        onOpenChange={setOpen}
        title="Neu erstellen"
        description="UI-Vorschau ohne Speicherung"
      >
        <KList>
          {quickCreateOptions.map(([label, icon]) => (
            <KListItem
              key={label}
              title={label}
              leadingIcon={icon}
              onClick={() => {
                setSelected(label);
                setOpen(false);
              }}
            />
          ))}
        </KList>
      </KDialog>
      <output aria-live="polite">
        {selected && `${selected} ausgewählt · UI-Vorschau`}
      </output>
    </>
  );
}
export const QuickCreate: Story = { render: () => <QuickCreateReview /> };
export const QuickCreateMobile: Story = {
  ...phone,
  render: () => <QuickCreateReview mobile />,
};
