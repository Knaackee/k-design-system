import { useEffect, useState, type ReactNode } from "react";
import {
  KAvatar,
  KButton,
  KCalendar,
  KDatePicker,
  KField,
  KIcon,
  KIconButton,
  KInline,
  KMobileAppBar,
  KInput,
  KSearchField,
  KResponsiveDrawer,
  KSelect,
  KStack,
  KSwitch,
  KText,
  KTextarea,
  type KIconName,
} from "@k-design-system/ui";
import { AvatarEditorFixture } from "./avatar-editor-fixture.js";
import { AppOverhaulMap } from "./app-overhaul-map.js";
import {
  bookings as initialBookings,
  customers as initialCustomers,
  customerOf,
  dateLabel,
  money,
  statusLabels,
  type AppScreen,
  type Booking,
  type Customer,
} from "./app-overhaul-data.js";
import "./app-overhaul.css";
import {
  AppOverhaulDayForm,
  defaultDayFormValue,
  isDayFormValid,
} from "./app-overhaul-day-form.js";
import { ReviewAdaptiveDialog as KDialog } from "./review-overlay-preference.js";
import markUrl from "./offer-overview-mark.svg";

// Composition: K buttons/fields/overlay/calendar/map; layout owns one inset per
// surface and uses the library's semantic gap roles. All actions are local fixtures.
const pages: { id: AppScreen; label: string; icon: KIconName }[] = [
  { id: "home", label: "Heute", icon: "house" },
  { id: "day", label: "Mein Tag", icon: "route" },
  { id: "calendar", label: "Kalender", icon: "calendar" },
  { id: "bookings", label: "Buchungen", icon: "list" },
  { id: "inbox", label: "Posteingang", icon: "inbox" },
  { id: "customers", label: "Kund:innen", icon: "users" },
  { id: "assistant", label: "Assistent", icon: "sparkles" },
];
function RowAction({
  label,
  onClick,
  children,
}: {
  label: string;
  onClick: () => void;
  children: ReactNode;
}) {
  return (
    <div className="ao-action-row">
      <div aria-hidden="true">{children}</div>
      <div className="ao-action-hit">
        <KButton
          variant="ghost"
          className="ao-action-trigger"
          aria-label={label}
          onClick={onClick}
        >
          {""}
        </KButton>
      </div>
    </div>
  );
}
const defaultDay = defaultDayFormValue;
const fixtureToday = "2026-11-03";
const desktopCalendarViews = ["week", "month", "list"] as const;
const mobileCalendarViews = ["list", "three-day", "month"] as const;
const calendarLabels = {
  week: "Woche",
  month: "Monat",
  list: "Liste",
  "three-day": "3 Tage",
};
type CalendarMode = (typeof desktopCalendarViews)[number] | "three-day";
const calendarMonth = new Intl.DateTimeFormat("de-DE", {
  month: "long",
  year: "numeric",
  timeZone: "UTC",
});
const shiftDate = (value: string, days: number) => {
  const d = new Date(`${value}T12:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
};
type Overlay =
  | "day"
  | "booking"
  | "accept"
  | "decline"
  | "cancel"
  | "payment"
  | "customer"
  | "editCustomer"
  | "deleteCustomer"
  | "photo"
  | null;
export function AppOverhaulFixture({
  initialScreen = "home",
  empty = false,
  dark = false,
  initialOverlay = null,
}: {
  initialScreen?: AppScreen;
  empty?: boolean;
  dark?: boolean;
  initialOverlay?: Overlay;
}) {
  const [wide, setWide] = useState(
    () => window.matchMedia("(min-width: 1100px)").matches,
  );
  useEffect(() => {
    const media = window.matchMedia("(min-width: 1100px)");
    const update = () => setWide(media.matches);
    media.addEventListener("change", update);
    return () => media.removeEventListener("change", update);
  }, []);
  const [desktopCalendar, setDesktopCalendar] = useState(
    () => window.matchMedia("(min-width: 701px)").matches,
  );
  useEffect(() => {
    const media = window.matchMedia("(min-width: 701px)");
    const update = () => setDesktopCalendar(media.matches);
    media.addEventListener("change", update);
    return () => media.removeEventListener("change", update);
  }, []);
  const [moreOpen, setMoreOpen] = useState(false);
  const [screen, setScreen] = useState(initialScreen),
    [overlay, setOverlay] = useState<Overlay>(initialOverlay);
  const [booking, setBooking] = useState<Booking>(initialBookings[1]),
    [customer, setCustomer] = useState<Customer>(initialCustomers[1]);
  const [items, setItems] = useState(empty ? [] : initialBookings),
    [contacts, setContacts] = useState(empty ? [] : initialCustomers);
  const [filter, setFilter] = useState("Alle"),
    [query, setQuery] = useState(""),
    [read, setRead] = useState(false);
  const [calendarChoice, setCalendarChoice] = useState<CalendarMode | null>(
    null,
  );
  const [date, setDate] = useState(fixtureToday);
  const [calendarDate, setCalendarDate] = useState(fixtureToday);
  const [calendarSelections, setCalendarSelections] = useState<
    Record<string, string>
  >({
    [fixtureToday.slice(0, 7)]: fixtureToday,
  });
  const calendarMonthKey = calendarDate.slice(0, 7);
  const calendarSelectedDay =
    calendarSelections[calendarMonthKey] ?? `${calendarMonthKey}-01`;
  const selectCalendarDay = (day: string) => {
    const month = day.slice(0, 7);
    if (month !== calendarMonthKey) setCalendarDate(day);
    setCalendarSelections((selections) => ({ ...selections, [month]: day }));
  };
  const calendarViews: readonly CalendarMode[] = desktopCalendar
    ? desktopCalendarViews
    : mobileCalendarViews;
  const calendarView =
    calendarChoice && calendarViews.includes(calendarChoice)
      ? calendarChoice
      : calendarViews[0];
  const activeBookings = items.filter((b) =>
    ["confirmed", "request", "quote"].includes(b.status),
  );
  const [message, setMessage] = useState(""),
    [chat, setChat] = useState<string[]>([]),
    [chatInput, setChatInput] = useState("");
  const [off, setOff] = useState(false),
    [start, setStart] = useState("08:00"),
    [end, setEnd] = useState("18:00"),
    [startPlace, setStartPlace] = useState("Kochstraße 21, Leipzig"),
    [endPlace, setEndPlace] = useState("Kochstraße 21, Leipzig"),
    [mode, setMode] = useState("car"),
    [firstIn, setFirstIn] = useState(true),
    [lastIn, setLastIn] = useState(true);
  const [savedDays, setSavedDays] = useState<Record<string, typeof defaultDay>>(
    {},
  );
  const [draftDate, setDraftDate] = useState(date);
  const savedDay = savedDays[date] ?? defaultDay;
  const dayChanged = !!savedDays[date];
  const loadDayDraft = (d: string) => {
    const v = savedDays[d] ?? defaultDay;
    setDraftDate(d);
    setOff(v.off);
    setStart(v.start);
    setEnd(v.end);
    setStartPlace(v.startPlace);
    setEndPlace(v.endPlace);
    setMode(v.mode);
    setFirstIn(v.firstIn);
    setLastIn(v.lastIn);
  };
  const [draftName, setDraftName] = useState(
      initialOverlay === "editCustomer" || initialOverlay === "photo"
        ? "Jonas Becker"
        : "",
    ),
    [draftEmail, setDraftEmail] = useState(
      initialOverlay === "editCustomer" || initialOverlay === "photo"
        ? "jonas@example.invalid"
        : "",
    ),
    [draftAddress, setDraftAddress] = useState(
      initialOverlay === "editCustomer" || initialOverlay === "photo"
        ? initialCustomers[1].address
        : "",
    ),
    [draftNote, setDraftNote] = useState(
      initialOverlay === "editCustomer" || initialOverlay === "photo"
        ? initialCustomers[1].note
        : "",
    );
  const [draftPhoto, setDraftPhoto] = useState<string>();
  const [isNewCustomer, setIsNewCustomer] = useState(false);
  const [price, setPrice] = useState("85"),
    [reason, setReason] = useState("");
  const today = items.filter(
      (b) => b.date === date && b.status === "confirmed",
    ),
    requests = items.filter((b) => ["request", "quote"].includes(b.status));
  const openBooking = (b: Booking) => {
    setBooking(b);
    setOverlay("booking");
  };
  const notify = (text: string) => setMessage(text);
  const go = (next: AppScreen) => {
    setMoreOpen(false);
    setScreen(next);
    setFilter("Alle");
    setQuery("");
    setOverlay(null);
  };
  const editCustomer = (c?: Customer) => {
    setIsNewCustomer(!c);
    if (c) setCustomer(c);
    setDraftName(c?.name ?? "");
    setDraftPhoto(undefined);
    setDraftEmail(c?.email ?? (c ? `${c.id}@example.invalid` : ""));
    setDraftAddress(c?.address ?? "");
    setDraftNote(c?.note ?? "");
    setOverlay("editCustomer");
  };
  const heading = (title: string, subtitle?: string, action?: ReactNode) => (
    <header className="ao-heading">
      <div>
        <KText variant="heading2" as="h1">
          {title}
        </KText>
        {subtitle && <p>{subtitle}</p>}
      </div>
      {action}
    </header>
  );
  const chip = (label: string, selected: boolean, onClick: () => void) => (
    <KButton
      key={label}
      variant={selected ? "primary" : "ghost"}
      className="ao-chip"
      aria-pressed={selected}
      onClick={onClick}
    >
      {label}
    </KButton>
  );
  const filters = (labels: string[]) => (
    <div className="ao-chips">
      {labels.map((label) =>
        chip(label, filter === label, () => setFilter(label)),
      )}
    </div>
  );
  const badge = (b: Booking) => (
    <span className={`ao-badge ao-badge--${b.status}`}>
      {statusLabels[b.status]}
    </span>
  );
  const section = (title: string, children: ReactNode, action?: ReactNode) => (
    <section className="ao-section">
      <div className="ao-section-heading">
        <KText variant="label">{title}</KText>
        {action}
      </div>
      {children}
    </section>
  );
  const blank = (
    icon: KIconName,
    title: string,
    description: string,
    action?: ReactNode,
  ) => (
    <div className="ao-empty">
      <span className="ao-empty-icon">
        <KIcon name={icon} size={30} />
      </span>
      <KText variant="heading3">{title}</KText>
      <p>{description}</p>
      {action}
    </div>
  );
  const row = (b: Booking) => (
    <RowAction
      key={b.id}
      label={`${customerOf(b).name}, ${b.start}, ${b.service}, ${statusLabels[b.status]}`}
      onClick={() => openBooking(b)}
    >
      <span className="ao-list-row">
        <KAvatar alt={customerOf(b).name} />
        <span className="ao-list-copy">
          <strong>{customerOf(b).name}</strong>
          <small>
            {b.start} · {b.service}
          </small>
        </span>
        <span className="ao-list-value">
          <strong>
            {b.status === "quote" ? "Auf Anfrage" : money(b.price + b.travel)}
          </strong>
          {badge(b)}
        </span>
      </span>
    </RowAction>
  );
  const timeline = () => (
    <div className="ao-timeline">
      <div className="ao-timeline-start">
        <time>08:18</time>
        <span className="ao-timeline-rail">
          <i />
        </span>
        <div>Start · Zuhause</div>
      </div>
      {today.map((b, i) => (
        <div
          className="ao-stop"
          key={b.id}
          data-done={i === 0}
          data-next={i === 1}
        >
          <div className="ao-drive">
            <KIcon name="car" size={15} />
            {b.drive} Min · {b.km} km{i > 0 ? " · 15 Min Puffer" : ""}
          </div>
          <div className="ao-stop-main">
            <time>{b.start}</time>
            <span className="ao-timeline-rail">
              <i />
            </span>
            <KButton
              fullWidth
              variant="ghost"
              className="ao-stop-button"
              onClick={() => openBooking(b)}
            >
              <span className="ao-stop-copy">
                <strong>{customerOf(b).name}</strong>
                <small>
                  {b.service} · bis {b.end} · {customerOf(b).area}
                </small>
              </span>
            </KButton>
          </div>
        </div>
      ))}
      <div className="ao-drive">
        <KIcon name="car" size={15} />
        15 Min · 5,6 km
      </div>
      <div className="ao-timeline-start ao-timeline-end">
        <time>16:00</time>
        <span className="ao-timeline-rail">
          <i />
        </span>
        <div>Zurück · Zuhause</div>
      </div>
    </div>
  );
  const customerDetails = () => (
    <KStack gap="action" align="stretch" className="ao-customer-details">
      <div className="ao-customer-hero">
        <KAvatar alt={customer.name} size="large" />
        <KText variant="heading2">{customer.name}</KText>
        <p>{customer.area} · seit August 2025</p>
      </div>
      <div className="ao-quick">
        {(["phone", "message-circle", "navigation", "plus"] as KIconName[]).map(
          (icon, i) => (
            <KButton
              key={icon}
              variant={i === 0 ? "primary" : "secondary"}
              onClick={() =>
                notify(
                  "Galerie: Diese Aktion öffnet im Produkt den entsprechenden Ablauf.",
                )
              }
            >
              <span className="ao-quick-content">
                <KIcon name={icon} size={21} />
                {["Anrufen", "Nachricht", "Route", "Termin"][i]}
              </span>
            </KButton>
          ),
        )}
      </div>
      {section(
        "Nächster Termin",
        <div className="ao-card">
          {items
            .filter(
              (b) => b.customer === customer.id && b.status === "confirmed",
            )
            .slice(0, 2)
            .map(row)}
          {!items.some((b) => b.customer === customer.id) && (
            <p className="ao-inset ao-muted">Kein Termin geplant.</p>
          )}
        </div>,
      )}
      {section(
        "Einsatzort",
        <div className="ao-card">
          <AppOverhaulMap dark={dark} />
          <div className="ao-inset">
            <strong>{customer.address.split(",")[0]}</strong>
            <p className="ao-muted">{customer.address.split(",")[1]}</p>
            <p>{customer.note}</p>
          </div>
        </div>,
      )}
      {section(
        "Auf einen Blick",
        <div className="ao-stats ao-card">
          <div>
            <b>8</b>
            <span>Besuche</span>
          </div>
          <div>
            <b>384 €</b>
            <span>Umsatz</span>
          </div>
          <div>
            <b>1</b>
            <span>Kommend</span>
          </div>
        </div>,
      )}
      <KButton variant="secondary" onClick={() => editCustomer(customer)}>
        Kund:in bearbeiten
      </KButton>
      <KButton
        variant="ghost"
        className="ao-danger"
        onClick={() => setOverlay("deleteCustomer")}
      >
        Kund:in löschen
      </KButton>
    </KStack>
  );
  let content: ReactNode;
  if (screen === "home")
    content = (
      <>
        {heading(
          "Guten Tag, Mara.",
          empty
            ? "Dienstag, 3. November"
            : "Dienstag, 3. November · 3 Termine noch heute",
        )}{" "}
        {empty ? (
          <>
            {blank(
              "calendar-check",
              "Bereit für die ersten Buchungen.",
              "Teile deine Seite, damit Kund:innen bei dir buchen können.",
              <KButton
                onClick={() =>
                  notify(
                    "Teilen-Vorschau ist in der separaten Sharing-Galerie verfügbar.",
                  )
                }
              >
                Seite teilen
              </KButton>,
            )}
            {section(
              "Heute",
              <p className="ao-muted">
                Noch keine Termine. Sobald jemand bucht, steht der Termin hier,
                mit Route und Uhrzeit.
              </p>,
            )}
          </>
        ) : (
          <>
            <div className="ao-home-grid">
              <div>
                <div className="ao-card">
                  <AppOverhaulMap dark={dark} />
                  <div className="ao-next">
                    <span className="ao-eyebrow">Nächster Termin</span>
                    <div className="ao-time">
                      10:40<small>bis 11:10</small>
                    </div>
                    <span className="ao-leave">
                      <KIcon name="car" size={17} />
                      Losfahren um 10:26 · in 11 Min
                    </span>
                    <div className="ao-person">
                      <KAvatar alt="Jonas Becker" />
                      <div>
                        <strong>Jonas Becker</strong>
                        <small>Herrenschnitt · Bornaische Straße 18</small>
                      </div>
                    </div>
                    <KInline gap="action" wrap>
                      <KButton
                        onClick={() =>
                          notify(
                            "Galerie: Navigation ist hier nicht mit einem Gerät verbunden.",
                          )
                        }
                      >
                        <KIcon name="navigation" size={17} />
                        Route starten
                      </KButton>
                      <KButton
                        variant="secondary"
                        onClick={() =>
                          openBooking(items[1] ?? initialBookings[1])
                        }
                      >
                        Termin öffnen
                      </KButton>
                    </KInline>
                  </div>
                </div>
                {section(
                  "Heute",
                  timeline(),
                  <KButton variant="ghost" onClick={() => go("day")}>
                    Mein Tag
                  </KButton>,
                )}
              </div>
              <div className="ao-home-aside">
                {section(
                  "Anfragen",
                  <div className="ao-card">{requests.map(row)}</div>,
                  <KButton variant="ghost" onClick={() => go("inbox")}>
                    Alle
                  </KButton>,
                )}
                {section(
                  "Letzte 7 Tage",
                  <div className="ao-stats">
                    <div>
                      <b>12</b>
                      <span>Termine</span>
                    </div>
                    <div>
                      <b>642 €</b>
                      <span>Einnahmen</span>
                    </div>
                    <div>
                      <b>{requests.length}</b>
                      <span>Anfragen</span>
                    </div>
                  </div>,
                )}
              </div>
            </div>
          </>
        )}
      </>
    );
  else if (screen === "day")
    content = (
      <>
        {heading("Mein Tag", "Deine Termine und Wege auf einen Blick.")}
        <div className="ao-datebar">
          <KIconButton
            icon="chevron-left"
            label="Vorheriger Tag"
            onClick={() => setDate(shiftDate(date, -1))}
          />
          <KField label="Datum">
            <KDatePicker
              locale="de-DE"
              dateFormat="dayMonthYear"
              timeZone="Europe/Berlin"
              value={date}
              onValueChange={(day) => {
                if (day) setDate(day);
              }}
            />
          </KField>
          <KIconButton
            icon="chevron-right"
            label="Nächster Tag"
            onClick={() => setDate(shiftDate(date, 1))}
          />
        </div>
        <KButton
          fullWidth
          variant="secondary"
          className="ao-day-edit"
          onClick={() => {
            loadDayDraft(date);
            setOverlay("day");
          }}
        >
          <KIcon name="sliders-horizontal" size={20} />
          <span className="ao-stop-copy">
            <strong>
              {savedDay.off
                ? "Freier Tag"
                : dayChanged
                  ? "Abweichungen für diesen Tag"
                  : "Tag anpassen"}
            </strong>
            <small>
              Start Zuhause · {savedDay.start} ·{" "}
              {savedDay.mode === "car"
                ? "Auto"
                : savedDay.mode === "bicycle"
                  ? "Fahrrad"
                  : "Zu Fuß"}
            </small>
          </span>
          <KIcon name="chevron-right" size={18} />
        </KButton>
        {today.length ? (
          <>
            <div className="ao-card">
              <AppOverhaulMap dark={dark} large />
            </div>
            {savedDay.off && (
              <p className="ao-muted">
                Freier Tag: Deine bestehenden Termine bleiben erhalten.
              </p>
            )}
            <div className="ao-day-summary">
              <span>
                <b>{today.length}</b> Termine
              </span>
              <span>
                <b>1 Std 24 Min</b> unterwegs
              </span>
              <span>
                <b>
                  {money(today.reduce((a, b) => a + b.price + b.travel, 0))}
                </b>{" "}
                gesamt
              </span>
            </div>
            {timeline()}
          </>
        ) : (
          blank(
            "sun",
            "Heute ist Platz für Neues.",
            savedDay.off
              ? "Für diesen Tag sind keine neuen Buchungen möglich. Bestehende Termine bleiben erhalten."
              : "Noch keine Termine für diesen Tag.",
          )
        )}
      </>
    );
  else if (screen === "bookings") {
    const filtered = items.filter(
      (b) =>
        filter === "Alle" ||
        (filter === "Anfragen" && ["request", "quote"].includes(b.status)) ||
        (filter === "Bestätigt" && b.status === "confirmed") ||
        (filter === "Abgesagt" && b.status === "cancelled"),
    );
    content = (
      <>
        {heading("Buchungen", `${items.length} Buchungen`)}
        {filters(["Alle", "Anfragen", "Bestätigt", "Abgesagt"])}
        {!items.length
          ? blank(
              "calendar",
              "Noch keine Buchungen",
              "Neue Termine und Anfragen erscheinen hier.",
            )
          : Array.from(new Set(filtered.map((b) => b.date))).map((d) => (
              <section className="ao-section" key={d}>
                <div className="ao-day-label">{dateLabel(d)}</div>
                <div className="ao-card">
                  {filtered.filter((b) => b.date === d).map(row)}
                </div>
              </section>
            ))}
        {items.length > 0 &&
          !filtered.length &&
          blank(
            "search",
            "Keine passenden Buchungen",
            "Wähle einen anderen Filter.",
          )}
      </>
    );
  } else if (screen === "calendar") {
    const upcoming = activeBookings
      .filter(
        (b) =>
          b.date > fixtureToday || (b.date === fixtureToday && b.end > "10:15"),
      )
      .sort(
        (a, b) =>
          a.date.localeCompare(b.date) || a.start.localeCompare(b.start),
      );
    const navigateCalendar = (direction: number) => {
      if (calendarView === "month") {
        const next = new Date(`${calendarDate.slice(0, 7)}-01T12:00:00Z`);
        next.setUTCMonth(next.getUTCMonth() + direction);
        const nextDay = next.toISOString().slice(0, 10);
        setCalendarDate(nextDay);
      } else {
        setCalendarDate(
          shiftDate(
            calendarDate,
            direction * (calendarView === "week" ? 7 : 3),
          ),
        );
      }
    };
    const selectedDayBookings = activeBookings
      .filter((b) => b.date === calendarSelectedDay)
      .sort((a, b) => a.start.localeCompare(b.start));
    content = (
      <>
        {heading("Kalender")}
        <div className="ao-calendar-header">
          <KText variant="label">
            {calendarView === "list"
              ? "Anstehend"
              : calendarMonth.format(new Date(`${calendarDate}T12:00:00Z`))}
          </KText>
          {calendarView !== "list" && (
            <KInline gap="control" wrap>
              <KIconButton
                icon="chevron-left"
                label="Vorheriger Zeitraum"
                onClick={() => navigateCalendar(-1)}
              />
              <KButton
                variant="secondary"
                onClick={() => {
                  setCalendarDate(fixtureToday);
                  selectCalendarDay(fixtureToday);
                }}
              >
                Heute
              </KButton>
              <KIconButton
                icon="chevron-right"
                label="Nächster Zeitraum"
                onClick={() => navigateCalendar(1)}
              />
            </KInline>
          )}
        </div>
        <div className="ao-chips" role="group" aria-label="Kalenderansicht">
          {calendarViews.map((view) =>
            chip(calendarLabels[view], calendarView === view, () =>
              setCalendarChoice(view),
            ),
          )}
        </div>
        {calendarView === "list" ? (
          upcoming.length ? (
            Array.from(new Set(upcoming.map((b) => b.date))).map((day) => (
              <section className="ao-section" key={day}>
                <div className="ao-day-label">{dateLabel(day)}</div>
                <div className="ao-card">
                  {upcoming.filter((b) => b.date === day).map(row)}
                </div>
              </section>
            ))
          ) : (
            blank(
              "calendar",
              "Nichts geplant",
              "Hier erscheinen deine kommenden Termine.",
            )
          )
        ) : (
          <div className="ao-card ao-calendar">
            <KCalendar
              date={new Date(`${calendarDate}T12:00:00`)}
              view={calendarView}
              events={activeBookings}
              getEventId={(b) => b.id}
              getEventStart={(b) => new Date(`${b.date}T${b.start}:00+01:00`)}
              getEventEnd={(b) => new Date(`${b.date}T${b.end}:00+01:00`)}
              renderEvent={({ event: b }) => (
                <span>
                  <strong>{customerOf(b).name}</strong>
                  <br />
                  {b.service}
                </span>
              )}
              onEventOpen={openBooking}
              locale="de-DE"
              timeZone="Europe/Berlin"
              startHour={8}
              endHour={19}
              firstDayOfWeek={1}
              minDayWidth={desktopCalendar ? 84 : 78}
              onNavigate={navigateCalendar}
              monthEventDisplay={
                desktopCalendar ? "appointments" : "indicators"
              }
              height={
                calendarView === "month"
                  ? desktopCalendar
                    ? 600
                    : 360
                  : undefined
              }
              selectedMonthDay={calendarSelectedDay}
              onMonthDayOpen={selectCalendarDay}
            />
          </div>
        )}
        {calendarView === "month" && (
          <section
            className="ao-section"
            aria-label="Termine am ausgewählten Tag"
          >
            <div className="ao-day-label" aria-live="polite">
              {dateLabel(calendarSelectedDay)}
            </div>
            {selectedDayBookings.length ? (
              <div className="ao-card">{selectedDayBookings.map(row)}</div>
            ) : (
              <p className="ao-muted">Keine Termine.</p>
            )}
          </section>
        )}
      </>
    );
  } else if (screen === "inbox")
    content = (
      <>
        {heading(
          "Posteingang",
          read || empty ? "Alles gelesen" : "3 ungelesen",
          !read && !empty && (
            <KButton variant="secondary" onClick={() => setRead(true)}>
              <KIcon name="check" size={17} />
              Alle gelesen
            </KButton>
          ),
        )}
        {filters(["Alle", "Ungelesen", "Anfragen"])}
        {empty ? (
          blank(
            "inbox",
            "Alles ruhig hier",
            "Neue Anfragen, Zahlungen und Absagen erscheinen hier, sobald jemand bucht.",
          )
        ) : filter === "Ungelesen" && read ? (
          blank("check", "Alles gelesen", "Du bist auf dem neuesten Stand.")
        ) : (
          <>
            {section(
              "Heute",
              <div className="ao-card">
                {requests.map((b) => (
                  <article className="ao-event" key={b.id}>
                    <span className="ao-event-icon">
                      <KIcon
                        name={b.status === "quote" ? "euro" : "bell"}
                        size={19}
                      />
                    </span>
                    <div>
                      <p>
                        <strong>{customerOf(b).name}</strong>{" "}
                        {b.status === "quote"
                          ? "wünscht ein Angebot für"
                          : "fragt"}{" "}
                        {b.service} für {dateLabel(b.date)}, {b.start} an.
                      </p>
                      <small>
                        vor 2 Std
                        {b.status !== "quote"
                          ? ` · ${money(b.price + b.travel)}`
                          : ""}
                      </small>
                      <KInline gap="action" wrap>
                        <KButton
                          variant="secondary"
                          className="ao-danger"
                          onClick={() => {
                            setBooking(b);
                            setOverlay("decline");
                          }}
                        >
                          Ablehnen
                        </KButton>
                        <KButton
                          onClick={() => {
                            setBooking(b);
                            setOverlay("accept");
                          }}
                        >
                          {b.status === "quote" ? "Preis nennen" : "Annehmen"}
                        </KButton>
                      </KInline>
                    </div>
                    {!read && <i className="ao-unread" />}
                  </article>
                ))}
              </div>,
            )}
            {filter !== "Anfragen" &&
              section(
                "Gestern",
                <div className="ao-card">
                  <article className="ao-event">
                    <span className="ao-event-icon ao-success">
                      <KIcon name="check" size={19} />
                    </span>
                    <div>
                      <p>
                        <strong>Lena Hoffmann</strong> hat bezahlt. Der Termin
                        am Freitag, 10:00 steht fest.
                      </p>
                      <small>gestern, 19:02 · 41,90 €</small>
                    </div>
                  </article>
                </div>,
              )}
          </>
        )}
      </>
    );
  else if (screen === "customers") {
    const found = contacts.filter((c) =>
      `${c.name} ${c.area} ${c.address}`
        .toLowerCase()
        .includes(query.toLowerCase()),
    );
    content = (
      <>
        {heading(
          "Kund:innen",
          `${contacts.length} Kontakte`,
          <KButton onClick={() => editCustomer()}>
            <KIcon name="plus" size={17} />
            Neu
          </KButton>,
        )}
        {contacts.length ? (
          <>
            <KSearchField
              aria-label="Kund:innen suchen"
              placeholder="Name, Straße oder Stadtteil"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
            />
            <div className="ao-card ao-customer-list">
              {found.map((c) => (
                <RowAction
                  key={c.id}
                  label={`${c.name}, ${c.area}`}
                  onClick={() => {
                    setCustomer(c);
                    setOverlay("customer");
                  }}
                >
                  <span className="ao-list-row">
                    <KAvatar alt={c.name} />
                    <span className="ao-list-copy">
                      <strong>{c.name}</strong>
                      <small>{c.area}</small>
                    </span>
                    <span className="ao-list-value">
                      <small>{c.id === "c2" ? "Heute · 10:40" : ""}</small>
                      <KIcon name="chevron-right" size={17} />
                    </span>
                  </span>
                </RowAction>
              ))}
            </div>
            {!found.length &&
              blank(
                "search",
                "Niemand gefunden",
                "Versuche einen anderen Namen oder Stadtteil.",
              )}
          </>
        ) : (
          blank(
            "users",
            "Noch keine Kund:innen",
            "Wer bei dir bucht, landet automatisch hier. Du kannst Kund:innen auch selbst anlegen.",
            <KButton onClick={() => editCustomer()}>Kund:in anlegen</KButton>,
          )
        )}
      </>
    );
  } else
    content = (
      <>
        {heading(
          "Assistent",
          undefined,
          chat.length > 0 && (
            <KButton variant="secondary" onClick={() => setChat([])}>
              <KIcon name="plus" size={17} />
              Neues Gespräch
            </KButton>
          ),
        )}
        {chat.length ? (
          <div className="ao-chat">
            {chat.map((q, i) => (
              <div key={i}>
                <div className="ao-chat-user">{q}</div>
                <div className="ao-chat-answer">
                  <KIcon name="sparkles" size={22} />
                  <div>
                    <p>
                      {empty
                        ? "Du hast noch keine Termine oder Buchungen."
                        : "Heute stehen noch drei Termine an. Dein nächster Termin ist um 10:40 bei Jonas Becker."}
                    </p>
                    {!empty && (
                      <KButton
                        variant="secondary"
                        onClick={() => openBooking(initialBookings[1])}
                      >
                        Termin öffnen
                      </KButton>
                    )}
                    <small className="ao-muted">
                      Lokale Galerieantwort – keine KI-Anfrage.
                    </small>
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          blank(
            "sparkles",
            "Wobei kann ich helfen?",
            empty
              ? "Galerievorschau ohne Beispieldaten. Neue Buchungen erscheinen im Arbeitsalltag, sobald Termine vorhanden sind."
              : "Galerievorschau mit Beispieldaten. Probiere eine Frage aus und sieh dir eine Beispielantwort an.",
            <KStack gap="control" align="stretch">
              {[
                "Was steht heute an?",
                "Wie viel habe ich diese Woche verdient?",
                "Gibt es offene Anfragen?",
              ].map((q) => (
                <KButton
                  key={q}
                  variant="secondary"
                  onClick={() => setChat([q])}
                >
                  {q}
                </KButton>
              ))}
            </KStack>,
          )
        )}
        <div className="ao-chat-compose">
          <KInput
            aria-label="Nachricht an den Assistenten"
            placeholder="Frag deinen Assistenten …"
            value={chatInput}
            onChange={(e) => setChatInput(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter" && chatInput.trim()) {
                setChat([...chat, chatInput]);
                setChatInput("");
              }
            }}
          />
          <KIconButton
            icon="arrow-up"
            label="Nachricht senden"
            disabled={!chatInput.trim()}
            onClick={() => {
              setChat([...chat, chatInput]);
              setChatInput("");
            }}
          />
        </div>
      </>
    );
  const updateBooking = (status: Booking["status"]) => {
    setItems(
      items.map((b) =>
        b.id === booking.id
          ? {
              ...b,
              status,
              ...(status === "confirmed" && b.status === "quote"
                ? { price: Number(price.replace(",", ".")) }
                : {}),
            }
          : b,
      ),
    );
    setOverlay(null);
    notify(
      "Nur in dieser Galerie geändert. Es wurde keine Nachricht versendet.",
    );
  };
  const bookingDetails = () => (
    <KStack gap="action" align="stretch" className="ao-booking-details">
      <div className="ao-booking-hero">
        {badge(booking)}
        <div className="ao-time">
          {booking.start}
          <small>bis {booking.end}</small>
        </div>
        <KText variant="bodySmall">{dateLabel(booking.date)}</KText>
      </div>
      <section className="ao-booking-section">
        <KText variant="label">Kund:in &amp; Einsatzort</KText>
        <div className="ao-card">
          <div className="ao-person ao-inset">
            <KAvatar alt={customerOf(booking).name} />
            <div>
              <strong>{customerOf(booking).name}</strong>
              <small>{customerOf(booking).area}</small>
            </div>
          </div>
          <AppOverhaulMap dark={dark} />
          <div className="ao-inset">
            <strong>{customerOf(booking).address}</strong>
            <p className="ao-muted">{customerOf(booking).note}</p>
          </div>
        </div>
      </section>
      <section className="ao-booking-section">
        <KText variant="label">Leistungen &amp; Preis</KText>
        <div className="ao-card ao-inset">
          <div className="ao-kv">
            <span>{booking.service}</span>
            <strong>
              {booking.status === "quote"
                ? "Auf Anfrage"
                : money(booking.price)}
            </strong>
          </div>
          <div className="ao-kv">
            <span>Anfahrt</span>
            <span>{money(booking.travel)}</span>
          </div>
          <div className="ao-kv ao-total">
            <strong>Gesamt</strong>
            <strong>
              {booking.status === "quote"
                ? "Preis offen"
                : money(booking.price + booking.travel)}
            </strong>
          </div>
        </div>
      </section>
      <KInline gap="action" wrap>
        {["request", "quote"].includes(booking.status) ? (
          <>
            <KButton onClick={() => setOverlay("accept")}>
              {booking.status === "quote" ? "Preis nennen" : "Annehmen"}
            </KButton>
            <KButton
              variant="secondary"
              className="ao-danger"
              onClick={() => setOverlay("decline")}
            >
              Ablehnen
            </KButton>
          </>
        ) : (
          <>
            <KButton variant="secondary" onClick={() => setOverlay("payment")}>
              Zahlung ansehen
            </KButton>
            <KButton
              variant="ghost"
              className="ao-danger"
              onClick={() => setOverlay("cancel")}
            >
              Absagen
            </KButton>
          </>
        )}
      </KInline>
    </KStack>
  );
  const draftDay = {
    off,
    start,
    end,
    startPlace,
    endPlace,
    mode,
    firstIn,
    lastIn,
  };
  const changeDayDraft = (value: typeof defaultDay) => {
    setOff(value.off);
    setStart(value.start);
    setEnd(value.end);
    setStartPlace(value.startPlace);
    setEndPlace(value.endPlace);
    setMode(value.mode);
    setFirstIn(value.firstIn);
    setLastIn(value.lastIn);
  };
  const saveDayDraft = () => {
    if (!isDayFormValid(draftDay, draftDate)) return;
    setSavedDays((previous) => {
      const next = { ...previous };
      if (JSON.stringify(draftDay) === JSON.stringify(defaultDay))
        delete next[draftDate];
      else next[draftDate] = draftDay;
      return next;
    });
    setDate(draftDate);
    setOverlay(null);
  };
  const dialogTitle = {
    day: "Tag anpassen",
    booking: "Buchungsdetails",
    accept: booking.status === "quote" ? "Preis nennen" : "Anfrage annehmen",
    decline: "Anfrage ablehnen",
    cancel: "Buchung absagen",
    payment: "Buchungszahlung",
    customer: "Kund:in",
    editCustomer: "Kund:in bearbeiten",
    deleteCustomer: "Kund:in löschen?",
    photo: "Dein Bild",
  };
  return (
    <div className="ao-root" data-mode={dark ? "dark" : "light"}>
      <div className="ao-shell">
        <aside className="ao-sidebar">
          <div className="ao-logo">
            <img src={markUrl} alt="" width="26" height="32" />
            onzeit<span>.</span>
          </div>
          <nav>
            {pages.map((p) => (
              <KButton
                key={p.id}
                fullWidth
                className="ao-nav"
                variant={screen === p.id ? "secondary" : "ghost"}
                aria-current={screen === p.id ? "page" : undefined}
                onClick={() => go(p.id)}
              >
                <KIcon name={p.icon} size={19} />
                {p.label}
              </KButton>
            ))}
          </nav>
          <div className="ao-sidebar-person">
            <KAvatar alt="Mara Krüger" />
            <span>
              <strong>Mara Krüger</strong>
              <small>Mobile Friseurin</small>
            </span>
          </div>
        </aside>
        <main className="ao-main">
          <div className="ao-mobile-brand ao-logo">
            <img src={markUrl} alt="" width="23" height="28" />
            onzeit<span>.</span>
          </div>
          <div
            className={`ao-wrap ${wide && (screen === "bookings" || screen === "customers") ? "ao-split" : ""}`}
          >
            {wide && (screen === "bookings" || screen === "customers") ? (
              <>
                <div>{content}</div>
                <div className="ao-detail-pane">
                  {screen === "bookings" && overlay === "booking"
                    ? bookingDetails()
                    : screen === "customers" && overlay === "customer"
                      ? customerDetails()
                      : blank(
                          screen === "bookings" ? "calendar" : "users",
                          screen === "bookings"
                            ? "Buchung auswählen"
                            : "Kund:in auswählen",
                          "Wähle links einen Eintrag aus.",
                        )}
                </div>
              </>
            ) : (
              content
            )}
          </div>
          {message && (
            <div className="ao-notice" role="status">
              {message}
              <KIconButton
                icon="x"
                label="Hinweis schließen"
                onClick={() => setMessage("")}
              />
            </div>
          )}
        </main>
        <div className="ao-mobile-nav">
          <KMobileAppBar
            label="App-Navigation"
            variant="fixed"
            labelVisibility="never"
            visibility="always"
            quality="solid"
            items={[
              ...pages
                .filter((page) =>
                  ["home", "calendar", "bookings", "inbox"].includes(page.id),
                )
                .map((page) => ({
                  id: page.id,
                  label: page.label,
                  icon: <KIcon name={page.icon} size={21} />,
                })),
              {
                id: "more",
                label: "Mehr Bereiche",
                icon: <KIcon name="grid-2x2" size={21} />,
              },
            ]}
            selectedId={
              ["day", "customers", "assistant"].includes(screen)
                ? "more"
                : screen
            }
            onSelectionChange={(id) =>
              id === "more" ? setMoreOpen(true) : go(id as AppScreen)
            }
          />
        </div>
      </div>
      <KResponsiveDrawer
        open={moreOpen}
        onOpenChange={setMoreOpen}
        title="Mehr"
        side="left"
        breakpoint={0}
      >
        <KStack gap="control" align="stretch">
          {pages
            .filter((p) => ["day", "customers", "assistant"].includes(p.id))
            .map((p) => (
              <KButton
                key={p.id}
                fullWidth
                variant="ghost"
                onClick={() => go(p.id)}
              >
                <KIcon name={p.icon} size={20} />
                {p.label}
              </KButton>
            ))}
        </KStack>
      </KResponsiveDrawer>
      <KDialog
        open={
          overlay !== null &&
          overlay !== "photo" &&
          !(
            wide &&
            ((screen === "bookings" && overlay === "booking") ||
              (screen === "customers" && overlay === "customer"))
          )
        }
        title={overlay ? dialogTitle[overlay] : ""}
        onOpenChange={(open) => {
          if (!open) setOverlay(null);
        }}
        className="ao-dialog"
        bodyClassName="ao-dialog-body"
        preferPageSheet={
          overlay !== "cancel" &&
          overlay !== "decline" &&
          overlay !== "deleteCustomer"
        }
        closeLabel="Schließen"
        actions={
          overlay === "day" ? (
            <KInline gap="control" wrap>
              <KButton
                variant="secondary"
                onClick={() => changeDayDraft(defaultDay)}
              >
                Alles zurücksetzen
              </KButton>
              <KButton
                disabled={!isDayFormValid(draftDay, draftDate)}
                onClick={saveDayDraft}
              >
                Übernehmen
              </KButton>
            </KInline>
          ) : undefined
        }
      >
        {overlay === "day" && (
          <AppOverhaulDayForm
            value={draftDay}
            date={draftDate}
            onDateChange={loadDayDraft}
            onChange={changeDayDraft}
            onReset={() => changeDayDraft(defaultDay)}
            onSave={saveDayDraft}
            hideActions
          />
        )}
        {overlay === "booking" && bookingDetails()}
        {overlay === "accept" && (
          <KStack gap="section" align="stretch">
            <p>
              {customerOf(booking).name} · {booking.service}
              <br />
              {dateLabel(booking.date)}, {booking.start}
            </p>
            {booking.status === "quote" && (
              <KField label="Preis für die Leistung (€)">
                <KInput
                  inputMode="decimal"
                  value={price}
                  onChange={(e) => setPrice(e.target.value)}
                />
              </KField>
            )}
            <p className="ao-muted">
              Galerie-Vorschau. Eine echte Annahme muss Verfügbarkeit und Preis
              serverseitig bestätigen.
            </p>
            <KButton
              disabled={
                booking.status === "quote" &&
                (!Number.isFinite(Number(price.replace(",", "."))) ||
                  Number(price.replace(",", ".")) <= 0)
              }
              onClick={() => updateBooking("confirmed")}
            >
              Annahme in der Galerie zeigen
            </KButton>
          </KStack>
        )}
        {(overlay === "cancel" || overlay === "decline") && (
          <KStack gap="action" align="stretch" className="ao-cancel-form">
            <p>
              {customerOf(booking).name} · {booking.service}
              <br />
              {dateLabel(booking.date)}, {booking.start}
            </p>
            <KField label="Grund (Vorschau)">
              <KTextarea
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                placeholder="Grund für die Absage"
              />
            </KField>
            <p className="ao-muted">
              Nachrichtenversand und Rückerstattung werden hier nicht
              ausgeführt. Die zusätzlichen Felder benötigen vor
              Produktintegration einen erweiterten Vertrag.
            </p>
            <KButton
              fullWidth
              style={{ justifyContent: "center" }}
              className="ao-danger-button"
              onClick={() => updateBooking("cancelled")}
            >
              Absage in der Galerie zeigen
            </KButton>
            <KButton
              fullWidth
              style={{ justifyContent: "center" }}
              variant="secondary"
              onClick={() => setOverlay("booking")}
            >
              Zurück
            </KButton>
          </KStack>
        )}
        {overlay === "payment" && (
          <KStack gap="section" align="stretch">
            <div className="ao-booking-hero">
              <span className="ao-badge ao-badge--confirmed">
                Beispielzahlung
              </span>
              <div className="ao-time">
                {money(booking.price + booking.travel)}
              </div>
              <p>{customerOf(booking).name}</p>
            </div>
            <div className="ao-card ao-inset">
              <div className="ao-kv">
                <span>Leistungen</span>
                <strong>{money(booking.price)}</strong>
              </div>
              <div className="ao-kv">
                <span>Anfahrt</span>
                <strong>{money(booking.travel)}</strong>
              </div>
              <div className="ao-kv ao-total">
                <span>Gesamt</span>
                <strong>{money(booking.price + booking.travel)}</strong>
              </div>
            </div>
            <div className="ao-card ao-inset">
              <div className="ao-kv">
                <span>Kund:in</span>
                <span>{customerOf(booking).name}</span>
              </div>
              <div className="ao-kv">
                <span>Termin</span>
                <span>
                  {dateLabel(booking.date)}, {booking.start}
                </span>
              </div>
              <div className="ao-kv">
                <span>Buchungsnummer</span>
                <span>DEMO-{booking.id}</span>
              </div>
            </div>
          </KStack>
        )}
        {overlay === "customer" && customerDetails()}
        {overlay === "editCustomer" && (
          <KStack gap="section" align="stretch">
            <KButton variant="ghost" onClick={() => setOverlay("photo")}>
              <KAvatar
                alt={draftName || "Neues Bild"}
                size="large"
                src={draftPhoto}
              />
              Foto auswählen
            </KButton>
            <div className="ao-form-grid">
              <KField label="Name" required>
                <KInput
                  value={draftName}
                  onChange={(e) => setDraftName(e.target.value)}
                />
              </KField>
              <KField label="E-Mail" required>
                <KInput
                  type="email"
                  value={draftEmail}
                  onChange={(e) => setDraftEmail(e.target.value)}
                />
              </KField>
              <KField label="Einsatzort" required>
                <KInput
                  value={draftAddress}
                  onChange={(e) => setDraftAddress(e.target.value)}
                />
              </KField>
              <KField label="Zugangshinweise">
                <KTextarea
                  value={draftNote}
                  onChange={(e) => setDraftNote(e.target.value)}
                />
              </KField>
            </div>
            <p className="ao-muted">
              Es wird keine Einladung verschickt. Galerieänderungen werden nicht
              gespeichert.
            </p>
            <KButton
              fullWidth
              style={{ justifyContent: "center" }}
              disabled={
                !draftName.trim() ||
                !draftEmail.includes("@") ||
                !draftAddress.trim()
              }
              onClick={() => {
                setContacts([
                  ...contacts.filter(
                    (c) => isNewCustomer || c.id !== customer.id,
                  ),
                  {
                    ...customer,
                    id: isNewCustomer
                      ? `gallery-${contacts.length + 1}`
                      : customer.id,
                    name: draftName,
                    email: draftEmail,
                    address: draftAddress,
                    note: draftNote,
                  },
                ]);
                setOverlay(null);
                notify("Kontakt nur in dieser Galerie geändert.");
              }}
            >
              Speichern
            </KButton>
          </KStack>
        )}
        {overlay === "deleteCustomer" && (
          <KStack gap="action" align="stretch" className="ao-cancel-form">
            <p>
              Kontakt, Adresse und Notizen werden gelöscht. Vergangene Buchungen
              bleiben für deine Abrechnung erhalten.
            </p>
            <KButton
              fullWidth
              style={{ justifyContent: "center" }}
              className="ao-danger-button"
              onClick={() => {
                setContacts((current) =>
                  current.filter((item) => item.id !== customer.id),
                );
                setOverlay(null);
                notify("Kontakt in der Galerie gelöscht.");
              }}
            >
              Löschen
            </KButton>
            <KButton
              fullWidth
              style={{ justifyContent: "center" }}
              variant="secondary"
              onClick={() => setOverlay("customer")}
            >
              Abbrechen
            </KButton>
          </KStack>
        )}
      </KDialog>
      <AvatarEditorFixture
        open={overlay === "photo"}
        includeSample={false}
        onOpenChange={(open) => {
          if (!open) setOverlay("editCustomer");
        }}
        onAvatarChange={setDraftPhoto}
      />
    </div>
  );
}
