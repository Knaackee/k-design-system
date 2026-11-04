import { useMemo, useState, type CSSProperties, type ReactNode } from "react";
import {
  KBadge,
  KBreadcrumb,
  KButton,
  KCheckbox,
  KField,
  KIcon,
  KInline,
  KInput,
  KSelect,
  KSlider,
  KStack,
  KSwitch,
  KText,
  type KIconName,
} from "@k-design-system/ui";
import { KMap, type KMapZone } from "@k-design-system/ui/patterns/map";
import {
  createMapStyle,
  LIGHT_MAP_TOKENS,
  DARK_MAP_TOKENS,
} from "@k-design-system/ui/maps";
import { setWorkerUrl } from "maplibre-gl";
import workerUrl from "maplibre-gl/dist/maplibre-gl-worker.mjs?worker&url";
import "maplibre-gl/dist/maplibre-gl.css";
import "@k-design-system/ui/maps.css";
import "./settings-grouped.css";
import "./deployment-overhaul.css";
import { ReviewAdaptiveDialog } from "./review-overlay-preference";
import {
  isEinsatzDate,
  isEinsatzEntryValid,
  isEinsatzZoneValid,
  postalCodeError,
} from "./deployment-overhaul-validation";
import {
  exceptions as initialExceptions,
  zones as initialZones,
  history,
  holidays,
  modes,
  pages,
  type EinsatzPage,
  type SheetKind,
  type Exception,
  type Zone,
} from "./deployment-overhaul-data";

setWorkerUrl(workerUrl);
const dateLabel = (value: string) =>
  !isEinsatzDate(value)
    ? "Datum fehlt"
    : new Intl.DateTimeFormat("de-DE", {
        day: "numeric",
        month: "short",
        timeZone: "UTC",
      }).format(new Date(`${value}T12:00:00Z`));
const modeName = (mode: string) =>
  modes.find((item) => item.value === mode)?.label ?? "Auto";
const typeNames = {
  absence: "Abwesenheit",
  private: "Privat",
  transport: "Wechsel",
  holiday: "Feiertag",
};
const typeIcons: Record<Exception["kind"], KIconName> = {
  absence: "calendar-off",
  private: "user",
  transport: "car",
  holiday: "flag",
};
const addresses = [
  "Akazienweg 4, 92449 Steinberg am See",
  "Akazienweg 4, 93128 Regenstauf",
  "Akazienstraße 4, 93053 Regensburg",
];
const allDays = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"];

function IconTile({ icon, color }: { icon: KIconName; color?: string }) {
  return (
    <span
      className={`do-icon${color ? "" : " do-icon--neutral"}`}
      style={
        color ? ({ "--do-icon-color": color } as CSSProperties) : undefined
      }
    >
      <KIcon name={icon} size={17} />
    </span>
  );
}
function Row({
  title,
  subtitle,
  eyebrow,
  icon,
  color,
  value,
  onClick,
}: {
  title: string;
  subtitle?: string;
  eyebrow?: string;
  icon?: KIconName;
  color?: string;
  value?: ReactNode;
  onClick: () => void;
}) {
  return (
    <KButton variant="ghost" fullWidth className="do-row" onClick={onClick}>
      <span className="do-row-layout">
        {icon && <IconTile icon={icon} color={color} />}
        <span className="do-row-body">
          {eyebrow && <small className="do-row-eyebrow">{eyebrow}</small>}
          <span>{title}</span>
          {subtitle && <small>{subtitle}</small>}
        </span>
        {value && <span className="do-row-value">{value}</span>}
        <KIcon name="chevron-right" size={17} />
      </span>
    </KButton>
  );
}
function Group({
  title,
  action,
  children,
  foot,
}: {
  title: string;
  action?: ReactNode;
  children: ReactNode;
  foot?: string;
}) {
  return (
    <section className="do-group">
      <div className="do-group-heading">
        <KText as="h2" variant="caption">
          {title}
        </KText>
        {action}
      </div>
      {children}
      {foot && (
        <KText variant="caption" as="p" className="do-footnote">
          {foot}
        </KText>
      )}
    </section>
  );
}
function Toggle({
  title,
  hint,
  value,
  onChange,
}: {
  title: string;
  hint?: string;
  value: boolean;
  onChange: (value: boolean) => void;
}) {
  return (
    <div className="do-toggle">
      <span>
        {title}
        {hint && <small>{hint}</small>}
      </span>
      <KSwitch
        showLabel={false}
        label={title}
        checked={value}
        onCheckedChange={onChange}
      />
    </div>
  );
}
function Empty({ title, children }: { title: string; children: ReactNode }) {
  return (
    <div className="do-empty">
      <KText variant="heading5">{title}</KText>
      {children}
    </div>
  );
}

function ZoneMap({
  dark,
  items,
  compact = false,
}: {
  dark: boolean;
  items: Zone[];
  compact?: boolean;
}) {
  const mapStyle = useMemo(
    () => createMapStyle({ tokens: dark ? DARK_MAP_TOKENS : LIGHT_MAP_TOKENS }),
    [dark],
  );
  const mapZones = useMemo<KMapZone[]>(
    () =>
      items
        .filter((zone) => zone.active)
        .map((zone) => {
          // Deterministic gallery geometry, not authoritative postal boundaries.
          const center: [number, number] =
            zone.type === "radius"
              ? [12.178, 49.285]
              : zone.type === "postal"
                ? [12.1016, 49.0134]
                : [12.12, 49.345];
          const points = zone.type === "radius" ? 64 : 6;
          const radius = zone.type === "radius" ? zone.radius : 3;
          const coordinates = Array.from(
            { length: points },
            (_, index): [number, number] => {
              const angle = (index / points) * Math.PI * 2;
              return [
                center[0] +
                  (Math.cos(angle) * radius) /
                    (111.32 * Math.cos((center[1] * Math.PI) / 180)),
                center[1] + (Math.sin(angle) * radius) / 111.32,
              ];
            },
          );
          return {
            id: zone.id,
            name: zone.name,
            color: zone.color,
            coordinates,
            kind: zone.type === "radius" ? "circle" : "polygon",
            ...(zone.type === "radius"
              ? { circle: { center, radiusKm: zone.radius } }
              : {}),
          };
        }),
    [items],
  );
  return (
    <div className={`do-map${compact ? " do-map--compact" : ""}`}>
      <KMap
        mapStyle={mapStyle}
        center={[12.18, 49.2]}
        zoom={9}
        zones={mapZones}
        pins={[
          {
            id: "start",
            label: "Dein Start",
            position: [12.178, 49.285],
            icon: "house",
          },
        ]}
        fitContent
        fitPadding={40}
        fitDurationMs={0}
        label="Beispielgebiete in der Oberpfalz"
      />
      {items.length > 0 && (
        <div className="do-map-legend">
          {items.map((zone) => (
            <span key={zone.id}>
              <i style={{ background: zone.color }} />
              {zone.name}
            </span>
          ))}
        </div>
      )}
    </div>
  );
}

export function DeploymentOverhaul({
  initialPage = "times",
  empty = false,
  dark = false,
  initialSheet,
}: {
  initialPage?: EinsatzPage;
  empty?: boolean;
  dark?: boolean;
  initialSheet?: SheetKind;
}) {
  const [page, setPage] = useState(initialPage);
  const [sheet, setSheet] = useState<SheetKind | null>(initialSheet ?? null);
  const [address, setAddress] = useState(empty ? "" : addresses[0]);
  const [endAddress, setEndAddress] = useState(addresses[0]);
  const [addressDraft, setAddressDraft] = useState(addresses[0]);
  const [endSame, setEndSame] = useState(true);
  const [mode, setMode] = useState("car");
  const [exceptions, setExceptions] = useState<Exception[]>(
    empty ? [] : initialExceptions,
  );
  const [zones, setZones] = useState<Zone[]>(empty ? [] : initialZones);
  const [past, setPast] = useState(false);
  const [filter, setFilter] = useState("Alle");
  const [entry, setEntry] = useState<Exception>(initialExceptions[0]);
  const [zone, setZone] = useState<Zone>(initialZones[0]);
  const [postalDraft, setPostalDraft] = useState("");
  const [postalError, setPostalError] = useState("");
  const [log, setLog] = useState(history[0]);
  const [year, setYear] = useState("2026");
  const [region, setRegion] = useState("Bayern");
  const [selectedHolidays, setSelectedHolidays] = useState<string[]>([
    "2026-12-25",
    "2026-12-26",
  ]);
  const [notice, setNotice] = useState("");
  const [confirmDelete, setConfirmDelete] = useState(false);
  const current = pages.find((item) => item.id === page)!;
  const visibleExceptions = exceptions
    .filter((item) =>
      past ? item.date < "2026-11-03" : item.until >= "2026-11-03",
    )
    .sort((a, b) => a.date.localeCompare(b.date));
  const changeEntry = (patch: Partial<Exception>) =>
    setEntry((previous) => ({ ...previous, ...patch }));
  const changeZone = (patch: Partial<Zone>) =>
    setZone((previous) => ({ ...previous, ...patch }));
  const close = () => {
    setSheet(null);
    setConfirmDelete(false);
  };
  function open(kind: SheetKind) {
    setConfirmDelete(false);
    setPostalDraft("");
    setPostalError("");
    setSheet(kind);
    if (kind === "start" || kind === "end")
      setAddressDraft(kind === "start" ? address : endAddress);
  }
  function addPostalCode() {
    const error = postalCodeError(postalDraft, zone.postal);
    setPostalError(error);
    if (error) return;
    changeZone({ postal: [...zone.postal, postalDraft.trim()].sort() });
    setPostalDraft("");
  }
  function add(kind: "absence" | "private" | "transport") {
    setEntry({
      ...initialExceptions[0],
      id: "",
      kind,
      title: "",
      address: "",
      date: "2026-11-09",
      until: "2026-11-09",
      allDay: kind === "absence",
    });
    open(kind);
  }
  function edit(item: Exception) {
    setEntry({ ...item });
    open(item.kind === "holiday" ? "absence" : item.kind);
  }
  function newZone(type: Zone["type"]) {
    setZone({
      ...initialZones[0],
      id: "",
      name: "",
      type,
      postal: [],
      days: ["Mo", "Di", "Mi", "Do", "Fr"],
    });
    open("zone");
  }
  function save() {
    if (invalid) return;
    if (sheet === "start") setAddress(addressDraft.trim());
    if (sheet === "end") setEndAddress(addressDraft.trim());
    if (["absence", "private", "transport"].includes(sheet ?? ""))
      setExceptions((previous) => [
        ...previous.filter((item) => item.id !== entry.id),
        { ...entry, id: entry.id || `fixture-${Date.now()}` },
      ]);
    if (sheet === "zone")
      setZones((previous) => [
        ...previous.filter((item) => item.id !== zone.id),
        { ...zone, id: zone.id || `fixture-zone-${Date.now()}` },
      ]);
    close();
    setNotice("Änderung in dieser Vorschau übernommen.");
  }
  function remove() {
    if (!confirmDelete) {
      setConfirmDelete(true);
      return;
    }
    if (sheet === "zone")
      setZones((items) => items.filter((item) => item.id !== zone.id));
    else setExceptions((items) => items.filter((item) => item.id !== entry.id));
    close();
    setNotice("Eintrag aus dieser Vorschau entfernt.");
  }
  const entryInvalid = !isEinsatzEntryValid(entry, sheet === "transport");
  const invalid =
    sheet === "start" || sheet === "end"
      ? !addressDraft.trim()
      : sheet === "zone"
        ? !isEinsatzZoneValid(zone)
        : entryInvalid;
  const titles: Record<SheetKind, string> = {
    start: "Startadresse",
    end: "Endadresse",
    mode: "Unterwegs mit",
    add: "Hinzufügen",
    absence: "Abwesenheit",
    private: "Privater Termin",
    transport: "Verkehrsmittel wechseln",
    holidays: "Feiertage übernehmen",
    newZone: "Neue Zone",
    zone: zone.id ? "Zone bearbeiten" : "Neue Zone",
    history: log.title,
    historyPreview: "Vorschau damals",
    undo: "Rückgängig machen?",
  };
  const isForm = [
    "start",
    "end",
    "absence",
    "private",
    "transport",
    "zone",
  ].includes(sheet ?? "");
  const newZoneOptions = (
    <KStack gap="control">
      {(
        [
          [
            "radius",
            "Umkreis",
            "Ein Radius um deine Startadresse. In 10 Sekunden fertig.",
            "circle",
          ],
          [
            "postal",
            "Postleitzahlen",
            "PLZ-Gebiete auswählen, z. B. für eine Stadt.",
            "grid-2x2",
          ],
          [
            "polygon",
            "Eigene Fläche",
            "Gebiet frei auf der Karte zeichnen.",
            "hexagon",
          ],
        ] as const
      ).map(([type, title, subtitle, icon]) => (
        <Row
          key={type}
          title={title}
          subtitle={subtitle}
          icon={icon}
          color={
            type === "radius"
              ? "#0ea5e9"
              : type === "postal"
                ? "#8b5cf6"
                : "#f59e0b"
          }
          onClick={() => newZone(type)}
        />
      ))}
    </KStack>
  );

  return (
    <div data-theme={dark ? "dark" : "light"}>
      <div className="sg-review do-review">
        <aside className="do-navigation">
          <KText variant="heading3">Verwaltung</KText>
          <KText variant="caption">Einsatz</KText>
          <div className="do-card">
            {pages.map((item) => (
              <Row
                key={item.id}
                title={item.title}
                icon={item.icon}
                color={item.color}
                onClick={() => {
                  setPage(item.id);
                  setNotice("");
                }}
              />
            ))}
          </div>
          <KText variant="caption" className="do-preview-note">
            Interaktive Designvorschau · keine produktiven Änderungen
          </KText>
        </aside>
        <main className="do-main">
          <div className="do-content">
            <div className="do-mobile-nav">
              <KInline gap="control" wrap>
                {pages.map((item) => (
                  <KButton
                    key={item.id}
                    variant={page === item.id ? "secondary" : "ghost"}
                    onClick={() => setPage(item.id)}
                  >
                    {item.title}
                  </KButton>
                ))}
              </KInline>
            </div>
            <KBreadcrumb
              items={[
                {
                  id: "management",
                  label: "Verwaltung",
                  onSelect: () => setPage("times"),
                },
                { id: page, label: current.title },
              ]}
            />
            <header className="do-heading">
              <div>
                <KText as="h1" variant="heading2">
                  {current.title}
                </KText>
                <KText>{current.description}</KText>
              </div>
              {page === "zones" && (
                <KButton onClick={() => open("newZone")}>
                  <KIcon name="plus" size={17} />
                  Zone
                </KButton>
              )}
            </header>
            {notice && (
              <div role="status" className="do-notice">
                <KIcon name="check" size={18} />
                {notice}
              </div>
            )}
            {page === "times" && (
              <>
                <Group
                  title="Tagesstart"
                  foot="Von hier berechnen wir die Anfahrt zum ersten und die Rückfahrt vom letzten Termin."
                >
                  {address ? (
                    <div className="do-card">
                      <Row
                        title={address}
                        eyebrow="Start"
                        icon="house"
                        onClick={() => open("start")}
                      />
                      <div className="do-inset do-return-row">
                        <IconTile icon="flag" />
                        <Toggle
                          title="Am Startort enden"
                          hint="Rückfahrt nach dem letzten Termin einplanen"
                          value={endSame}
                          onChange={setEndSame}
                        />
                      </div>
                      {!endSame && (
                        <Row
                          title={endAddress || "Endadresse festlegen"}
                          eyebrow="Ende"
                          icon="flag"
                          onClick={() => open("end")}
                        />
                      )}
                      <Row
                        title="Unterwegs mit"
                        icon={
                          modes.find((item) => item.value === mode)?.icon ??
                          "car"
                        }
                        value={modeName(mode)}
                        onClick={() => open("mode")}
                      />
                    </div>
                  ) : (
                    <Empty title="Wo startet dein Tag?">
                      <KText>
                        Ohne Startadresse können wir keine Anfahrten berechnen.
                      </KText>
                      <KButton onClick={() => open("start")}>
                        <KIcon name="map-pin" />
                        Startadresse festlegen
                      </KButton>
                    </Empty>
                  )}
                </Group>
                <Group
                  title="Einsatzzeiten"
                  foot="Wann du wo buchbar bist, legst du pro Zone fest. Hier trägst du nur Abweichungen ein."
                >
                  <div className="do-card">
                    <Row
                      title="Wochenzeiten je Zone"
                      subtitle={
                        zones.length
                          ? `${zones.filter((item) => item.active).length} aktiv · Mo–Fr / Di, Do`
                          : "Lege zuerst eine Zone an"
                      }
                      icon="hexagon"
                      color="#ca8a04"
                      onClick={() => setPage("zones")}
                    />
                  </div>
                </Group>
                <Group
                  title="Ausnahmen & Termine"
                  action={
                    <KInline gap="control">
                      <KButton variant="ghost" onClick={() => open("holidays")}>
                        <KIcon name="flag" size={15} />
                        Feiertage
                      </KButton>
                      <KButton variant="ghost" onClick={() => open("add")}>
                        <KIcon name="plus" size={15} />
                        Hinzufügen
                      </KButton>
                    </KInline>
                  }
                >
                  {!exceptions.length ? (
                    <Empty title="Keine Ausnahmen">
                      <KText>
                        Trag Urlaub, private Termine oder Feiertage ein. In
                        dieser Zeit kann dich niemand buchen.
                      </KText>
                      <KInline gap="action" wrap>
                        <KButton onClick={() => open("add")}>
                          Hinzufügen
                        </KButton>
                        <KButton
                          variant="secondary"
                          onClick={() => open("holidays")}
                        >
                          Feiertage übernehmen
                        </KButton>
                      </KInline>
                    </Empty>
                  ) : (
                    <>
                      <div className="do-chips">
                        <KButton
                          variant={!past ? "primary" : "ghost"}
                          onClick={() => setPast(false)}
                        >
                          Kommend ·{" "}
                          {
                            exceptions.filter(
                              (item) => item.until >= "2026-11-03",
                            ).length
                          }
                        </KButton>
                        <KButton
                          variant={past ? "primary" : "ghost"}
                          onClick={() => setPast(true)}
                        >
                          Vergangen ·{" "}
                          {
                            exceptions.filter(
                              (item) => item.until < "2026-11-03",
                            ).length
                          }
                        </KButton>
                      </div>
                      {visibleExceptions.length ? (
                        <>
                          {[
                            ...new Set(
                              visibleExceptions.map((item) =>
                                item.date.slice(0, 7),
                              ),
                            ),
                          ].map((month) => (
                            <div className="do-month-group" key={month}>
                              <KText
                                as="h3"
                                variant="caption"
                                className="do-month-heading"
                              >
                                {new Intl.DateTimeFormat("de-DE", {
                                  month: "long",
                                  year: "numeric",
                                  timeZone: "UTC",
                                }).format(new Date(`${month}-01T12:00:00Z`))}
                              </KText>
                              <div className="do-card">
                                {visibleExceptions
                                  .filter((item) => item.date.startsWith(month))
                                  .map((item) => (
                                    <KButton
                                      key={item.id}
                                      variant="ghost"
                                      fullWidth
                                      className="do-row"
                                      onClick={() => edit(item)}
                                    >
                                      <span className="do-exception">
                                        <span className="do-date">
                                          <small>
                                            {new Intl.DateTimeFormat("de-DE", {
                                              weekday: "short",
                                              timeZone: "UTC",
                                            }).format(new Date(item.date))}
                                          </small>
                                          <b>{Number(item.date.slice(-2))}</b>
                                        </span>
                                        <span className="do-row-body">
                                          <span>
                                            {item.kind === "transport"
                                              ? `${modeName(item.mode)} weiter`
                                              : item.title}
                                          </span>
                                          <small>
                                            {item.allDay
                                              ? item.date === item.until
                                                ? "Ganztägig"
                                                : `${dateLabel(item.date)} – ${dateLabel(item.until)}`
                                              : `${item.from}–${item.to}`}
                                            {item.address &&
                                              ` · ${item.address}`}
                                          </small>
                                        </span>
                                        <span
                                          className={`do-type do-type--${item.kind}`}
                                        >
                                          <KIcon
                                            name={typeIcons[item.kind]}
                                            size={13}
                                          />
                                          {typeNames[item.kind]}
                                        </span>
                                        <KIcon name="chevron-right" size={17} />
                                      </span>
                                    </KButton>
                                  ))}
                              </div>
                            </div>
                          ))}
                        </>
                      ) : (
                        <Empty title="Nichts geplant.">
                          <KText>
                            Für diesen Zeitraum sind keine Ausnahmen vorhanden.
                          </KText>
                        </Empty>
                      )}
                    </>
                  )}
                </Group>
              </>
            )}
            {page === "zones" && (
              <div className="do-zones">
                <ZoneMap dark={dark} items={zones} />
                <div>
                  {zones.length ? (
                    <>
                      <div className="do-card">
                        {zones.map((item) => (
                          <Row
                            key={item.id}
                            title={item.name}
                            subtitle={`${item.type === "radius" ? `${item.radius} km Umkreis` : item.type === "postal" ? `${item.postal.length} Postleitzahlen` : "Eigene Fläche"} · ${item.days.join(", ")} · ${item.from}–${item.to}${Number(item.fee) ? ` · +${item.fee} € Anfahrt` : ""}`}
                            icon="circle"
                            color={item.color}
                            value={
                              !item.active ? (
                                <KBadge>Pausiert</KBadge>
                              ) : undefined
                            }
                            onClick={() => {
                              setZone({ ...item });
                              open("zone");
                            }}
                          />
                        ))}
                      </div>
                      <KText as="p" variant="caption" className="do-footnote">
                        Gebiete, Zeiten und Buchungsregeln gelten gemeinsam.
                        Bereits bestätigte Termine bleiben bestehen.
                      </KText>
                    </>
                  ) : (
                    <div className="do-card do-inset">
                      <KText variant="heading4">
                        Erstelle deine erste Zone
                      </KText>
                      <KText>
                        Lege fest, wo du arbeitest. Zeiten und Regeln stellst du
                        danach pro Zone ein.
                      </KText>
                      {newZoneOptions}
                    </div>
                  )}
                </div>
              </div>
            )}
            {page === "history" && (
              <>
                {!empty && (
                  <div className="do-chips">
                    {[
                      "Alle",
                      "Angebot",
                      "Zeiten",
                      "Zonen",
                      "Buchungsseite",
                    ].map((item) => (
                      <KButton
                        key={item}
                        variant={filter === item ? "primary" : "ghost"}
                        onClick={() => setFilter(item)}
                      >
                        {item}
                      </KButton>
                    ))}
                  </div>
                )}
                {empty ? (
                  <Empty title="Noch keine Änderungen">
                    <KText>
                      Sobald du Angebot, Zeiten, Zonen oder deine Buchungsseite
                      änderst, siehst du hier, wer was wann geändert hat.
                    </KText>
                  </Empty>
                ) : (
                  ["Heute", "Gestern"].map((day) => {
                    const entries = history.filter(
                      (item) =>
                        item.day === day &&
                        (filter === "Alle" || filter === item.area),
                    );
                    return (
                      !!entries.length && (
                        <Group key={day} title={day}>
                          <div className="do-card">
                            {entries.map((item) => (
                              <Row
                                key={item.id}
                                title={item.title}
                                subtitle={`${item.time} · Denis Knaack · ${item.changes.map((change) => change[0]).join(", ")}`}
                                icon={item.icon}
                                color={item.color}
                                value={
                                  item.published ? (
                                    <KBadge>Veröffentlicht</KBadge>
                                  ) : undefined
                                }
                                onClick={() => {
                                  setLog(item);
                                  open("history");
                                }}
                              />
                            ))}
                          </div>
                        </Group>
                      )
                    );
                  })
                )}
              </>
            )}
          </div>
        </main>
        <ReviewAdaptiveDialog
          open={sheet !== null}
          onOpenChange={(value) => !value && close()}
          title={sheet ? titles[sheet] : ""}
          closeLabel="Schließen"
          preferPageSheet={sheet !== "undo"}
          className="sg-review do-dialog"
          actions={
            isForm ? (
              <div className="do-footer">
                {(sheet === "zone" && zone.id) ||
                (["absence", "private", "transport"].includes(sheet ?? "") &&
                  entry.id) ? (
                  <KButton
                    variant="ghost"
                    className="do-danger"
                    onClick={remove}
                  >
                    <KIcon name="trash" size={17} />
                    {confirmDelete ? "Löschen bestätigen" : "Löschen"}
                  </KButton>
                ) : (
                  <span className="do-timezone">
                    <KIcon name="globe" size={15} />
                    Europe/Berlin
                  </span>
                )}
                <KInline gap="control" wrap>
                  <KButton variant="secondary" onClick={close}>
                    Abbrechen
                  </KButton>
                  <KButton disabled={invalid} onClick={save}>
                    Speichern
                  </KButton>
                </KInline>
              </div>
            ) : undefined
          }
        >
          <KStack gap="action" align="stretch">
            {(sheet === "start" || sheet === "end") && (
              <>
                <KField label="Adresse" required>
                  <KInput
                    value={addressDraft}
                    onChange={(event) => setAddressDraft(event.target.value)}
                    placeholder="Straße, PLZ Ort"
                  />
                </KField>
                <div className="do-card">
                  {addresses.map((item) => (
                    <Row
                      key={item}
                      title={item}
                      icon="map-pin"
                      onClick={() => setAddressDraft(item)}
                    />
                  ))}
                </div>
                <KText variant="caption">
                  Nur für die Berechnung der Anfahrt. Kund:innen sehen deine
                  Adresse nicht.
                </KText>
              </>
            )}
            {sheet === "mode" && (
              <>
                <KText>
                  Damit berechnen wir deine Fahrzeiten. Für einzelne Tage kannst
                  du unter „Ausnahmen“ wechseln.
                </KText>
                <div className="do-mode-options">
                  {modes.map((item) => (
                    <KButton
                      key={item.value}
                      variant={mode === item.value ? "primary" : "secondary"}
                      onClick={() => {
                        setMode(item.value);
                        close();
                      }}
                    >
                      <span className="do-mode">
                        <KIcon name={item.icon} size={28} />
                        {item.label}
                      </span>
                    </KButton>
                  ))}
                </div>
              </>
            )}
            {sheet === "add" && (
              <div className="do-card">
                <Row
                  title="Abwesenheit"
                  subtitle="Urlaub, Fortbildung oder freie Zeit"
                  icon="calendar-off"
                  color="#f59e0b"
                  onClick={() => add("absence")}
                />
                <Row
                  title="Privater Termin"
                  subtitle="Zeit und Anfahrt mit einplanen"
                  icon="user"
                  color="#8b5cf6"
                  onClick={() => add("private")}
                />
                <Row
                  title="Verkehrsmittel wechseln"
                  subtitle="Für den restlichen Tag anders unterwegs"
                  icon="car"
                  color="#0ea5e9"
                  onClick={() => add("transport")}
                />
                <Row
                  title="Feiertage übernehmen"
                  subtitle="Feiertage für deine Region auswählen"
                  icon="flag"
                  color="#16a34a"
                  onClick={() => open("holidays")}
                />
              </div>
            )}
            {(sheet === "absence" ||
              sheet === "private" ||
              sheet === "transport") && (
              <>
                {sheet !== "transport" && (
                  <KField
                    label={
                      sheet === "private"
                        ? "Bezeichnung (nur für dich)"
                        : "Grund (nur für dich)"
                    }
                    required
                  >
                    <KInput
                      value={entry.title}
                      onChange={(event) =>
                        changeEntry({ title: event.target.value })
                      }
                      placeholder={
                        sheet === "private" ? "z. B. Zahnarzt" : "z. B. Urlaub"
                      }
                    />
                  </KField>
                )}
                <div className="do-two">
                  <KField label="Von" required>
                    <KInput
                      type="date"
                      value={entry.date}
                      onChange={(event) =>
                        changeEntry({
                          date: event.target.value,
                          until:
                            entry.until < event.target.value
                              ? event.target.value
                              : entry.until,
                        })
                      }
                    />
                  </KField>
                  {sheet !== "transport" ? (
                    <KField label="Bis" required>
                      <KInput
                        type="date"
                        value={entry.until}
                        onChange={(event) =>
                          changeEntry({ until: event.target.value })
                        }
                      />
                    </KField>
                  ) : (
                    <KField label="Ab" required>
                      <KInput
                        type="time"
                        value={entry.from}
                        onChange={(event) =>
                          changeEntry({ from: event.target.value })
                        }
                      />
                    </KField>
                  )}
                </div>
                {sheet === "absence" && (
                  <Toggle
                    title="Ganztägig"
                    value={entry.allDay}
                    onChange={(value) => changeEntry({ allDay: value })}
                  />
                )}
                {sheet !== "transport" && !entry.allDay && (
                  <div className="do-two">
                    <KField label="Von">
                      <KInput
                        type="time"
                        value={entry.from}
                        onChange={(event) =>
                          changeEntry({ from: event.target.value })
                        }
                      />
                    </KField>
                    <KField label="Bis">
                      <KInput
                        type="time"
                        value={entry.to}
                        onChange={(event) =>
                          changeEntry({ to: event.target.value })
                        }
                      />
                    </KField>
                  </div>
                )}
                {sheet === "transport" && (
                  <>
                    <KText variant="label">Danach unterwegs mit</KText>
                    <div className="do-mode-options">
                      {modes.map((item) => (
                        <KButton
                          key={item.value}
                          variant={
                            entry.mode === item.value ? "primary" : "secondary"
                          }
                          onClick={() => changeEntry({ mode: item.value })}
                        >
                          <span className="do-mode">
                            <KIcon name={item.icon} size={26} />
                            {item.label}
                          </span>
                        </KButton>
                      ))}
                    </div>
                    <KField
                      label="Zeit für den Wechsel"
                      helperText="z. B. Parkplatz suchen, Rad abschließen"
                    >
                      <KInput
                        type="number"
                        min={0}
                        max={120}
                        step={5}
                        value={entry.minutes}
                        onChange={(event) =>
                          changeEntry({ minutes: Number(event.target.value) })
                        }
                      />
                    </KField>
                  </>
                )}
                {(sheet === "private" || sheet === "transport") && (
                  <KField
                    required
                    label={sheet === "private" ? "Adresse" : "Wo wechselst du?"}
                    helperText="Wir planen die Anfahrt vom Termin davor und zum Termin danach ein."
                  >
                    <KInput
                      value={entry.address}
                      onChange={(event) =>
                        changeEntry({ address: event.target.value })
                      }
                      placeholder="Straße, PLZ Ort"
                    />
                  </KField>
                )}
                {sheet === "private" && (
                  <div className="do-info">
                    <KIcon name="eye" size={18} />
                    <span>
                      Kund:innen sehen nur, dass du belegt bist – nicht die
                      Bezeichnung.
                    </span>
                  </div>
                )}
                <div className="do-info">
                  <KIcon name="info" size={18} />
                  <span>
                    Bestehende Buchungen bleiben bestehen. Die Anwendung prüft
                    beim Speichern die tatsächlichen Konflikte.
                  </span>
                </div>
                {entry.date > entry.until && (
                  <KText className="do-danger">
                    Das Ende liegt vor dem Beginn.
                  </KText>
                )}
              </>
            )}
            {sheet === "holidays" && (
              <>
                <div className="do-two">
                  <KField label="Land">
                    <KSelect
                      value="de"
                      options={[{ value: "de", label: "Deutschland" }]}
                    />
                  </KField>
                  <KField label="Bundesland">
                    <KSelect
                      value={region}
                      options={["Bayern", "Berlin", "Hamburg"].map((value) => ({
                        value,
                        label: value,
                      }))}
                      onValueChange={setRegion}
                    />
                  </KField>
                </div>
                <div className="do-chips">
                  {["2026", "2027"].map((value) => (
                    <KButton
                      key={value}
                      variant={year === value ? "primary" : "secondary"}
                      onClick={() => setYear(value)}
                    >
                      {value}
                    </KButton>
                  ))}
                </div>
                <div className="do-card">
                  {holidays
                    .filter(
                      (item) =>
                        item.date.startsWith(year) &&
                        (item.scope === "bundesweit" || item.scope === region),
                    )
                    .map((item) => (
                      <div key={item.date} className="do-holiday">
                        <KCheckbox
                          label={item.title}
                          value={selectedHolidays.includes(item.date)}
                          onValueChange={(checked) =>
                            setSelectedHolidays((previous) =>
                              checked
                                ? [...previous, item.date]
                                : previous.filter((date) => date !== item.date),
                            )
                          }
                        />
                        <small>
                          {dateLabel(item.date)} · {item.scope}
                        </small>
                      </div>
                    ))}
                </div>
                <KText variant="caption">
                  Beispielauswahl für die Designprüfung. In der App werden die
                  echten regionalen Feiertage geladen.
                </KText>
                <KButton
                  onClick={() => {
                    const selected = holidays.filter(
                      (item) =>
                        selectedHolidays.includes(item.date) &&
                        item.date.startsWith(year) &&
                        (item.scope === "bundesweit" || item.scope === region),
                    );
                    setExceptions((previous) => [
                      ...previous,
                      ...selected
                        .filter(
                          (item) =>
                            !previous.some(
                              (existing) =>
                                existing.id === `holiday-${item.date}`,
                            ),
                        )
                        .map((item) => ({
                          ...initialExceptions[0],
                          id: `holiday-${item.date}`,
                          kind: "holiday" as const,
                          title: item.title,
                          date: item.date,
                          until: item.date,
                          allDay: true,
                          address: "",
                        })),
                    ]);
                    close();
                  }}
                >
                  Auswahl übernehmen
                </KButton>
              </>
            )}
            {sheet === "newZone" && newZoneOptions}
            {sheet === "zone" && (
              <>
                <ZoneMap dark={dark} items={[zone]} compact />
                <KField label="Name" required>
                  <KInput
                    value={zone.name}
                    onChange={(event) =>
                      changeZone({ name: event.target.value })
                    }
                    placeholder="z. B. Regensburg Innenstadt"
                  />
                </KField>
                <KText variant="label" className="do-section-title">
                  Gebiet
                </KText>
                <div className="do-chips do-zone-type">
                  {(
                    [
                      ["radius", "Umkreis"],
                      ["postal", "Postleitzahlen"],
                      ["polygon", "Eigene Fläche"],
                    ] as const
                  ).map(([value, label]) => (
                    <KButton
                      key={value}
                      variant={zone.type === value ? "primary" : "secondary"}
                      onClick={() => changeZone({ type: value })}
                    >
                      {label}
                    </KButton>
                  ))}
                </div>
                {zone.type === "radius" ? (
                  <KStack gap="control" align="stretch">
                    <KInline
                      gap="control"
                      wrap
                      style={{ justifyContent: "space-between" }}
                    >
                      <KText variant="label">
                        Luftlinie um deine Startadresse
                      </KText>
                      <KText variant="label">{zone.radius} km</KText>
                    </KInline>
                    <KSlider
                      label="Luftlinie um deine Startadresse"
                      min={3}
                      max={40}
                      value={zone.radius}
                      onValueChange={(value) => changeZone({ radius: value })}
                      valueLabel={(value) => `${value} km`}
                    />
                  </KStack>
                ) : zone.type === "postal" ? (
                  <KStack gap="control" align="stretch">
                    <KField
                      label="Postleitzahl hinzufügen"
                      errorText={postalError}
                      helperText="Fünfstellig, z. B. 93059. Die Gebietsgrenzen werden in dieser Vorschau nicht geladen."
                    >
                      <div className="do-postal-input">
                        <KInput
                          value={postalDraft}
                          inputMode="numeric"
                          autoComplete="postal-code"
                          placeholder="z. B. 93059"
                          onChange={(event) => {
                            setPostalDraft(event.target.value);
                            setPostalError("");
                          }}
                          onKeyDown={(event) => {
                            if (event.key === "Enter") {
                              event.preventDefault();
                              addPostalCode();
                            }
                          }}
                        />
                        <KButton variant="secondary" onClick={addPostalCode}>
                          <KIcon name="plus" size={17} />
                          Hinzufügen
                        </KButton>
                      </div>
                    </KField>
                    <KInline gap="control" wrap>
                      {zone.postal.map((value) => (
                        <KButton
                          key={value}
                          variant="secondary"
                          aria-label={`Postleitzahl ${value} entfernen`}
                          onClick={() =>
                            changeZone({
                              postal: zone.postal.filter(
                                (item) => item !== value,
                              ),
                            })
                          }
                        >
                          {value}
                          <KIcon name="x" size={15} />
                        </KButton>
                      ))}
                    </KInline>
                    {!zone.postal.length && (
                      <KText variant="caption">
                        Füge mindestens eine Postleitzahl hinzu.
                      </KText>
                    )}
                  </KStack>
                ) : (
                  <KText variant="caption">
                    Die freie Fläche wird in der App im vorhandenen
                    KMap-Zoneneditor bearbeitet. Diese Galerie zeigt die
                    Formulargestaltung.
                  </KText>
                )}
                <KText variant="label" className="do-section-title">
                  Einsatzzeiten
                </KText>
                <KField label="Zeiten übernehmen von">
                  <KSelect
                    value={null}
                    placeholder="Zone auswählen"
                    options={zones
                      .filter((item) => item.id !== zone.id)
                      .map((item) => ({ value: item.id, label: item.name }))}
                    onValueChange={(value) => {
                      const source = zones.find((item) => item.id === value);
                      if (source)
                        changeZone({
                          days: [...source.days],
                          from: source.from,
                          to: source.to,
                        });
                    }}
                  />
                </KField>
                <div className="do-days">
                  {allDays.map((value) => (
                    <KButton
                      key={value}
                      variant={
                        zone.days.includes(value) ? "primary" : "secondary"
                      }
                      onClick={() =>
                        changeZone({
                          days: zone.days.includes(value)
                            ? zone.days.filter((item) => item !== value)
                            : [...zone.days, value],
                        })
                      }
                    >
                      {value}
                    </KButton>
                  ))}
                </div>
                <div className="do-two">
                  <KField label="Von">
                    <KInput
                      type="time"
                      value={zone.from}
                      onChange={(event) =>
                        changeZone({ from: event.target.value })
                      }
                    />
                  </KField>
                  <KField label="Bis">
                    <KInput
                      type="time"
                      value={zone.to}
                      onChange={(event) =>
                        changeZone({ to: event.target.value })
                      }
                    />
                  </KField>
                </div>
                <KText variant="label" className="do-section-title">
                  Buchungsregeln
                </KText>
                <div className="do-two">
                  <KField label="Vorlaufzeit">
                    <KSelect
                      value={zone.lead}
                      options={[
                        "2 Stunden",
                        "12 Stunden",
                        "1 Tag",
                        "2 Tage",
                      ].map((value) => ({ value, label: value }))}
                      onValueChange={(value) => changeZone({ lead: value })}
                    />
                  </KField>
                  <KField label="Anfahrtspauschale (€)">
                    <KInput
                      type="number"
                      min={0}
                      value={zone.fee}
                      onChange={(event) =>
                        changeZone({ fee: event.target.value })
                      }
                    />
                  </KField>
                </div>
                <Toggle
                  title="Zone aktiv"
                  hint="Pausierte Zonen sind nicht buchbar."
                  value={zone.active}
                  onChange={(value) => changeZone({ active: value })}
                />
              </>
            )}
            {sheet === "history" && (
              <>
                <KInline gap="action" wrap>
                  <KText variant="caption">{log.area}</KText>
                  <KText variant="caption">
                    {log.day}, {log.time}
                  </KText>
                  <KText variant="caption">Denis Knaack</KText>
                </KInline>
                <div className="do-card">
                  {log.changes.map(([label, before, after]) => (
                    <div key={label} className="do-change">
                      <KText variant="label">{label}</KText>
                      <div>
                        {before && (
                          <>
                            <del>{before}</del>
                            <KIcon name="arrow-right" size={16} />
                          </>
                        )}
                        <span>{after}</span>
                      </div>
                    </div>
                  ))}
                </div>
                <KText variant="caption">
                  Nur geänderte Felder. Unveränderte Angaben blenden wir aus.
                </KText>
                <div className="do-info">
                  <KIcon name="info" size={18} />
                  <span>
                    Historische Vorschau und konfliktfestes Rückgängigmachen
                    werden separat angebunden. Hier werden keine produktiven
                    Daten zurückgesetzt.
                  </span>
                </div>
                <KInline gap="action" wrap>
                  <KButton
                    variant="secondary"
                    onClick={() => open("historyPreview")}
                  >
                    <KIcon name="eye" size={17} />
                    Vorschau damals
                  </KButton>
                  <KButton variant="secondary" onClick={() => open("undo")}>
                    <KIcon name="rotate-ccw" size={17} />
                    Rückgängig
                  </KButton>
                </KInline>
              </>
            )}
            {sheet === "historyPreview" && (
              <>
                <KBadge>Lokale Designvorschau</KBadge>
                <KText variant="caption">
                  {log.day}, {log.time} · {log.area}
                </KText>
                <div className="do-card">
                  {log.changes.map(([label, before]) => (
                    <div className="do-change" key={label}>
                      <KText variant="label">{label}</KText>
                      <KText>{before || "Noch nicht vorhanden"}</KText>
                    </div>
                  ))}
                </div>
                <KText variant="caption">
                  Beispielstand vor dieser Änderung. In der Anwendung wird eine
                  historische Buchungsseiten-Vorschau nur mit vorhandenem
                  Snapshot angeboten.
                </KText>
                <KButton variant="secondary" onClick={() => open("history")}>
                  Zurück zum Verlaufseintrag
                </KButton>
              </>
            )}
            {sheet === "undo" && (
              <>
                <KBadge>Lokale Simulation</KBadge>
                <KText>
                  „{log.title}“ vom {log.day}, {log.time} zurücksetzen?
                </KText>
                <KText>
                  In dieser Designvorschau wird nur der Bestätigungsablauf
                  gezeigt. Es werden keine gespeicherten Daten geändert. Die
                  Anwendung muss spätere Änderungen an denselben Feldern zuerst
                  auf Konflikte prüfen.
                </KText>
                <KButton
                  fullWidth
                  onClick={() => {
                    close();
                    setNotice(
                      "Rückgängig-Ablauf simuliert. Keine produktiven Daten wurden verändert.",
                    );
                  }}
                >
                  Rückgängig machen
                </KButton>
                <KButton
                  fullWidth
                  variant="secondary"
                  onClick={() => open("history")}
                >
                  Abbrechen
                </KButton>
              </>
            )}
          </KStack>
        </ReviewAdaptiveDialog>
      </div>
    </div>
  );
}
