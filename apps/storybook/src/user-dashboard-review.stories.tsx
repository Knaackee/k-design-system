import { useMemo, useState, type ReactNode } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KAvatar,
  KBadge,
  KBarChart,
  KButton,
  KCard,
  KIcon,
  KIconButton,
  KInline,
  KProgress,
  KQrCode,
  KStack,
  KSwitch,
  KTabs,
  KText,
  type KIconName,
} from "@k-design-system/ui";
import { KMap, type KMapRoute } from "@k-design-system/ui/patterns/map";
import {
  createMapStyle,
  DARK_MAP_TOKENS,
  LIGHT_MAP_TOKENS,
} from "@k-design-system/ui/maps";
import { setWorkerUrl } from "maplibre-gl";
import workerUrl from "maplibre-gl/dist/maplibre-gl-worker.mjs?worker&url";
import "maplibre-gl/dist/maplibre-gl.css";
import "@k-design-system/ui/maps.css";
import "./user-dashboard-review.css";

// Gallery-only composition: KCard/KStack/KInline + public K actions, fields,
// map and charts. Inter and host semantic token overrides remain authoritative.
// Every interaction below is synthetic; it never changes a real booking/account.
setWorkerUrl(workerUrl);
type DashboardState = "full" | "free" | "fresh" | "ready";
type Action = (message: string) => void;
const money = (n: number) => `${n.toLocaleString("de-DE")} €`;
const series = (n: number, base: number, amp: number, seed: number) =>
  Array.from({ length: n }, (_, i) =>
    Math.max(
      0,
      Math.round(
        base +
          amp * Math.sin(i / 1.7 + seed) +
          ((i * base) / n) * 0.35 +
          ((i * 7 + seed * 3) % 4) -
          1.5,
      ),
    ),
  );
const sum = (a: number[]) => a.reduce((x, y) => x + y, 0);
const accents = ["blue", "violet", "pink", "orange", "teal"];
function Copy({ title, subtitle }: { title: string; subtitle?: string }) {
  return (
    <span className="ud-copy">
      <strong>{title}</strong>
      {subtitle && <small title={subtitle}>{subtitle}</small>}
    </span>
  );
}
function Box({
  title,
  end,
  children,
  className = "",
}: {
  title?: string;
  end?: ReactNode;
  children: ReactNode;
  className?: string;
}) {
  return (
    <KCard className={`ud-box ${className}`}>
      {title && (
        <div className="ud-box-heading">
          <KText as="h2" variant="heading4">
            {title}
          </KText>
          {end}
        </div>
      )}
      {children}
    </KCard>
  );
}
function LinkAction({
  children,
  onClick,
}: {
  children: ReactNode;
  onClick: () => void;
}) {
  return (
    <KButton variant="ghost" className="ud-link" onClick={onClick}>
      {children}
    </KButton>
  );
}
function Avatar({ name, index = 0 }: { name: string; index?: number }) {
  return (
    <span className="ud-avatar" data-accent={accents[index % accents.length]}>
      <KAvatar alt={name} />
    </span>
  );
}
function Spark({
  values,
  negative = false,
}: {
  values: number[];
  negative?: boolean;
}) {
  const max = Math.max(...values, 1);
  return (
    <svg
      className={`ud-spark ${negative ? "ud-negative" : ""}`}
      aria-hidden="true"
      viewBox="0 0 100 30"
      preserveAspectRatio="none"
    >
      <polyline
        points={values
          .map(
            (v, i) =>
              `${(i / (values.length - 1)) * 100},${28 - (v / max) * 26}`,
          )
          .join(" ")}
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        vectorEffect="non-scaling-stroke"
        strokeLinejoin="round"
      />
    </svg>
  );
}
const route: KMapRoute = {
  id: "demo-next",
  coordinates: [
    [12.3748, 51.3405],
    [12.3749, 51.3394],
    [12.3754, 51.3386],
    [12.3763, 51.3377],
    [12.3771, 51.3368],
    [12.3774, 51.3356],
  ],
};
function Next({
  free,
  dark,
  action,
}: {
  free: boolean;
  dark: boolean;
  action: Action;
}) {
  const mapStyle = useMemo(
    () => createMapStyle({ tokens: dark ? DARK_MAP_TOKENS : LIGHT_MAP_TOKENS }),
    [dark],
  );
  const name = free ? "Jonas Becker" : "Lena Hoffmann";
  return (
    <Box className="ud-next">
      <div className="ud-map">
        <KMap
          label="Beispielroute zum nächsten Termin"
          mapStyle={mapStyle}
          center={route.coordinates[0]}
          routes={[{ ...route, color: dark ? "#7ac1f2" : "#0c679f" }]}
          pins={[
            {
              id: "previous",
              position: route.coordinates[0],
              label: "Vorherige Station",
              icon: "check",
              shape: "circle",
              color: dark ? "#7ac1f2" : "#0c679f",
            },
            {
              id: "next",
              position: route.coordinates.at(-1)!,
              label: name,
              icon: "map-pin",
              color: dark ? "#7ac1f2" : "#0c679f",
            },
          ]}
          interactive={false}
          showZoomControls={false}
          fitContent
          fitPadding={{ top: 48, bottom: 12, left: 24, right: 24 }}
          fitMaxZoom={14}
          fitDurationMs={0}
        />
      </div>
      <KStack className="ud-next-body" gap="control" align="stretch">
        <KText className="ud-muted" variant="caption">
          Nächster Termin · {free ? "Morgen" : "in 13 Min"}
        </KText>
        <div className="ud-time">
          {free ? "09:30" : "17:15"}
          <span>
            bis {free ? "10:30 · 14 Min Fahrt" : "19:15 · 11 Min Fahrt"}
          </span>
        </div>
        <KInline gap="control" className="ud-leave">
          <KIcon name="car" size={16} />
          <KText variant="label">
            {free ? "Losfahren um 09:16" : "Jetzt losfahren"}
          </KText>
        </KInline>
        <KInline gap="action">
          <Avatar name={name} index={free ? 0 : 4} />
          <Copy
            title={name}
            subtitle={
              free
                ? "Herrenschnitt · Bornaische Str. 18, Leipzig"
                : "Balayage · Karl-Heine-Str. 42, Leipzig"
            }
          />
        </KInline>
        <div className="ud-actions-two">
          <KButton onClick={() => action("Route öffnen")}>
            <KIcon name="navigation" />
            Route
          </KButton>
          <KButton
            variant="secondary"
            onClick={() => action("Termindetails öffnen")}
          >
            Details
          </KButton>
        </div>
      </KStack>
    </Box>
  );
}
function Today({ action }: { action: Action }) {
  return (
    <Box
      title="Heute"
      end={
        <LinkAction onClick={() => action("Mein Tag öffnen")}>
          Mein Tag
        </LinkAction>
      }
    >
      <div className="ud-timeline">
        {[
          ["08:30", "Ingrid Kühn", "Waschen & Schneiden · Zentrum-Süd"],
          ["10:40", "Renate Weber", "Farbe, Schneiden · Gohlis"],
          ["14:30", "Familie Öztürk", "3× Kinderschnitt · Connewitz"],
          ["17:15", "Lena Hoffmann", "Balayage · Plagwitz"],
        ].map(([time, name, detail], i) => (
          <div key={time} className={i < 3 ? "ud-done" : "ud-current"}>
            <time>{time}</time>
            <i aria-hidden="true" />
            <Copy title={name} subtitle={detail} />
          </div>
        ))}
      </div>
    </Box>
  );
}
function Requests({ action }: { action: Action }) {
  const [items, setItems] = useState([0, 1]);
  const names = ["Thomas Richter", "Sophie Lange"];
  return (
    <Box
      title={items.length ? "Offene Anfragen" : "Anfragen"}
      end={items.length ? <KBadge>{items.length}</KBadge> : undefined}
    >
      {items.length ? (
        items.map((i) => (
          <div className="ud-list-row" key={i}>
            <Avatar name={names[i]} index={i + 3} />
            <span className="ud-copy">
              <strong>{names[i]}</strong>
              <small>
                {i
                  ? "Balayage · Mo, 9. Nov · Preis offen"
                  : "Herrenschnitt · Do, 5. Nov, 11:00"}
              </small>
              <small className="ud-price">
                {i ? "Auf Anfrage" : "35,40 €"}
              </small>
            </span>
            <KInline className="ud-request-actions" gap="control">
              <KIconButton
                className="ud-decline"
                icon="x"
                label={`${names[i]}: Anfrage ablehnen`}
                onClick={() => {
                  setItems(items.filter((x) => x !== i));
                  action("Anfrage abgelehnt – nur Vorschau");
                }}
              />
              <KIconButton
                className="ud-accept"
                icon="check"
                label={`${names[i]}: Anfrage annehmen`}
                onClick={() => {
                  setItems(items.filter((x) => x !== i));
                  action("Anfrage angenommen – nur Vorschau");
                }}
              />
            </KInline>
          </div>
        ))
      ) : (
        <KInline gap="control">
          <KIcon name="check" className="ud-positive" size={16} />
          <KText className="ud-muted">Alles beantwortet.</KText>
        </KInline>
      )}
    </Box>
  );
}
function Metrics({
  period,
  onPeriod,
  revenue,
  bookings,
}: {
  period: number;
  onPeriod: (n: number) => void;
  revenue: number[];
  bookings: number[];
}) {
  const rows = [
    {
      label: "Umsatz",
      value: money(sum(revenue)),
      change: "+12 %",
      values: revenue,
    },
    {
      label: "Buchungen",
      value: String(sum(bookings)),
      change: "+8 %",
      values: bookings,
    },
    {
      label: "Neue Kund:innen",
      value: String(Math.round((9 * period) / 30) || 2),
      change: period === 7 ? "+1" : "+3",
      values: series(revenue.length, 1, 1, 4),
    },
    {
      label: "Auslastung",
      value: "74 %",
      change: "−4 %",
      values: series(revenue.length, 70, 8, 5),
    },
  ];
  return (
    <section className="ud-span">
      <div className="ud-business-heading">
        <KText as="h2" variant="heading3">
          Dein Geschäft
        </KText>
        <div className="ud-period">
          <KTabs
            label="Auswertungszeitraum"
            expanded
            value={String(period)}
            onValueChange={(v) => onPeriod(Number(v))}
            items={[7, 30, 90].map((p) => ({
              id: String(p),
              label: `${p} Tage`,
              content: null,
            }))}
          />
        </div>
      </div>
      <div className="ud-metrics">
        {rows.map((r, i) => (
          <KCard className="ud-metric" key={r.label}>
            <span>{r.label}</span>
            <b>{r.value}</b>
            <small className={i === 3 ? "ud-negative" : "ud-positive"}>
              {r.change} <span>vs. davor</span>
            </small>
            <Spark values={r.values} negative={i === 3} />
          </KCard>
        ))}
      </div>
    </section>
  );
}
function Revenue({
  revenue,
  previous,
  period,
}: {
  revenue: number[];
  previous: number[];
  period: number;
}) {
  const max = Math.ceil(Math.max(...revenue, ...previous) / 100) * 100;
  const labels =
    period === 7
      ? ["Do", "Fr", "Sa", "So", "Mo", "Di", "Mi"]
      : period === 30
        ? ["6. Okt", "20. Okt", "4. Nov"]
        : ["Aug", "Sep", "Okt", "Nov"];
  return (
    <Box title="Umsatz">
      <KBarChart
        label="Umsatz im Vergleich zur Vorperiode"
        height={150}
        series={[
          {
            id: "current",
            label: "Aktuell",
            points: revenue.map((y, x) => ({ id: String(x), x, y })),
          },
          {
            id: "previous",
            label: "Davor",
            colorIndex: 1,
            points: previous.map((y, x) => ({ id: String(x), x, y })),
          },
        ]}
        xAxis={{
          min: -0.5,
          max: revenue.length - 0.5,
          ticks: [],
          format: String,
        }}
        yAxis={{ min: 0, max, ticks: [], format: money }}
      />
      <div className="ud-chart-labels">
        {labels.map((label) => (
          <span key={label}>{label}</span>
        ))}
      </div>
    </Box>
  );
}
function Week({
  free = false,
  ready = false,
}: {
  free?: boolean;
  ready?: boolean;
}) {
  const values = ready
    ? [100, 100, 100, 0, 0, 100, 100]
    : [free ? 0 : 88, 62, 75, 40, 0, 25, 50];
  return (
    <Box
      title={ready ? "Diese Woche buchbar" : "Nächste 7 Tage"}
      end={
        !ready && (
          <span className="ud-legend">
            <span>
              <i />
              gebucht
            </span>
            <span>
              <i className="ud-legend-free" />
              frei
            </span>
          </span>
        )
      }
    >
      {ready && (
        <div className="ud-time ud-week-time">
          31<span>Std. frei · Mo–Fr 09–18</span>
        </div>
      )}
      <div
        className={`ud-week ${ready ? "ud-week-ready" : ""}`}
        role="img"
        aria-label={
          ready
            ? "31 Stunden frei; Samstag und Sonntag nicht buchbar"
            : "Auslastung: heute bis Dienstag"
        }
      >
        {values.map((v, i) => (
          <div key={i}>
            <div className="ud-week-bar">
              <i style={{ height: `${v}%` }} />
            </div>
            <span className={!i ? "ud-brand" : undefined}>
              {["Heute", "Do", "Fr", "Sa", "So", "Mo", "Di"][i]}
            </span>
          </div>
        ))}
      </div>
      <KText className="ud-footnote">
        {ready ? (
          "Grün = buchbar. Sa und So bist du nicht buchbar."
        ) : (
          <>
            Am meisten frei: <strong>Mo, 9. Nov</strong> · 6 Std.
          </>
        )}
      </KText>
    </Box>
  );
}
function Customers({ action }: { action: Action }) {
  return (
    <Box
      title="Neue Kund:innen"
      end={
        <LinkAction onClick={() => action("Kundenliste öffnen")}>
          Alle
        </LinkAction>
      }
    >
      {[
        ["Lena Hoffmann", "Balayage · über Buchungsseite", "heute"],
        ["Familie Öztürk", "Kinderschnitt · über QR-Code", "gestern"],
        ["Paul Neumann", "Herrenschnitt · Empfehlung von Ingrid K.", "Mo"],
        ["Clara Vogt", "Waschen & Föhnen · Instagram", "So"],
      ].map(([name, sub, time], i) => (
        <div className="ud-list-row" key={name}>
          <Avatar name={name} index={i} />
          <Copy title={name} subtitle={sub} />
          <span className="ud-customer-when">{time}</span>
        </div>
      ))}
    </Box>
  );
}
function Services() {
  return (
    <Box title="Top-Leistungen">
      <KStack gap="control" align="stretch">
        {[
          ["Balayage", 1240],
          ["Herrenschnitt", 862],
          ["Waschen & Schneiden", 610],
          ["Kinderschnitt", 288],
        ].map(([name, value]) => (
          <div key={name}>
            <div className="ud-service-heading">
              <span>{name}</span>
              <strong>{money(Number(value))}</strong>
            </div>
            <KProgress
              value={(Number(value) / 1240) * 100}
              aria-hidden="true"
            />
          </div>
        ))}
      </KStack>
    </Box>
  );
}
function Share({
  action,
  draft = false,
  first = false,
}: {
  action: Action;
  draft?: boolean;
  first?: boolean;
}) {
  return (
    <Box
      title={first ? "Bereit für deine erste Buchung" : "Deine Buchungsseite"}
      className={first ? "ud-share-featured" : ""}
      end={
        <KBadge variant={draft ? "secondary" : "success"}>
          {draft ? "Entwurf" : "Online"}
        </KBadge>
      }
    >
      <KInline gap="action" className="ud-share-copy">
        <div className="ud-qr">
          <KQrCode
            data="https://example.invalid/denis"
            label="QR-Code der Demo-Buchungsseite"
            size={64}
            moduleShape="rounded"
            eyeShape="rounded"
          />
        </div>
        <span className="ud-copy">
          <strong>example.invalid/denis</strong>
          <small>
            {draft
              ? "Schließe die Einrichtung ab, bevor du deine Seite veröffentlichst und teilst."
              : first
                ? "Jetzt geht es darum, dass Leute deine Seite finden."
                : "Teile den Link in deiner Insta-Bio oder zeig den QR-Code vor Ort."}
          </small>
        </span>
      </KInline>
      {!draft && !first && (
        <div className="ud-stats-three">
          {[
            ["186", "Aufrufe"],
            ["14", "Buchungen"],
            ["7,5 %", "Conversion"],
          ].map(([value, label]) => (
            <div key={label}>
              <b>{value}</b>
              <span>{label}</span>
            </div>
          ))}
        </div>
      )}
      <div className="ud-actions-two ud-share-actions">
        <KButton
          variant="secondary"
          disabled={draft}
          onClick={() => action("Link kopieren – nur Vorschau")}
        >
          <KIcon name="copy" />
          Kopieren
        </KButton>
        <KButton disabled={draft} onClick={() => action("Teilen öffnen")}>
          <KIcon name="share" />
          Teilen
        </KButton>
      </div>
    </Box>
  );
}
function Ghost({ small = false }: { small?: boolean }) {
  return (
    <Box className="ud-ghost" title="Dein Geschäft">
      <div
        className={`ud-metrics ${small ? "ud-metrics-small" : ""}`}
        aria-hidden="true"
      >
        {(small
          ? ["Umsatz", "Buchungen"]
          : ["Umsatz", "Buchungen", "Neue Kund:innen", "Auslastung"]
        ).map((label) => (
          <div className="ud-metric" key={label}>
            <span>{label}</span>
            <b>–</b>
            <Spark values={[2, 4, 3, 6, 5, 8, 7]} />
          </div>
        ))}
      </div>
      <p>
        Ab deiner ersten Buchung siehst du hier Umsatz, Buchungen und
        Auslastung.
      </p>
    </Box>
  );
}
function SetupContent({ action }: { action: Action }) {
  const [steps, setSteps] = useState([true, true, true, false, false, false]);
  const labels = [
    ["Profil & Foto", "Damit Kund:innen dich erkennen"],
    ["Erste Leistung", "Mit Preis und Dauer"],
    ["Startadresse", "Für Anfahrten"],
    ["Zone festlegen", "Wo man dich buchen kann"],
    ["Zahlungen verbinden", "Optional · Stripe"],
    ["Seite teilen", "Nach der Veröffentlichung"],
  ];
  const required = steps.filter((_, i) => i !== 4);
  const count = required.filter(Boolean).length;
  return (
    <>
      <header className="ud-header">
        <div>
          <KText as="h1" variant="heading1">
            Willkommen, Denis.
          </KText>
          <KText className="ud-muted">
            {count === required.length
              ? "Deine Einrichtung ist vollständig."
              : `Noch ${required.length - count} ${required.length - count === 1 ? "Schritt" : "Schritte"} bis zur ersten Buchung.`}
          </KText>
        </div>
      </header>
      <div className="ud-grid">
        <div className="ud-column">
          <Box>
            <KInline gap="action" className="ud-setup-heading">
              <div
                className="ud-ring"
                role="img"
                aria-label={`${count} von ${required.length} erforderlichen Schritten erledigt`}
                style={
                  {
                    "--progress": `${(count / required.length) * 100}%`,
                  } as React.CSSProperties
                }
              >
                <b>
                  {count}/{required.length}
                </b>
              </div>
              <Copy title="Einrichtung" subtitle="Dauert etwa 5 Minuten." />
            </KInline>
            {labels.map(([label, sub], i) => (
              <KButton
                key={label}
                className="ud-setup-row"
                variant="ghost"
                fullWidth
                onClick={() => {
                  setSteps(steps.map((s, j) => (i === j ? !s : s)));
                  action(`${label} – Demostatus geändert`);
                }}
              >
                <span
                  className={`ud-setup-content ${steps[i] ? "ud-setup-done" : ""}`}
                >
                  <span className="ud-check">
                    {steps[i] && <KIcon name="check" size={16} />}
                  </span>
                  <Copy title={label} subtitle={sub} />
                  {!steps[i] && <KIcon name="chevron-right" size={20} />}
                </span>
              </KButton>
            ))}
          </Box>
        </div>
        <div className="ud-column">
          <Share action={action} draft />
          <Ghost small />
        </div>
      </div>
    </>
  );
}
function ReadyContent({ action }: { action: Action }) {
  const [done, setDone] = useState([true, false, false, false]);
  const tips = [
    [
      "Link in deine Instagram-Bio",
      "Die meisten ersten Buchungen kommen von dort",
      "Erledigt",
    ],
    [
      "Bestandskund:innen einladen",
      "Kontakte auswählen und deinen Link teilen",
      "Einladen",
    ],
    ["QR-Code ausdrucken", "Für Visitenkarte, Auto oder Salon-Spiegel", "PDF"],
    [
      "Testbuchung machen",
      "Erlebe deine Seite wie deine Kund:innen",
      "Starten",
    ],
  ];
  return (
    <div className="ud-grid">
      <div className="ud-column">
        <Share action={action} first />
        <Box
          title="So kommen die ersten Buchungen"
          end={
            <span className="ud-muted ud-nowrap">
              {done.filter(Boolean).length} von 4
            </span>
          }
        >
          {tips.map(([label, sub, button], i) => (
            <div
              className={`ud-list-row ud-tip ${done[i] ? "ud-setup-done" : ""}`}
              key={label}
            >
              <span className="ud-check">
                {done[i] && <KIcon name="check" size={16} />}
              </span>
              <Copy title={label} subtitle={sub} />
              {!done[i] && (
                <KButton
                  variant="secondary"
                  onClick={() => {
                    setDone(done.map((x, j) => (i === j ? true : x)));
                    action(`${label} – nur Vorschau`);
                  }}
                >
                  {button}
                </KButton>
              )}
            </div>
          ))}
        </Box>
      </div>
      <div className="ud-column">
        <Box
          title="Besuche auf deiner Seite"
          end={
            <LinkAction onClick={() => action("Statistik öffnen")}>
              Details
            </LinkAction>
          }
        >
          <KInline gap="control" align="end">
            <span className="ud-time">38</span>
            <span className="ud-positive">+12 heute</span>
          </KInline>
          <div
            className="ud-week ud-visits"
            role="img"
            aria-label="Seitenbesuche pro Tag: 0, 3, 5, 2, 9, 7, 12"
          >
            {[0, 3, 5, 2, 9, 7, 12].map((v, i) => (
              <div key={i}>
                <div className="ud-week-bar">
                  <i style={{ height: `${(v / 12) * 100}%` }} />
                </div>
                <span>{["Do", "Fr", "Sa", "So", "Mo", "Di", "Heute"][i]}</span>
              </div>
            ))}
          </div>
          <div className="ud-stats-three">
            {[
              ["38", "Besuche"],
              ["9", "Leistung gewählt"],
              ["3", "bis Terminwahl"],
            ].map(([v, l]) => (
              <div key={l}>
                <b>{v}</b>
                <span>{l}</span>
              </div>
            ))}
          </div>
          <KText className="ud-footnote">
            3 Personen waren kurz vor der Buchung. Kurze Vorlaufzeiten und mehr
            freie Termine helfen.
          </KText>
        </Box>
        <Week ready />
        <LinkAction onClick={() => action("Zeiten ändern")}>
          Zeiten ändern
        </LinkAction>
      </div>
      <div className="ud-span">
        <Ghost />
      </div>
    </div>
  );
}
function Quiet({ action }: { action: Action }) {
  const [lastMinute, setLastMinute] = useState(false);
  return (
    <>
      <Box className="ud-free">
        <KInline gap="action" align="start">
          <span className="ud-sun">
            <KIcon name="sun" />
          </span>
          <Copy
            title="Heute ist frei."
            subtitle="Morgen um 09:30 geht's weiter. Willst du kurzfristige Buchungen für heute erlauben?"
          />
        </KInline>
      </Box>
      <Box title="Lücken füllen">
        <div className="ud-list-row">
          <Copy
            title="Last-Minute heute freigeben"
            subtitle="Kund:innen können bis 1 Std. vorher buchen"
          />
          <KSwitch
            label="Last-Minute"
            showLabel={false}
            checked={lastMinute}
            onCheckedChange={(v) => {
              setLastMinute(v);
              action(`Last-Minute ${v ? "aktiv" : "inaktiv"} – nur Vorschau`);
            }}
          />
        </div>
        <div className="ud-list-row">
          <Copy
            title="Stammkund:innen erinnern"
            subtitle="3 waren seit über 6 Wochen nicht da"
          />
          <KButton
            variant="secondary"
            onClick={() => action("Erinnerungen ansehen")}
          >
            Ansehen
          </KButton>
        </div>
      </Box>
    </>
  );
}
function UserDashboard({
  state = "full",
  dark = false,
}: {
  state?: DashboardState;
  dark?: boolean;
}) {
  const [period, setPeriod] = useState(30);
  const [notice, setNotice] = useState("");
  const count = period === 7 ? 7 : period === 30 ? 15 : 13;
  const revenue = series(
      count,
      period === 7 ? 120 : period === 30 ? 210 : 900,
      period === 7 ? 70 : 90,
      1,
    ),
    previous = series(
      count,
      period === 7 ? 100 : period === 30 ? 180 : 800,
      60,
      3,
    );
  const action: Action = (message) => setNotice(`Designvorschau: ${message}`);
  return (
    <main className="ud-review" data-state={state}>
      <div className="ud-wrap">
        {state === "fresh" ? (
          <SetupContent action={action} />
        ) : (
          <>
            <header className="ud-header">
              <div>
                <KText as="h1" variant="heading1">
                  Guten Abend, Denis.
                </KText>
                <KText className="ud-muted">
                  Mittwoch, 4. November
                  {state === "full"
                    ? " · 4 Termine heute"
                    : state === "ready"
                      ? " · Deine Seite ist seit 6 Tagen online"
                      : ""}
                </KText>
              </div>
              <KIconButton
                icon="sparkles"
                label="Assistent"
                onClick={() => action("Assistent öffnen")}
              />
            </header>
            {state !== "ready" && (
              <div className="ud-quick">
                <KInline gap="control">
                  {(
                    [
                      ["plus", "Termin"],
                      ["share", "Seite teilen"],
                      ["qr-code", "QR-Code"],
                      ["users", "Kund:in"],
                    ] as [KIconName, string][]
                  ).map(([icon, label], i) => (
                    <KButton
                      key={label}
                      variant={i ? "secondary" : "primary"}
                      onClick={() => action(`${label} öffnen`)}
                    >
                      <KIcon name={icon} size={16} />
                      {label}
                    </KButton>
                  ))}
                </KInline>
              </div>
            )}
            {state === "ready" ? (
              <ReadyContent action={action} />
            ) : (
              <div className="ud-grid">
                <div className="ud-column">
                  {state === "free" ? (
                    <Quiet action={action} />
                  ) : (
                    <Today action={action} />
                  )}
                  <Requests action={action} />
                </div>
                <div className="ud-column ud-next-column">
                  <Next free={state === "free"} dark={dark} action={action} />
                </div>
                <Metrics
                  period={period}
                  onPeriod={setPeriod}
                  revenue={revenue}
                  bookings={series(count, 3, 2, 2)}
                />
                <div className="ud-column">
                  <Revenue
                    revenue={revenue}
                    previous={previous}
                    period={period}
                  />
                  <Week free={state === "free"} />
                </div>
                <div className="ud-column">
                  <Customers action={action} />
                  {state === "full" && <Services />}
                  <Share action={action} />
                </div>
              </div>
            )}
          </>
        )}
        <p className="ud-demo-note">
          Interaktive Designvorschau · synthetische Daten · keine echten
          Aktionen
        </p>
        {notice && (
          <div className="ud-notice" role="status">
            <KIcon name="check" size={16} />
            {notice}
            <KIconButton
              icon="x"
              label="Hinweis schließen"
              onClick={() => setNotice("")}
            />
          </div>
        )}
      </div>
    </main>
  );
}
const meta = {
  title: "Review/UserDashboard",
  component: UserDashboard,
  parameters: { layout: "fullscreen" },
  render: (args, context) => (
    <UserDashboard
      key={args.state}
      {...args}
      dark={context.globals.theme === "dark"}
    />
  ),
} satisfies Meta<typeof UserDashboard>;
export default meta;
type Story = StoryObj<typeof meta>;
export const FullDay: Story = {
  name: "Gefüllter Tag",
  args: { state: "full" },
};
export const FreeDay: Story = { name: "Ruhiger Tag", args: { state: "free" } };
export const Setup: Story = { name: "Neues Konto", args: { state: "fresh" } };
export const Ready: Story = {
  name: "Eingerichtet · keine Buchungen",
  args: { state: "ready" },
};
