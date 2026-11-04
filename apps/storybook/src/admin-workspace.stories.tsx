import { useState, type ReactNode } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KAdaptiveDialog,
  KAvatar,
  KBadge,
  KBarChart,
  KButton,
  KField,
  KIcon,
  KIconButton,
  KInput,
  KLineChart,
  KSearchField,
  KSelect,
  KStack,
  KSwitch,
  KTextarea,
  type KBadgeVariant,
  type KIconName,
} from "@k-design-system/ui";
import * as data from "./admin-workspace-data.js";
import type { AdminPage } from "./admin-workspace-data.js";
import "./admin-workspace.css";

// Gallery composition: synthetic fixtures, no backend requests or production actions.
// Composition map: responsive admin shell -> public K controls/charts/dialog;
// tokenized grouped rows, card insets, typography and section/control spacing.
function Badge({ value }: { value: string }) {
  const variant: KBadgeVariant = [
    "Aktiv",
    "Bezahlt",
    "Freigegeben",
    "Eingelöst",
    "Angenommen",
    "Erfolgreich",
    "Stabil",
    "Zugestellt",
  ].includes(value)
    ? "success"
    : [
          "Gesperrt",
          "Fehlgeschlagen",
          "Abgelehnt",
          "Widerrufen",
          "Gestört",
        ].includes(value)
      ? "destructive"
      : ["Abgelaufen", "Verzögert", "Pausiert", "Gekündigt"].includes(value)
        ? "warning"
        : "secondary";
  return <KBadge variant={variant}>{value}</KBadge>;
}
function Card({ children }: { children: ReactNode }) {
  return <div className="adm-card">{children}</div>;
}
function Group({
  title,
  action,
  children,
}: {
  title: string;
  action?: ReactNode;
  children: ReactNode;
}) {
  return (
    <section className="adm-group">
      <div className="adm-group-heading">
        <h2>{title}</h2>
        {action}
      </div>
      <Card>{children}</Card>
    </section>
  );
}
function Row({
  title,
  subtitle,
  avatar,
  end,
  onClick,
}: {
  title: string;
  subtitle?: string;
  avatar?: string;
  end?: ReactNode;
  onClick?: () => void;
}) {
  const content = (
    <span className="adm-row-layout">
      {avatar && <KAvatar alt={avatar} />}
      <span className="adm-row-copy">
        <strong>{title}</strong>
        {subtitle && <small>{subtitle}</small>}
      </span>
    </span>
  );
  return (
    <div className="adm-row">
      {onClick ? (
        <KButton
          variant="ghost"
          fullWidth
          className="adm-row-trigger"
          onClick={onClick}
        >
          {content}
        </KButton>
      ) : (
        content
      )}
      {end && <span className="adm-row-end">{end}</span>}
    </div>
  );
}
function Chips({
  items,
  value,
  onChange,
}: {
  items: string[];
  value: string;
  onChange: (value: string) => void;
}) {
  return (
    <div className="adm-chips" role="group" aria-label="Status filtern">
      {items.map((item) => (
        <KButton
          key={item}
          variant={value === item ? "primary" : "ghost"}
          aria-pressed={value === item}
          onClick={() => onChange(item)}
        >
          {item}
        </KButton>
      ))}
    </div>
  );
}
function Kpis({ items }: { items: [string, string | number, string][] }) {
  return (
    <div className="adm-kpis">
      {items.map(([label, value, delta]) => (
        <div className="adm-kpi" key={label}>
          <span>{label}</span>
          <strong>{value}</strong>
          {delta && (
            <small data-negative={delta.startsWith("-")}>
              {delta} <span>vs. Vorperiode</span>
            </small>
          )}
        </div>
      ))}
    </div>
  );
}
const series = (n: number, base: number, amp: number, seed: number) =>
  Array.from({ length: n }, (_, i) => ({
    id: String(i),
    x: i,
    y: Math.round(
      base +
        amp * Math.sin(i / 2.3 + seed) +
        ((i * base) / n) * 0.4 +
        ((i * 7 + seed * 13) % 5),
    ),
  }));
function Chart({ bar = false, days = 30 }: { bar?: boolean; days?: number }) {
  const count = bar ? 8 : days === 7 ? 7 : 15;
  const current = {
    id: "current",
    label: "Aktuell",
    colorIndex: 0,
    points: series(count, bar ? 700 : 6, bar ? 120 : 3, 1),
  };
  const previous = {
    id: "previous",
    label: "Vorperiode",
    colorIndex: 1,
    points: series(count, 5, 3, 3),
  };
  const ChartControl = bar ? KBarChart : KLineChart;
  return (
    <section className="adm-chart">
      <h2>{bar ? "Umsatz pro Woche" : "Anmeldungen"}</h2>
      <ChartControl
        label={bar ? "Umsatz pro Woche" : "Anmeldungen aktuell und Vorperiode"}
        height={180}
        series={bar ? [current] : [current, previous]}
        xAxis={{
          min: 0,
          max: count - 1,
          ticks: [0, Math.floor(count / 2), count - 1],
          format: (x) => String(x + 1),
        }}
        yAxis={{
          min: 0,
          max: bar ? 1200 : 18,
          ticks: bar ? [0, 600, 1200] : [0, 9, 18],
          format: (x) => `${x}${bar ? " €" : ""}`,
        }}
      />
    </section>
  );
}
function Breakdown({
  title,
  items,
}: {
  title: string;
  items: [string, number][];
}) {
  return (
    <section className="adm-chart">
      <h2>{title}</h2>
      <KBarChart
        orientation="horizontal"
        label={title}
        height={items.length * 36}
        series={[
          {
            id: title,
            label: title,
            colorIndex: 0,
            points: items.map(([label, value], i) => ({
              id: label,
              x: i,
              y: value,
            })),
          },
        ]}
        xAxis={{
          min: -0.5,
          max: items.length - 0.5,
          ticks: items.map((_, i) => i),
          format: (i) => items[i]?.[0] ?? "",
        }}
        yAxis={{
          min: 0,
          max: Math.max(...items.map((x) => x[1])) * 1.1,
          ticks: [],
          format: String,
        }}
      />
    </section>
  );
}
function KeyValues({ items }: { items: [string, ReactNode][] }) {
  return (
    <Card>
      {items.map(([key, value]) => (
        <div className="adm-kv" key={key}>
          <span>{key}</span>
          <strong
            className={
              ["Empfehlungslink", "E-Mail", "Social-Profil"].includes(key)
                ? "adm-single-line"
                : undefined
            }
            title={typeof value === "string" ? value : undefined}
          >
            {value}
          </strong>
        </div>
      ))}
    </Card>
  );
}
function Select({
  label,
  value,
  values,
  onChange,
}: {
  label: string;
  value: string;
  values: string[];
  onChange: (value: string) => void;
}) {
  return (
    <KSelect
      label={label}
      value={value}
      options={values.map((x) => ({ value: x, label: x }))}
      onValueChange={onChange}
    />
  );
}

export function AdminWorkspace({
  initialPage = "overview",
  overview = false,
}: {
  initialPage?: AdminPage;
  overview?: boolean;
}) {
  const [page, setPage] = useState<AdminPage>(initialPage),
    [hub, setHub] = useState(overview);
  const [period, setPeriod] = useState(30),
    [query, setQuery] = useState(""),
    [filter, setFilter] = useState("Alle");
  const [customers, setCustomers] = useState(data.customers),
    [waitlist, setWaitlist] = useState(data.waitlist),
    [invitations, setInvitations] = useState(data.invitations),
    [applications, setApplications] = useState(data.applications),
    [partners, setPartners] = useState(data.partners),
    [admins, setAdmins] = useState(data.administrators);
  const [registration, setRegistration] = useState(true),
    [inviteOnly, setInviteOnly] = useState(true),
    [notice, setNotice] = useState("");
  const [dialog, setDialog] = useState<{ kind: string; index: number } | null>(
      null,
    ),
    [note, setNote] = useState(""),
    [email, setEmail] = useState(""),
    [role, setRole] = useState("Admin");
  const [provider, setProvider] = useState("OpenRouter"),
    [model, setModel] = useState("Demo-Modell A"),
    [fallback, setFallback] = useState("Demo-Modell B"),
    [apiKey, setApiKey] = useState("");
  const [retry, setRetry] = useState<string[]>([]);
  const notify = (text: string) =>
    setNotice(`${text} · nur in dieser Vorschau`);
  const go = (next: AdminPage) => {
    setPage(next);
    setHub(false);
    setFilter("Alle");
    setQuery("");
    setDialog(null);
    setNotice("");
  };
  const open = (kind: string, index = 0) => {
    setDialog({ kind, index });
    if (kind === "waitlist") setNote(waitlist[index][6]);
  };
  const update = (
    rows: string[][],
    setter: (rows: string[][]) => void,
    index: number,
    column: number,
    value: string,
  ) =>
    setter(
      rows.map((row, i) =>
        i === index ? row.map((cell, j) => (j === column ? value : cell)) : row,
      ),
    );
  const matches = (row: string[], status: string) =>
    (filter === "Alle" || status === filter) &&
    row
      .join(" ")
      .toLocaleLowerCase("de")
      .includes(query.toLocaleLowerCase("de"));
  const pending = waitlist.filter((x) => x[5] === "Neu").length;
  const badgeCount: Partial<Record<AdminPage, number>> = {
    waitlist: pending,
    applications: applications.filter((x) => x[6] === "Neu").length,
    subscriptions: 2,
  };
  const nav = (
    <>
      {data.adminGroups.map(([title, pages]) => (
        <section className="adm-nav-group" key={title}>
          {title && <h2>{title}</h2>}
          <div>
            {pages.map((id) => (
              <KButton
                key={id}
                variant="ghost"
                fullWidth
                className="adm-nav-button"
                aria-current={page === id && !hub ? "page" : undefined}
                onClick={() => go(id)}
              >
                <span className="adm-nav-layout">
                  <span className="adm-nav-icon" data-page={id}>
                    <KIcon name={data.adminPages[id][1]} size={16} />
                  </span>
                  <span className="adm-nav-label">
                    {data.adminPages[id][0]}
                  </span>
                  {badgeCount[id] ? <KBadge>{badgeCount[id]}</KBadge> : null}
                  <span className="adm-nav-chevron">
                    <KIcon name="chevron-right" size={16} />
                  </span>
                </span>
              </KButton>
            ))}
          </div>
        </section>
      ))}
    </>
  );
  const search = (label: string) => (
    <KSearchField
      aria-label={label}
      placeholder={label}
      value={query}
      onChange={(e) => setQuery(e.target.value)}
      clearable
      onClear={() => setQuery("")}
    />
  );
  const empty = <p className="adm-empty">Keine Einträge für diese Auswahl.</p>;
  const action = (label: string, callback: () => void, danger = false) => (
    <KButton
      variant="secondary"
      className={danger ? "adm-danger" : undefined}
      onClick={callback}
    >
      {label}
    </KButton>
  );
  const waitAction = (index: number, status: string) => {
    update(waitlist, setWaitlist, index, 5, status);
    setDialog(null);
    notify(
      status === "Freigegeben"
        ? "Freigegeben und Einladung vorgemerkt"
        : "Anfrage abgelehnt",
    );
  };
  let content: ReactNode;
  switch (page) {
    case "overview":
      content = (
        <>
          <div className="adm-period" role="group" aria-label="Zeitraum">
            {[7, 30, 90].map((days) => (
              <KButton
                key={days}
                variant={period === days ? "secondary" : "ghost"}
                aria-pressed={period === days}
                onClick={() => setPeriod(days)}
              >
                {days} Tage
              </KButton>
            ))}
          </div>
          <Kpis
            items={[
              ["Anmeldungen", Math.round((128 * period) / 30), "+18 %"],
              ["Aktive Betriebe", 412, "+6 %"],
              ["Offene Anfragen", pending + 34, ""],
              [
                "Umsatz",
                `${Math.round((6840 * period) / 30).toLocaleString("de-DE")} €`,
                "+9 %",
              ],
            ]}
          />
          <div className="adm-two">
            <Chart days={period} />
            <Chart bar days={period} />
          </div>
          <Group title="Braucht Aufmerksamkeit">
            <Row
              title={`${pending} neue Wartelisten-Anfragen`}
              subtitle="Älteste vom 03.11."
              onClick={() => go("waitlist")}
              end={<KIcon name="chevron-right" />}
            />
            <Row
              title="2 Zahlungsfehler"
              subtitle="Kund:innen wurden per Mail informiert"
              onClick={() => go("subscriptions")}
              end={<Badge value="Offen" />}
            />
            <Row
              title="Push verzögert"
              subtitle="3 Zustellungen fehlgeschlagen"
              onClick={() => go("operations")}
              end={<Badge value="Verzögert" />}
            />
          </Group>
        </>
      );
      break;
    case "customers": {
      const visible = customers
        .map((row, index) => ({ row, index }))
        .filter(({ row }) => matches(row, row[5]));
      content = (
        <>
          {search("Name, Betrieb, E-Mail …")}
          <Chips
            items={["Alle", "Aktiv", "Testphase", "Gesperrt", "Gekündigt"]}
            value={filter}
            onChange={setFilter}
          />
          <Card>
            {visible.length
              ? visible.map(({ row: x, index }) => (
                  <Row
                    key={x[2]}
                    avatar={x[0]}
                    title={`${x[0]} · ${x[1]}`}
                    subtitle={`${x[2]} · ${x[3]}`}
                    onClick={() => open("customer", index)}
                    end={
                      <>
                        <Badge value={x[4]} />
                        <Badge value={x[5]} />
                      </>
                    }
                  />
                ))
              : empty}
          </Card>
        </>
      );
      break;
    }
    case "access":
      content = (
        <>
          <Group title="Registrierung">
            <Row
              title="Registrierung aktiv"
              subtitle="Neue Konten können angelegt werden."
              end={
                <KSwitch
                  label="Registrierung aktiv"
                  showLabel={false}
                  checked={registration}
                  onCheckedChange={setRegistration}
                />
              }
            />
            <Row
              title="Einladung erforderlich"
              subtitle="Nur mit gültiger Einladung."
              end={
                <KSwitch
                  label="Einladung erforderlich"
                  showLabel={false}
                  checked={inviteOnly}
                  onCheckedChange={setInviteOnly}
                />
              }
            />
          </Group>
          <Group
            title="Administratoren"
            action={
              <KButton variant="ghost" onClick={() => open("admin")}>
                <KIcon name="plus" size={16} />
                Hinzufügen
              </KButton>
            }
          >
            {admins.map((x, i) => (
              <Row
                key={x[1]}
                avatar={x[0]}
                title={x[0]}
                subtitle={x[1]}
                end={
                  x[2] === "Owner" ? (
                    <Badge value="Owner" />
                  ) : (
                    <Select
                      label={`Rolle von ${x[0]}`}
                      value={x[2]}
                      values={data.roles.slice(1).map((r) => r[0])}
                      onChange={(value) =>
                        update(admins, setAdmins, i, 2, value)
                      }
                    />
                  )
                }
              />
            ))}
          </Group>
          <Group title="Rollen">
            {data.roles.map(([title, subtitle]) => (
              <Row key={title} title={title} subtitle={subtitle} />
            ))}
          </Group>
        </>
      );
      break;
    case "growth":
      content = (
        <>
          <Kpis
            items={[
              ["Anmeldungen", 128, "+18 %"],
              ["Warteliste → Konto", "41 %", "+4 %"],
              ["Aktiviert (1. Buchung)", "63 %", "-2 %"],
              ["Über Ambassadors", 74, "+22 %"],
            ]}
          />
          <Chart />
          <div className="adm-two">
            <Breakdown
              title="Quellen"
              items={[
                ["Ambassadors", 74],
                ["Instagram", 52],
                ["TikTok", 31],
                ["Google", 24],
                ["Direkt", 12],
              ]}
            />
            <Breakdown
              title="Länder"
              items={[
                ["Deutschland", 141],
                ["Österreich", 27],
                ["Schweiz", 14],
                ["Türkei", 6],
              ]}
            />
            <Breakdown
              title="Sprachen"
              items={[
                ["Deutsch", 166],
                ["Englisch", 13],
                ["Türkisch", 9],
              ]}
            />
            <Breakdown
              title="Plattformen"
              items={[
                ["iOS", 96],
                ["Android", 71],
                ["Web", 21],
              ]}
            />
          </div>
          <Group title="Kampagnen">
            {[
              [
                "Herbst-Launch Instagram",
                "utm=ig_herbst · 38 Anmeldungen",
                "9 %",
              ],
              ["Friseur-Messe Leipzig", "QR am Stand · 21 Anmeldungen", "34 %"],
              ["Newsletter Oktober", "utm=nl_okt · 9 Anmeldungen", "5 %"],
            ].map((x) => (
              <Row
                key={x[0]}
                title={x[0]}
                subtitle={x[1]}
                end={<strong>{x[2]}</strong>}
              />
            ))}
          </Group>
        </>
      );
      break;
    case "subscriptions":
      content = (
        <>
          <Kpis
            items={[
              ["Monatlicher Umsatz", "6.840 €", "+9 %"],
              ["Aktive Abos", 287, "+5 %"],
              ["In Testphase", 64, "+12 %"],
              ["Zahlungsfehler", 2, ""],
            ]}
          />
          <Group title="Tarife">
            {[
              ["Solo", "19 €/Monat", "141"],
              ["Pro", "39 €/Monat", "118"],
              ["Team", "79 €/Monat", "28"],
            ].map((x) => (
              <Row
                key={x[0]}
                title={x[0]}
                subtitle={`${x[1]} · 14 Tage Testphase`}
                end={<span>{x[2]} Abos</span>}
              />
            ))}
          </Group>
          <Group title="Zahlungsfehler">
            {data.paymentFailures.map((x, i) => (
              <Row
                key={x[0]}
                avatar={x[0]}
                title={x[0]}
                subtitle={x.slice(1).join(" · ")}
                end={action(
                  retry.includes(`pay${i}`) ? "Vorgemerkt" : "Erneut",
                  () => {
                    setRetry([...retry, `pay${i}`]);
                    notify("Zahlungsversuch vorgemerkt");
                  },
                )}
              />
            ))}
          </Group>
          <Group title="Rechnungen">
            {data.invoices.map((x, i) => (
              <Row
                key={x[0]}
                title={`${x[0]} · ${x[2]}`}
                subtitle={x[1]}
                onClick={() => open("invoice", i)}
                end={<Badge value={x[3]} />}
              />
            ))}
          </Group>
        </>
      );
      break;
    case "waitlist": {
      const visible = waitlist
        .map((row, index) => ({ row, index }))
        .filter(({ row }) => matches(row, row[5]));
      content = (
        <>
          <Chips
            items={["Alle", "Neu", "Freigegeben", "Abgelehnt"]}
            value={filter}
            onChange={setFilter}
          />
          <Card>
            {visible.length
              ? visible.map(({ row: x, index }) => (
                  <Row
                    key={x[0]}
                    avatar={x[0]}
                    title={x[0]}
                    subtitle={x.slice(1, 5).join(" · ")}
                    onClick={() => open("waitlist", index)}
                    end={
                      x[5] === "Neu" ? (
                        <>
                          <KButton
                            variant="ghost"
                            aria-label={`Ablehnen: ${x[0]}`}
                            className="adm-danger"
                            onClick={() => waitAction(index, "Abgelehnt")}
                          >
                            <KIcon name="x" size={18} />
                          </KButton>
                          <KButton
                            variant="ghost"
                            aria-label={`Freigeben: ${x[0]}`}
                            className="adm-success"
                            onClick={() => waitAction(index, "Freigegeben")}
                          >
                            <KIcon name="check" size={18} />
                          </KButton>
                        </>
                      ) : (
                        <Badge value={x[5]} />
                      )
                    }
                  />
                ))
              : empty}
          </Card>
        </>
      );
      break;
    }
    case "invitations":
      content = (
        <Card>
          {invitations.map((x, i) => (
            <Row
              key={x[0]}
              avatar={x[0]}
              title={x[0]}
              subtitle={`${x[1]} · läuft ab ${x[2]}`}
              onClick={() => open("invitation", i)}
              end={<Badge value={x[3]} />}
            />
          ))}
        </Card>
      );
      break;
    case "applications":
      content = (
        <Card>
          {applications.map((x, i) => (
            <Row
              key={x[0]}
              avatar={x[0]}
              title={x[0]}
              subtitle={`${x[1]} · ${x[2]} Follower · ${x[3]}`}
              onClick={() => open("application", i)}
              end={<Badge value={x[6]} />}
            />
          ))}
        </Card>
      );
      break;
    case "partners":
      content = (
        <>
          <Kpis
            items={[
              [
                "Aktive Ambassadors",
                partners.filter((x) => x[4] === "Aktiv").length,
                "",
              ],
              ["Vermittelte Anmeldungen", 83, "+22 %"],
            ]}
          />
          <Card>
            {partners.map((x, i) => (
              <Row
                key={x[0]}
                avatar={x[0]}
                title={x[0]}
                subtitle={`${x[1]} · ${x[2]} Anmeldungen · ${x[3]} % Conversion`}
                onClick={() => open("partner", i)}
                end={
                  <>
                    <Badge value={x[4]} />
                    <KButton
                      variant="ghost"
                      aria-label={`Link kopieren: ${x[0]}`}
                      onClick={() =>
                        void navigator.clipboard.writeText(x[1]).then(
                          () => notify("Demo-Link kopiert"),
                          () => notify("Kopieren nicht verfügbar"),
                        )
                      }
                    >
                      <KIcon name="copy" size={18} />
                    </KButton>
                  </>
                }
              />
            ))}
          </Card>
        </>
      );
      break;
    case "operations":
      content = (
        <>
          <Group title="Dienste">
            {data.systems.map((x) => (
              <Row
                key={x[0]}
                title={x[0]}
                subtitle={x[1]}
                end={<Badge value={x[2]} />}
              />
            ))}
          </Group>
          <Group title="Letzte Fehler">
            {data.errors.map((x, i) => (
              <Row
                key={x[0]}
                title={x[0]}
                subtitle={`${x[1]} · ${x[2]}`}
                end={action(
                  retry.includes(`err${i}`) ? "Vorgemerkt" : "Erneut",
                  () => {
                    setRetry([...retry, `err${i}`]);
                    notify("Wiederholung vorgemerkt");
                  },
                )}
              />
            ))}
          </Group>
          <Group title="App-Versionen">
            {data.versions.map((x) => (
              <Row
                key={x[0]}
                title={`${x[0]} · ${x[1]}`}
                subtitle={`${x[2]} der Nutzer:innen auf aktueller Version`}
              />
            ))}
          </Group>
        </>
      );
      break;
    case "assistant":
      content = (
        <>
          <Group title="Konfiguration">
            <div className="adm-form">
              <KStack gap="action" align="stretch">
                <KField label="Anbieter">
                  <Select
                    label="Anbieter"
                    value={provider}
                    values={["OpenRouter", "Anthropic", "OpenAI"]}
                    onChange={setProvider}
                  />
                </KField>
                <KField label="Modell">
                  <Select
                    label="Modell"
                    value={model}
                    values={["Demo-Modell A", "Demo-Modell B", "Demo-Modell C"]}
                    onChange={setModel}
                  />
                </KField>
                <KField label="Ausweichmodell">
                  <Select
                    label="Ausweichmodell"
                    value={fallback}
                    values={["Keines", "Demo-Modell B"]}
                    onChange={setFallback}
                  />
                </KField>
                <div>
                  <span className="adm-field-label">API-Schlüssel</span>
                  <Row
                    title="•••• •••• f3a9"
                    end={
                      <>
                        <Badge value="Hinterlegt" />
                        {action("Ersetzen", () => open("key"))}
                      </>
                    }
                  />
                </div>
              </KStack>
            </div>
          </Group>
          <Group title="Verbindungen">
            <Row
              title="OpenRouter API"
              subtitle="Antwortzeit 820 ms · 1.204 Anfragen heute"
              end={<Badge value="Stabil" />}
            />
            <Row
              title="MCP-Zugänge"
              subtitle="14 aktive Zugänge (Claude Code, Codex)"
              end={<Badge value="Stabil" />}
            />
          </Group>
          <KButton onClick={() => notify("Konfiguration gespeichert")}>
            Speichern
          </KButton>
        </>
      );
      break;
    case "audit": {
      const visible = data.logs.filter((x) => matches(x, x[4]));
      content = (
        <>
          {search("Admin, Aktion, Objekt …")}
          <Chips
            items={["Alle", "Erfolgreich", "Fehlgeschlagen"]}
            value={filter}
            onChange={setFilter}
          />
          <Card>
            {visible.length
              ? visible.map((x, i) => (
                  <Row
                    key={i}
                    avatar={x[0]}
                    title={x[1]}
                    subtitle={`${x[0]} · ${x[2]} · ${x[3]}`}
                    end={<Badge value={x[4]} />}
                  />
                ))
              : empty}
          </Card>
        </>
      );
      break;
    }
  }
  let title = "",
    detail: ReactNode = null,
    actions: ReactNode = null;
  if (dialog) {
    const i = dialog.index;
    if (dialog.kind === "customer") {
      const x = customers[i];
      title = x[0];
      detail = (
        <>
          <KeyValues
            items={[
              ["Betrieb", x[1]],
              ["E-Mail", x[2]],
              ["Beruf", x[3]],
              ["Ort", x[6]],
              ["Tarif", x[4]],
              ["Status", <Badge value={x[5]} />],
              ["Kund:in seit", x[7]],
              ["Buchungen", x[8]],
            ]}
          />
          <p className="adm-hint">
            Gesperrte Betriebe können sich nicht anmelden, ihre Buchungsseite
            ist offline. Bestehende Buchungen bleiben erhalten.
          </p>
        </>
      );
      actions = (
        <>
          {action("Passwort-Link senden", () =>
            notify("Passwort-Link vorgemerkt"),
          )}
          {action(
            x[5] === "Gesperrt" ? "Entsperren" : "Sperren",
            () => {
              update(
                customers,
                setCustomers,
                i,
                5,
                x[5] === "Gesperrt" ? "Aktiv" : "Gesperrt",
              );
              setDialog(null);
              notify("Kundenzugang geändert");
            },
            x[5] !== "Gesperrt",
          )}
        </>
      );
    }
    if (dialog.kind === "waitlist") {
      const x = waitlist[i];
      title = x[0];
      detail = (
        <KStack gap="action" align="stretch">
          <KeyValues
            items={[
              ["Beruf", x[1]],
              ["Herkunft", x[2]],
              ["Sprache", x[3]],
              ["Angefragt", x[4]],
              ["Status", <Badge value={x[5]} />],
            ]}
          />
          <KField label="Notiz (nur intern)">
            <KTextarea value={note} onChange={(e) => setNote(e.target.value)} />
          </KField>
          <KButton
            variant="secondary"
            onClick={() => {
              update(waitlist, setWaitlist, i, 6, note);
              notify("Notiz gespeichert");
            }}
          >
            Notiz speichern
          </KButton>
        </KStack>
      );
      actions =
        x[5] === "Neu" ? (
          <>
            {action("Ablehnen", () => waitAction(i, "Abgelehnt"))}
            <KButton onClick={() => waitAction(i, "Freigegeben")}>
              Freigeben & einladen
            </KButton>
          </>
        ) : null;
    }
    if (dialog.kind === "invitation") {
      const x = invitations[i];
      title = x[0];
      detail = (
        <KeyValues
          items={[
            ["Versand", <Badge value={x[1]} />],
            ["Läuft ab", x[2]],
            ["Einlösung", <Badge value={x[3]} />],
          ]}
        />
      );
      actions =
        x[3] !== "Eingelöst" ? (
          <>
            {action(
              "Widerrufen",
              () => {
                update(invitations, setInvitations, i, 3, "Widerrufen");
                setDialog(null);
                notify("Einladung widerrufen");
              },
              true,
            )}
            <KButton
              onClick={() => {
                setInvitations(
                  invitations.map((r, j) =>
                    j === i ? [r[0], "Versendet", "18.11.2026", "Offen"] : r,
                  ),
                );
                setDialog(null);
                notify("Einladung vorgemerkt");
              }}
            >
              Erneut senden
            </KButton>
          </>
        ) : null;
    }
    if (dialog.kind === "application") {
      const x = applications[i];
      title = x[0];
      detail = (
        <KStack gap="action" align="stretch">
          <KeyValues
            items={[
              ["Social-Profil", x[1]],
              ["Reichweite", `${x[2]} Follower`],
              ["Themen", x[3]],
              ["Sprache", x[4]],
              ["Status", <Badge value={x[6]} />],
            ]}
          />
          <div className="adm-motivation">
            <h3>Motivation</h3>
            <p>{x[5]}</p>
          </div>
        </KStack>
      );
      actions = (
        <>
          {action("Profil prüfen", () => {
            update(applications, setApplications, i, 6, "In Prüfung");
            notify("Profil zur Prüfung markiert");
          })}
          {action("Ablehnen", () => {
            update(applications, setApplications, i, 6, "Abgelehnt");
            setDialog(null);
          })}
          <KButton
            onClick={() => {
              update(applications, setApplications, i, 6, "Angenommen");
              setDialog(null);
              notify("Bewerbung angenommen");
            }}
          >
            Annehmen
          </KButton>
        </>
      );
    }
    if (dialog.kind === "partner") {
      const x = partners[i];
      title = x[0];
      detail = (
        <KeyValues
          items={[
            ["Empfehlungslink", x[1]],
            ["Vermittelte Anmeldungen", x[2]],
            ["Conversion", `${x[3]} %`],
            ["Status", <Badge value={x[4]} />],
          ]}
        />
      );
      actions = (
        <>
          {action(
            "Link kopieren",
            () =>
              void navigator.clipboard.writeText(x[1]).then(
                () => notify("Demo-Link kopiert"),
                () => notify("Kopieren nicht verfügbar"),
              ),
          )}
          {action(x[4] === "Aktiv" ? "Pausieren" : "Aktivieren", () => {
            update(
              partners,
              setPartners,
              i,
              4,
              x[4] === "Aktiv" ? "Pausiert" : "Aktiv",
            );
            setDialog(null);
          })}
        </>
      );
    }
    if (dialog.kind === "admin") {
      title = "Admin hinzufügen";
      detail = (
        <KStack gap="action" align="stretch">
          <KField label="E-Mail">
            <KInput
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="name@example.invalid"
            />
          </KField>
          <KField label="Rolle">
            <Select
              label="Rolle"
              value={role}
              values={data.roles.slice(1).map((x) => x[0])}
              onChange={setRole}
            />
          </KField>
          <p className="adm-hint">
            Demo: Eine Einladung und verpflichtende Zwei-Faktor-Anmeldung sind
            für die Produktintegration vorgesehen.
          </p>
        </KStack>
      );
      actions = (
        <KButton
          disabled={!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)}
          onClick={() => {
            setAdmins([...admins, [email.split("@")[0], email, role]]);
            setEmail("");
            setDialog(null);
            notify("Admin-Einladung vorgemerkt");
          }}
        >
          Einladen
        </KButton>
      );
    }
    if (dialog.kind === "invoice") {
      const x = data.invoices[i];
      title = x[0];
      detail = (
        <KeyValues
          items={[
            ["Betrieb", x[1]],
            ["Betrag", x[2]],
            ["Status", <Badge value={x[3]} />],
          ]}
        />
      );
      actions = action("Schließen", () => setDialog(null));
    }
    if (dialog.kind === "key") {
      title = "API-Schlüssel ersetzen";
      detail = (
        <KField label="Neuer API-Schlüssel">
          <KInput
            type="password"
            autoComplete="off"
            value={apiKey}
            onChange={(e) => setApiKey(e.target.value)}
            placeholder="Nur einen Demo-Wert eingeben"
          />
        </KField>
      );
      actions = (
        <KButton
          disabled={!apiKey.trim()}
          onClick={() => {
            setApiKey("");
            setDialog(null);
            notify("Demo-Schlüssel ersetzt");
          }}
        >
          Ersetzen
        </KButton>
      );
    }
  }
  const primaryItems: [KIconName, string][] = [
    ["house", "Heute"],
    ["calendar", "Kalender"],
    ["inbox", "Eingang"],
    ["shield", "Admin"],
    ["settings", "Mehr"],
  ];
  return (
    <div className="adm-review" data-hub={hub || undefined}>
      <aside className="adm-primary">
        <div className="adm-logo">
          <KIcon name="map-pin" />
          onzeit<span>.</span>
        </div>
        <KStack gap="control">
          {primaryItems.map(([icon, label]) => (
            <KButton
              key={label}
              variant="ghost"
              fullWidth
              className="adm-primary-link"
              aria-current={label === "Admin" ? "page" : undefined}
              onClick={() =>
                label === "Admin"
                  ? setHub(true)
                  : notify(`${label} liegt außerhalb dieser Admin-Vorschau`)
              }
            >
              <span className="adm-mobile-tab-layout">
                <KIcon name={icon} />
                {label}
              </span>
            </KButton>
          ))}
        </KStack>
        <div className="adm-owner">
          <KAvatar alt="Denis Knaack" />
          <span>
            <strong>Denis Knaack</strong>
            <small>Owner</small>
          </span>
        </div>
      </aside>
      <nav className="adm-navigation" aria-label="Adminbereiche">
        <h1>Admin</h1>
        {nav}
      </nav>
      <main className="adm-main">
        <div className="adm-wrap">
          {hub ? (
            <div className="adm-mobile-hub">
              <header className="adm-heading">
                <h1>Admin</h1>
                <p>Plattform, Betriebe und Wachstum.</p>
              </header>
              {nav}
            </div>
          ) : (
            <>
              <KButton
                variant="ghost"
                className="adm-mobile-back"
                onClick={() => setHub(true)}
              >
                <KIcon name="chevron-left" />
                Admin
              </KButton>
              <header className="adm-heading">
                <h1>{data.adminPages[page][0]}</h1>
                <p>{data.adminPages[page][2]}</p>
              </header>
              <div className="adm-content">{content}</div>
            </>
          )}
          <p className="adm-demo-note">
            Interaktive Designvorschau · synthetische Daten · keine echten
            Aktionen
          </p>
        </div>
      </main>
      <nav className="adm-mobile-tabs" aria-label="App-Navigation">
        {primaryItems.map(([icon, label]) => (
          <KButton
            key={label}
            variant="ghost"
            aria-current={label === "Admin" ? "page" : undefined}
            onClick={() =>
              label === "Admin"
                ? setHub(true)
                : notify(`${label} liegt außerhalb dieser Admin-Vorschau`)
            }
          >
            <span className="adm-mobile-tab-layout">
              <KIcon name={icon} />
              <small>{label}</small>
            </span>
          </KButton>
        ))}
      </nav>
      {notice && (
        <div className="adm-notice" role="status">
          <KIcon name="check" size={16} />
          {notice}
          <KButton
            variant="ghost"
            aria-label="Hinweis schließen"
            onClick={() => setNotice("")}
          >
            <KIcon name="x" size={16} />
          </KButton>
        </div>
      )}
      <KAdaptiveDialog
        open={dialog !== null}
        onOpenChange={(value) => {
          if (!value) {
            setDialog(null);
            setApiKey("");
          }
        }}
        title={title}
        headerless
        showClose={false}
        className="adm-dialog"
        bodyClassName="adm-dialog-body"
        actions={
          actions ? (
            <div className="adm-dialog-actions">{actions}</div>
          ) : undefined
        }
      >
        <div className="adm-dialog-heading">
          <h2 aria-hidden="true">{title}</h2>
          <KIconButton
            label="Schließen"
            variant="ghost"
            icon="x"
            onClick={() => {
              setDialog(null);
              setApiKey("");
            }}
          />
        </div>
        {detail}
      </KAdaptiveDialog>
    </div>
  );
}
const meta = {
  title: "Review/AdminWorkspace",
  component: AdminWorkspace,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof AdminWorkspace>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Overview: Story = {};
export const Navigation: Story = { args: { overview: true } };
export const Customers: Story = { args: { initialPage: "customers" } };
export const Access: Story = { args: { initialPage: "access" } };
export const Growth: Story = { args: { initialPage: "growth" } };
export const Subscriptions: Story = { args: { initialPage: "subscriptions" } };
export const Waitlist: Story = { args: { initialPage: "waitlist" } };
export const Invitations: Story = { args: { initialPage: "invitations" } };
export const Applications: Story = { args: { initialPage: "applications" } };
export const Partners: Story = { args: { initialPage: "partners" } };
export const Operations: Story = { args: { initialPage: "operations" } };
export const Assistant: Story = { args: { initialPage: "assistant" } };
export const Audit: Story = { args: { initialPage: "audit" } };
