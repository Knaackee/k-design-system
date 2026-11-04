import type { Meta, StoryObj } from "@storybook/react-vite";
import { useMemo, useState } from "react";
import {
  KAgenda,
  KCard,
  KBadge,
  KButton,
  KIcon,
  KLink,
  KInline,
  KMediaCard,
  KStack,
  KText,
} from "@k-design-system/ui";
import "./home-overview.css";

import "maplibre-gl/dist/maplibre-gl.css";
import "@k-design-system/ui/maps.css";

import {
  KMap,
  type KMapPin,
  type KMapRoute,
} from "@k-design-system/ui/patterns/map";
import {
  createMapStyle,
  LIGHT_MAP_TOKENS,
  DARK_MAP_TOKENS,
} from "@k-design-system/ui/maps";
import { setWorkerUrl } from "maplibre-gl";
import workerUrl from "maplibre-gl/dist/maplibre-gl-worker.mjs?worker&url";

setWorkerUrl(workerUrl);

// Gallery fixture only. The application supplies the previous-to-next leg
// from its routing service, rather than drawing a straight line between stops.
const route: KMapRoute = {
  id: "previous-to-next",
  coordinates: [
    [12.3748, 51.3405],
    [12.3749, 51.3394],
    [12.3754, 51.3386],
    [12.3763, 51.3377],
    [12.3771, 51.3368],
    [12.3774, 51.3356],
  ],
};
const pins: KMapPin[] = [
  {
    id: "previous",
    position: route.coordinates[0],
    label: "Vorherige Station",
    icon: "check",
    shape: "circle",
  },
  {
    id: "next",
    position: route.coordinates[route.coordinates.length - 1],
    label: "Nächster Termin: Jonas Becker",
    icon: "user",
  },
];

function MapPreview({ dark }: { dark: boolean }) {
  const style = useMemo(
    () => createMapStyle({ tokens: dark ? DARK_MAP_TOKENS : LIGHT_MAP_TOKENS }),
    [dark],
  );
  return (
    <div className="home-demo-map">
      <KMap
        mapStyle={style}
        center={route.coordinates[0]}
        routes={[route]}
        pins={pins}
        label="Beispielroute von der vorherigen zur nächsten Station"
        interactive={false}
        showZoomControls={false}
        fitContent
        fitPadding={48}
        fitMaxZoom={15}
        fitDurationMs={0}
      />
    </div>
  );
}
function PagePreview() {
  return (
    <div className="home-demo-preview" aria-hidden="true">
      <div className="home-demo-phone">
        <div className="home-demo-photo">
          <KIcon name="scissors" size={36} />
        </div>
        <small>Alex’ Haarpflege</small>
        <strong>
          Schöne Haare.
          <br />
          Bei dir zu Hause.
        </strong>
        <span>Termin buchen</span>
      </div>
    </div>
  );
}

function HomeOverview({
  state = "active",
  mediaPlacement = "top",
  dark = false,
}: {
  dark?: boolean;
  state?: "new" | "active";
  mediaPlacement?: "top" | "responsive";
}) {
  const [notice, setNotice] = useState("");
  const action = (label: string) => () => setNotice(`Demo: ${label}`);
  const active = state === "active";
  return (
    <div className="home-demo">
      <header>
        <KText as="h1" variant="heading2">
          Guten Tag, Alex.
        </KText>
        <KText className="home-demo-muted">
          Sonntag, 1. November{active ? " · noch 3 Termine heute" : ""}
        </KText>
      </header>
      <div className="home-demo-columns">
        <KStack gap="section" align="stretch">
          {active ? (
            <KMediaCard
              media={<MapPreview dark={dark} />}
              mediaPlacement={mediaPlacement}
              mediaOverlay={
                <KBadge variant="secondary">
                  <KIcon name="car" size={16} /> 6 Min.
                </KBadge>
              }
              elevation="low"
            >
              <div className="home-demo-appointment">
                <div className="home-demo-appointment-time">
                  <KText variant="label" className="home-demo-muted">
                    Nächster Termin
                  </KText>
                  <KInline align="center" gap="control">
                    <KText as="p" variant="heading1">
                      10:40
                    </KText>
                    <KText variant="bodySmall" className="home-demo-muted">
                      in 25 Min.
                    </KText>
                  </KInline>
                </div>
                <div className="home-demo-appointment-customer">
                  <KInline gap="action">
                    <div className="home-demo-avatar">J</div>
                    <div className="home-demo-person-copy">
                      <KText variant="label">Jonas Becker</KText>
                      <KText variant="bodySmall" className="home-demo-muted">
                        Herrenschnitt · 30 Min.
                      </KText>
                    </div>
                  </KInline>
                  <KText className="home-demo-muted">
                    Beispielstraße 18, Leipzig
                  </KText>
                </div>
                <KInline
                  className="home-demo-appointment-actions"
                  gap="action"
                  wrap
                >
                  <KButton onClick={action("Route starten")}>
                    <KIcon name="navigation" /> Route starten
                  </KButton>
                  <KButton variant="secondary" onClick={action("Anrufen")}>
                    <KIcon name="phone" /> Anrufen
                  </KButton>
                </KInline>
              </div>
            </KMediaCard>
          ) : (
            <KMediaCard
              media={<PagePreview />}
              mediaPlacement="top"
              elevation="low"
            >
              <KStack gap="action" align="start">
                <KBadge variant="secondary">Deine Seite ist online</KBadge>
                <KText variant="heading3">
                  Deine Seite ist bereit für die ersten Buchungen.
                </KText>
                <KText variant="bodySmall">onzeit.com/u/alex-demo</KText>
                <KInline gap="action" wrap>
                  <KButton onClick={action("Seite teilen")}>
                    <KIcon name="share" /> Seite teilen
                  </KButton>
                  <KButton
                    variant="secondary"
                    onClick={action("Vorschau öffnen")}
                  >
                    Ansehen
                  </KButton>
                </KInline>
                <KText variant="caption" className="home-demo-muted">
                  Seite live · Nächster Schritt: Teilen
                </KText>
              </KStack>
            </KMediaCard>
          )}
          <section>
            <KInline className="home-demo-section" wrap>
              <KText as="h2" variant="heading4">
                Heute
              </KText>
              <KButton variant="ghost" onClick={action("Kalender öffnen")}>
                {active ? "Mein Tag" : "Kalender"}
                <KIcon name="arrow-right" />
              </KButton>
            </KInline>
            {active ? (
              <KAgenda
                label="Heutige Termine"
                items={[
                  {
                    id: "first",
                    time: "09:00",
                    title: "Maria S.",
                    description: "Waschen & Schneiden · 45 Min.",
                    state: "completed",
                  },
                  {
                    id: "next",
                    time: "10:40",
                    title: "Jonas Becker",
                    description: "Herrenschnitt · 30 Min.",
                    state: "current",
                    transition: (
                      <KInline gap="control">
                        <KIcon name="car" size={16} />
                        <KText variant="caption">
                          14 Min. zum nächsten Termin
                        </KText>
                      </KInline>
                    ),
                  },
                  {
                    id: "later",
                    time: "11:45",
                    title: "Renate W.",
                    description: "Farbe · 90 Min.",
                  },
                  {
                    id: "last",
                    time: "14:00",
                    title: "Seniorenheim Lindenhof",
                    description: "4 Termine am Stück",
                  },
                ]}
              />
            ) : (
              <KText className="home-demo-muted">
                Noch keine Termine. Sobald jemand bucht, steht der Termin hier,
                mit Route und Uhrzeit.
              </KText>
            )}
          </section>
        </KStack>
        <KStack gap="section" align="stretch">
          <section>
            <KText as="h2" variant="heading4">
              {active ? "Diese Woche" : "Mehr Buchungen bekommen"}
            </KText>
            {active ? (
              <div className="home-demo-stats">
                {[
                  {
                    value: "23",
                    label: "Termine",
                    change: "+4",
                    positive: true,
                  },
                  {
                    value: "1.240 €",
                    label: "Einnahmen",
                    change: "+18 %",
                    positive: true,
                  },
                  {
                    value: "3,5 h",
                    label: "weniger Fahrt",
                    change: "dank Route",
                    positive: false,
                  },
                ].map(({ value, label, change, positive }) => (
                  <div key={label}>
                    <KText variant="heading3">{value}</KText>
                    <KText variant="bodySmall" className="home-demo-muted">
                      {label}
                    </KText>
                    <KText
                      variant="caption"
                      className={
                        positive ? "home-demo-positive" : "home-demo-muted"
                      }
                    >
                      {change}
                    </KText>
                  </div>
                ))}
              </div>
            ) : (
              <KStack gap="control" align="stretch">
                {[
                  "In deinen Status posten",
                  "QR-Code ausdrucken",
                  "Extras ergänzen",
                ].map((label) => (
                  <KButton key={label} variant="ghost" onClick={action(label)}>
                    {label}
                    <KIcon name="chevron-right" />
                  </KButton>
                ))}
              </KStack>
            )}
          </section>
          {active && (
            <section>
              <KInline className="home-demo-section">
                <KText as="h2" variant="heading4">
                  Anfragen
                </KText>
                <KButton variant="ghost" onClick={action("Alle Anfragen")}>
                  Alle
                </KButton>
              </KInline>
              {[
                ["Sophie L.", "Langhaarschnitt · Di 15:10"],
                ["Thomas R.", "Herrenschnitt · Mi 09:00"],
              ].map(([name, detail]) => (
                <KLink
                  className="home-demo-request"
                  key={name}
                  href="#request-preview"
                  aria-label={`Anfrage von ${name} öffnen`}
                  onClick={(event) => {
                    event.preventDefault();
                    action(name)();
                  }}
                >
                  <span className="home-demo-request-content">
                    <span className="home-demo-avatar" aria-hidden="true">
                      {name[0]}
                    </span>
                    <span className="home-demo-person-copy">
                      <KText as="span" variant="label">
                        {name}
                      </KText>
                      <KText
                        as="span"
                        variant="bodySmall"
                        className="home-demo-muted"
                      >
                        {detail}
                      </KText>
                    </span>
                    <KIcon name="chevron-right" />
                  </span>
                </KLink>
              ))}
            </section>
          )}
          {active && (
            <KCard className="home-demo-booking-page" elevation="low">
              <div className="home-demo-page-thumb" aria-hidden="true">
                <KIcon name="scissors" size={24} />
              </div>
              <KStack
                gap="control"
                align="start"
                className="home-demo-page-info"
              >
                <KText variant="label">Deine Buchungsseite</KText>
                <KLink
                  className="home-demo-page-link"
                  href="#booking-page-preview"
                  leading={
                    <span className="home-demo-online-dot" aria-hidden="true" />
                  }
                  onClick={(event) => {
                    event.preventDefault();
                    action("Buchungsseite öffnen")();
                  }}
                >
                  alex-demo.onzeit.com
                </KLink>
              </KStack>
              <KButton
                variant="ghost"
                aria-label="Buchungsseite teilen"
                onClick={action("Buchungsseite teilen")}
              >
                <KIcon name="share" />
              </KButton>
            </KCard>
          )}
          <KText variant="caption" className="home-demo-muted">
            Gestaltungsvorschau · Alle Namen, Werte und die Karte sind
            Beispieldaten.
          </KText>
        </KStack>
      </div>
      <KText role="status" variant="bodySmall">
        {notice}
      </KText>
    </div>
  );
}

const meta = {
  title: "Patterns/HomeOverview",
  component: HomeOverview,
  render: (args, context) => (
    <HomeOverview {...args} dark={context.globals.theme === "dark"} />
  ),
  globals: {
    typeScale: "standard",
    viewport: { value: "home-desktop", isRotated: false },
  },
  args: { state: "active", mediaPlacement: "top" },
  argTypes: {
    state: { control: "inline-radio", options: ["new", "active"] },
    mediaPlacement: { control: "inline-radio", options: ["top", "responsive"] },
  },
  parameters: {
    viewport: {
      options: {
        "home-desktop": {
          name: "Home Desktop",
          styles: { width: "1280px", height: "900px" },
        },
        "home-tablet": {
          name: "Home Tablet",
          styles: { width: "1024px", height: "900px" },
        },
        "home-mobile": {
          name: "Home Mobile",
          styles: { width: "390px", height: "844px" },
        },
      },
    },
    layout: "fullscreen",
    fixtureId: "home-overview-active",
  },
} satisfies Meta<typeof HomeOverview>;
export default meta;
type Story = StoryObj<typeof meta>;
export const ActiveDay: Story = {};
export const NewAccount: Story = {
  args: { state: "new" },
  parameters: { fixtureId: "home-overview-new" },
};
export const Mobile: Story = {
  globals: { viewport: { value: "home-mobile", isRotated: false } },
  decorators: [
    (Story) => (
      <div style={{ maxWidth: 390 }}>
        <Story />
      </div>
    ),
  ],
};
export const Dark: Story = { globals: { theme: "dark" } };
export const MediaOnLeft: Story = { args: { mediaPlacement: "responsive" } };

export const Tablet: Story = {
  globals: { viewport: { value: "home-tablet", isRotated: false } },
  decorators: [
    (Story) => (
      <div style={{ width: "100%", maxWidth: 1024 }}>
        <Story />
      </div>
    ),
  ],
};
