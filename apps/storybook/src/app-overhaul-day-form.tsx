import type { ReactNode } from "react";
import {
  KButton,
  KDatePicker,
  KIcon,
  KIconButton,
  KInput,
  KSelect,
  KStack,
  KSwitch,
  KText,
  type KIconName,
} from "@k-design-system/ui";
import "./app-overhaul-day-form.css";

export interface DayFormValue {
  off: boolean;
  start: string;
  end: string;
  startPlace: string;
  endPlace: string;
  mode: string;
  firstIn: boolean;
  lastIn: boolean;
}
export const defaultDayFormValue: DayFormValue = {
  off: false,
  start: "08:00",
  end: "18:00",
  startPlace: "Kochstraße 21, Leipzig",
  endPlace: "Kochstraße 21, Leipzig",
  mode: "car",
  firstIn: true,
  lastIn: true,
};
export function isDayFormValid(value: DayFormValue, date: string) {
  const validDate =
    /^\d{4}-\d{2}-\d{2}$/.test(date) &&
    !Number.isNaN(Date.parse(date)) &&
    new Date(date).toISOString().slice(0, 10) === date;
  return (
    validDate &&
    (value.off ||
      (value.startPlace.trim().length > 0 &&
        value.endPlace.trim().length > 0 &&
        /^([01]\d|2[0-3]):[0-5]\d$/.test(value.start) &&
        /^([01]\d|2[0-3]):[0-5]\d$/.test(value.end) &&
        value.end > value.start))
  );
}
export function AppOverhaulDayForm({
  value,
  onChange,
  date,
  onDateChange,
  onSave,
  onReset,
  defaults = defaultDayFormValue,
  hideActions = false,
}: {
  value: DayFormValue;
  onChange: (value: DayFormValue) => void;
  date: string;
  onDateChange: (date: string) => void;
  onSave: () => void;
  onReset: () => void;
  defaults?: DayFormValue;
  hideActions?: boolean;
}) {
  const patch = (next: Partial<DayFormValue>) =>
    onChange({ ...value, ...next });
  const changes = (Object.keys(defaults) as (keyof DayFormValue)[]).filter(
    (k) => defaults[k] !== value[k],
  ).length;
  const row = (key: keyof DayFormValue, label: string, control: ReactNode) => (
    <div className="ao-day-field" data-changed={value[key] !== defaults[key]}>
      <div className="ao-day-label">
        <strong>{label}</strong>
        <small>
          {value[key] !== defaults[key] ? "Abweichung" : "Standard"}
        </small>
      </div>
      <div className="ao-day-control">{control}</div>
      {value[key] !== defaults[key] && (
        <KIconButton
          icon="rotate-ccw"
          label={`${label} auf Standard zurücksetzen`}
          onClick={() => onChange({ ...value, [key]: defaults[key] })}
        />
      )}
    </div>
  );
  const group = (title: string, children: ReactNode) => (
    <section className="ao-day-group">
      <KText variant="label">{title}</KText>
      <div className="ao-day-fields">{children}</div>
    </section>
  );
  const presets: {
    label: string;
    icon: KIconName;
    patch: Partial<DayFormValue>;
  }[] = [
    { label: "Freier Tag", icon: "bed", patch: { off: true } },
    {
      label: "Später Start",
      icon: "sun",
      patch: { off: false, start: "10:00" },
    },
    {
      label: "Früher Feierabend",
      icon: "moon",
      patch: { off: false, end: "15:00" },
    },
    {
      label: "Start im Studio",
      icon: "map-pin",
      patch: { off: false, startPlace: "Karl-Liebknecht-Straße 36, Leipzig" },
    },
  ];
  return (
    <KStack gap="action" align="stretch" className="ao-day-form">
      <div className="ao-day-date-chips">
        {[
          ["2026-11-03", "Heute"],
          ["2026-11-04", "Morgen"],
          ["2026-11-05", "Donnerstag"],
        ].map(([day, label]) => (
          <KButton
            key={day}
            variant={date === day ? "primary" : "secondary"}
            aria-pressed={date === day}
            onClick={() => onDateChange(day)}
          >
            {label}
          </KButton>
        ))}
      </div>
      <div className="ao-day-date">
        <KDatePicker
          label="Datum wählen"
          locale="de-DE"
          dateFormat="dayMonthYear"
          timeZone="Europe/Berlin"
          value={date || null}
          onValueChange={(day) => {
            if (day) onDateChange(day);
          }}
        />
      </div>
      <div className="ao-day-summary-state" data-changed={changes > 0}>
        <KIcon name={changes ? "sliders-horizontal" : "check"} size={18} />
        {changes
          ? `${changes} ${changes === 1 ? "Abweichung" : "Abweichungen"} für diesen Tag`
          : "Es gelten deine Standards."}
      </div>
      <div className="ao-day-presets">
        {presets.map((p) => (
          <KButton
            key={p.label}
            fullWidth
            className="ao-day-preset-button"
            variant="secondary"
            onClick={() => patch(p.patch)}
          >
            <span className="ao-day-preset-content">
              <KIcon name={p.icon} size={20} />
              {p.label}
            </span>
          </KButton>
        ))}
      </div>
      <div className="ao-day-fields">
        {row(
          "off",
          "Freier Tag",
          <KSwitch
            showLabel={false}
            label="Freier Tag"
            checked={value.off}
            onCheckedChange={(off) => patch({ off })}
          />,
        )}
      </div>
      {value.off ? (
        <p className="ao-day-help">
          An diesem Tag kann niemand buchen. Bestehende Termine bleiben
          erhalten.
        </p>
      ) : (
        <>
          {group(
            "Start & Ende",
            <>
              {row(
                "startPlace",
                "Startort",
                <KInput
                  aria-label="Startort"
                  required
                  value={value.startPlace}
                  onChange={(e) => patch({ startPlace: e.target.value })}
                />,
              )}
              {row(
                "start",
                "Start ab",
                <KInput
                  aria-label="Start ab"
                  type="time"
                  required
                  value={value.start}
                  onChange={(e) => patch({ start: e.target.value })}
                />,
              )}
              {row(
                "endPlace",
                "Endort",
                <KInput
                  aria-label="Endort"
                  required
                  value={value.endPlace}
                  onChange={(e) => patch({ endPlace: e.target.value })}
                />,
              )}
              {row(
                "end",
                "Spätestens am Endort",
                <KInput
                  aria-label="Spätestens am Endort"
                  type="time"
                  required
                  value={value.end}
                  onChange={(e) => patch({ end: e.target.value })}
                />,
              )}
            </>,
          )}
          {group(
            "Fahrten",
            <>
              {row(
                "firstIn",
                "Erste Fahrt in der Arbeitszeit",
                <KSwitch
                  showLabel={false}
                  label="Erste Fahrt in der Arbeitszeit"
                  checked={value.firstIn}
                  onCheckedChange={(firstIn) => patch({ firstIn })}
                />,
              )}
              {row(
                "lastIn",
                "Letzte Fahrt in der Arbeitszeit",
                <KSwitch
                  showLabel={false}
                  label="Letzte Fahrt in der Arbeitszeit"
                  checked={value.lastIn}
                  onCheckedChange={(lastIn) => patch({ lastIn })}
                />,
              )}
            </>,
          )}
          <p className="ao-day-help">
            Aus: Die Fahrt darf vor Start bzw. nach Ende liegen.
          </p>
          {group(
            "Unterwegs",
            row(
              "mode",
              "Verkehrsmittel",
              <KSelect
                aria-label="Verkehrsmittel"
                value={value.mode}
                onValueChange={(mode) => patch({ mode })}
                options={[
                  { value: "car", label: "Auto" },
                  { value: "bicycle", label: "Fahrrad" },
                  { value: "walking", label: "Zu Fuß" },
                ]}
              />,
            ),
          )}
        </>
      )}
      <p className="ao-day-help">
        Zeitzone Europa/Berlin. Bestehende Termine bleiben erhalten. Die
        Konfliktprüfung erfolgt später im Produkt.
      </p>
      {!isDayFormValid(value, date) && (
        <p role="alert" className="ao-day-error">
          {!date
            ? "Bitte w�hle ein Datum."
            : !value.startPlace.trim() || !value.endPlace.trim()
              ? "Bitte gib einen Startort und einen Endort an."
              : "Bitte pr�fe Datum und Uhrzeiten. Das Ende muss nach dem Start liegen."}
        </p>
      )}
      {!hideActions && (
        <div className="ao-day-actions">
          <KButton variant="secondary" onClick={onReset}>
            Alles zurücksetzen
          </KButton>
          <KButton
            disabled={!isDayFormValid(value, date)}
            onClick={() => {
              if (isDayFormValid(value, date)) onSave();
            }}
          >
            Übernehmen
          </KButton>
        </div>
      )}
    </KStack>
  );
}
