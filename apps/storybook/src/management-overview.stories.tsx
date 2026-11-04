import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState, type CSSProperties } from "react";
import {
  KBadge,
  KBreadcrumb,
  KButton,
  KIcon,
  KStack,
  KText,
  KAdaptiveDialog,
  type KIconName,
} from "@k-design-system/ui";
import "./settings-grouped.css";
import "./management-overview.css";

// Gallery composition: KButton owns interaction; host supplies routes, counts and publication state.
// Reuses SettingsGrouped theme overrides. No new package API or production navigation.
const items: {
  id: string;
  title: string;
  icon: KIconName;
  color: string;
  description: string;
  value?: string;
}[] = [
  {
    id: "customers",
    title: "Kund:innen",
    icon: "users",
    color: "#0c679f",
    description: "Kontakte, Adressen und Notizen",
    value: "10",
  },
  {
    id: "services",
    title: "Leistungen",
    icon: "list",
    color: "#7c3aed",
    description: "Buchbar mit Preis und Dauer",
    value: "8 aktiv",
  },
  {
    id: "categories",
    title: "Kategorien",
    icon: "folders",
    color: "#db2777",
    description: "Gruppen und Reihenfolge",
    value: "3",
  },
  {
    id: "products",
    title: "Produkte",
    icon: "package",
    color: "#ea580c",
    description: "Waren, Extras und Bestände",
    value: "5",
  },
  {
    id: "booking-page",
    title: "Buchungsseite & QR",
    icon: "qr-code",
    color: "#0891b2",
    description: "Link, Vorschau und QR-Code",
    value: "Online",
  },
  {
    id: "business-profile",
    title: "Betriebsprofil",
    icon: "store",
    color: "#0d9488",
    description: "Name, Beschreibung und Kontakt",
  },
  {
    id: "locations",
    title: "Standorte & Zeiten",
    icon: "map-pin",
    color: "#16a34a",
    description: "Tagesstart, Tagesende, Ausnahmen",
    value: "Mo–Fr",
  },
  {
    id: "booking-rules",
    title: "Zonen & Buchungsregeln",
    icon: "hexagon",
    color: "#ca8a04",
    description: "Wo und wann man dich buchen kann",
  },
  {
    id: "history",
    title: "Änderungsverlauf",
    icon: "rotate-ccw",
    color: "#52525b",
    description: "Änderungen und Veröffentlichungen",
  },
];
const groups = [
  {
    title: "Kund:innen & Angebot",
    ids: ["customers", "services", "categories", "products"],
  },
  { title: "Auftritt", ids: ["booking-page", "business-profile"] },
  { title: "Einsatz", ids: ["locations", "booking-rules"] },
  { title: "Verlauf", ids: ["history"] },
];

function ManagementOverview({
  published = true,
  empty = false,
  longLabels = false,
}: {
  published?: boolean;
  empty?: boolean;
  longLabels?: boolean;
}) {
  const [page, setPage] = useState<string | null>(null);
  const [sharing, setSharing] = useState(false);
  const selected = items.find((item) => item.id === page);
  const titleFor = (item: (typeof items)[number]) =>
    longLabels && item.id === "booking-rules"
      ? "Buchungsgebiete und individuelle Buchungsbedingungen"
      : item.title;
  const valueFor = (item: (typeof items)[number]) =>
    item.id === "booking-page"
      ? published
        ? "Online"
        : "Entwurf"
      : empty && item.value
        ? "0"
        : item.value;
  const badge = (item: (typeof items)[number]) =>
    item.id === "booking-page" ? (
      <span className="mg-status" data-live={published}>
        {valueFor(item)}
      </span>
    ) : (
      <span className="mg-value">{valueFor(item)}</span>
    );
  const icon = (item: (typeof items)[number], navigation = false) => (
    <span
      className="mg-icon"
      style={{ "--mg-icon-color": item.color } as CSSProperties}
    >
      <KIcon
        className="mg-icon-glyph"
        name={item.icon}
        size={navigation ? 15 : 19}
      />
    </span>
  );
  const groupList = (navigation = false) =>
    groups.map((group) => (
      <section className="mg-group" key={group.title}>
        <h2>{group.title}</h2>
        <div className={navigation ? "mg-nav-list" : "mg-grid"}>
          {group.ids.map((id) => {
            const item = items.find((entry) => entry.id === id)!;
            return (
              <KButton
                key={id}
                fullWidth
                variant="ghost"
                className="mg-item"
                aria-current={page === id ? "page" : undefined}
                onClick={() => setPage(id)}
              >
                <span className="mg-item-layout">
                  {icon(item, navigation)}
                  <span
                    className="mg-item-title"
                    title={navigation ? titleFor(item) : undefined}
                  >
                    {titleFor(item)}
                  </span>
                  {badge(item)}
                  <span className="mg-description">{item.description}</span>
                  <KIcon
                    className="mg-chevron"
                    name="chevron-right"
                    size={20}
                  />
                </span>
              </KButton>
            );
          })}
        </div>
      </section>
    ));
  return (
    <div className="sg-review mg-review">
      <div className="mg-shell">
        <nav className="mg-nav" aria-label="Verwaltung">
          <KText as="h2" variant="heading3">
            Verwaltung
          </KText>
          <KButton
            fullWidth
            variant="ghost"
            className="mg-overview-link"
            aria-current={!page ? "page" : undefined}
            onClick={() => setPage(null)}
          >
            <KIcon name="briefcase" size={20} />
            Übersicht
          </KButton>
          {groupList(true)}
        </nav>
        <main className="mg-main">
          <div className="mg-content">
            <KBreadcrumb
              label="Brotkrümelnavigation"
              items={[
                {
                  id: "management",
                  label: "Verwaltung",
                  onSelect: () => setPage(null),
                },
                ...(selected
                  ? [{ id: selected.id, label: selected.title }]
                  : []),
              ]}
            />
            {selected ? (
              <KStack gap="section" align="stretch">
                <KButton
                  className="mg-back"
                  variant="ghost"
                  onClick={() => setPage(null)}
                >
                  <KIcon name="arrow-left" />
                  Zurück zur Verwaltung
                </KButton>
                <header className="mg-detail-title">
                  {icon(selected)}
                  <div>
                    <h1>{selected.title}</h1>
                    <p>{selected.description}</p>
                  </div>
                </header>
                <KText>
                  Dieses Navigationsziel ist Teil der Vorschau. In der Anwendung
                  öffnet sich hier der vorhandene Fachbereich.
                </KText>
                <KBadge>Storybook-Vorschau</KBadge>
              </KStack>
            ) : (
              <>
                <header className="mg-heading">
                  <h1>Verwaltung</h1>
                  <p>Alles für deinen Betrieb und deine Buchungen.</p>
                </header>
                <section
                  className="mg-share"
                  aria-label="Status deiner Buchungsseite"
                >
                  <span className="mg-dot" data-live={published} />
                  <div>
                    <strong>
                      {published
                        ? "Deine Buchungsseite ist online"
                        : "Deine Buchungsseite ist noch im Entwurf"}
                    </strong>
                    <p>
                      {published
                        ? `${empty ? "0" : "8"} Leistungen buchbar · Mo–Fr`
                        : "Schließe die Einrichtung ab, um Buchungen zu erhalten."}
                    </p>
                  </div>
                  <KButton
                    onClick={() =>
                      published ? setSharing(true) : setPage("booking-page")
                    }
                  >
                    <KIcon
                      name={published ? "share" : "arrow-right"}
                      size={16}
                    />
                    {published ? "Teilen" : "Einrichten"}
                  </KButton>
                </section>
                <KStack gap="section" align="stretch">
                  {groupList()}
                </KStack>
              </>
            )}
          </div>
        </main>
      </div>
      <KAdaptiveDialog
        open={sharing}
        onOpenChange={setSharing}
        title="Buchungsseite teilen"
      >
        <KStack gap="action">
          <KText>
            In der Anwendung öffnet sich hier der vorhandene Dialog für QR-Code
            und Teilen.
          </KText>
          <KButton onClick={() => setSharing(false)}>Schließen</KButton>
        </KStack>
      </KAdaptiveDialog>
    </div>
  );
}
const meta = {
  title: "Patterns/ManagementOverview",
  component: ManagementOverview,
  parameters: { layout: "fullscreen" },
  args: { published: true, empty: false, longLabels: false },
} satisfies Meta<typeof ManagementOverview>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Overview: Story = {};
export const Dark: Story = { globals: { theme: "dark" } };
export const Draft: Story = { args: { published: false } };
export const Empty: Story = { args: { published: false, empty: true } };
export const LongLabels: Story = { args: { longLabels: true } };
