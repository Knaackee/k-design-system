import type { Meta, StoryObj } from "@storybook/react-vite";
import { KBreadcrumb, KText } from "@k-design-system/ui";
import { BreadcrumbFixture } from "./basic-component-fixtures.js";
const meta = {
  title: "Navigation/Breadcrumb",
  component: BreadcrumbFixture,
} satisfies Meta<typeof BreadcrumbFixture>;
export default meta;
export const Navigation: StoryObj<typeof meta> = {
  name: "breadcrumb-navigation",
  parameters: { fixtureId: "breadcrumb-navigation" },
};

export const Responsive: StoryObj<typeof meta> = {
  name: "breadcrumb-responsive",
  parameters: { fixtureId: "breadcrumb-responsive" },
  render: () => (
    <div
      style={{
        display: "grid",
        gap: "var(--k-space-layout-section-gap)",
        width: "100%",
      }}
    >
      {[320, 520, 840].map((width) => (
        <section
          key={width}
          data-testid={`breadcrumb-${width}`}
          style={{ width, maxWidth: "100%" }}
        >
          <KText variant="caption">{width}px</KText>
          <KBreadcrumb
            label="Navigation"
            overflowLabel="Übergeordnete Seiten"
            items={[
              {
                id: "home",
                label: <span>Home</span>,
                icon: "house",
                href: "#home",
              },
              { id: "settings", label: "Einstellungen", href: "#settings" },
              {
                id: "admin",
                label: "Administration",
                onSelect: () => {
                  location.hash = "admin";
                },
              },
              {
                id: "current",
                label:
                  "Eine sehr lange aktuelle Seite – clients, entreprises et administration",
              },
            ]}
          />
        </section>
      ))}
    </div>
  ),
};
