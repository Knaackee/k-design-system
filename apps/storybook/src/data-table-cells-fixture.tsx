import { useState } from "react";
import {
  KDataTable,
  KEditableCell,
  KInput,
  KCheckbox,
  KSelect,
  KCombobox,
  KDatePicker,
  KTimePicker,
  KDateTimePicker,
  KCurrencyInput,
  formatCurrencyMinorUnits,
  KStack,
  KText,
  KContainer,
  KIcon,
  type KIconName,
} from "@k-design-system/ui";
const kinds = [
  "text",
  "checkbox",
  "select",
  "combobox",
  "date",
  "time",
  "datetime",
  "currency",
  "readonly",
] as const;
type Kind = (typeof kinds)[number];
const property: Record<Kind, { label: string; icon: KIconName }> = {
  text: { label: "Title", icon: "file-text" },
  checkbox: { label: "Review", icon: "circle-check" },
  select: { label: "Status", icon: "circle-check" },
  combobox: { label: "Owner", icon: "user" },
  date: { label: "Due date", icon: "calendar" },
  time: { label: "Reminder", icon: "clock" },
  datetime: { label: "Scheduled", icon: "calendar" },
  currency: { label: "Budget", icon: "info" },
  readonly: { label: "Source", icon: "lock" },
};
const initial: Record<Kind, string | boolean | number | null> = {
  text: "Atlas website",
  checkbox: true,
  select: "active",
  combobox: "alex",
  date: "2026-09-17",
  time: "14:30",
  datetime: "2026-09-17T12:30:00.000Z",
  currency: 123456,
  readonly: "Consumer-owned content",
};
export function DataTableCellsFixture() {
  const [values, setValues] = useState(initial),
    [editing, setEditing] = useState<Kind | null>(null),
    [draft, setDraft] = useState("");
  const update = (kind: Kind, value: string | boolean | number | null) =>
    setValues((v) => ({ ...v, [kind]: value }));
  const options = [
    { value: "planned", label: "Planned", icon: "minus" as const },
    { value: "active", label: "In progress", icon: "clock" as const },
  ];
  const cell = (kind: Kind) => {
    const label = `Cell ${kind}`;
    if (kind === "checkbox")
      return (
        <KCheckbox
          label="Approved"
          value={values.checkbox as boolean}
          onValueChange={(v) => update(kind, v)}
        />
      );
    if (kind === "select")
      return (
        <KSelect
          label={label}
          presentation="inline"
          options={options}
          value={values.select as string}
          onValueChange={(v) => update(kind, v)}
        />
      );
    if (kind === "combobox")
      return (
        <KCombobox
          label={label}
          presentation="inline"
          options={[
            { value: "alex", label: "Alex Morgan" },
            { value: "sam", label: "Sam Rivera" },
          ]}
          value={values.combobox as string}
          onValueChange={(v) => update(kind, v)}
        />
      );
    if (kind === "date" || kind === "time" || kind === "datetime") {
      const Control =
        kind === "date"
          ? KDatePicker
          : kind === "time"
            ? KTimePicker
            : KDateTimePicker;
      return (
        <Control
          presentation="inline"
          label={label}
          value={values[kind] as string | null}
          onValueChange={(v) => update(kind, v)}
          dateFormat="dayMonthYear"
          timeFormat="h24"
          timeZone="Europe/Berlin"
          now={new Date("2026-09-17T10:00:00Z")}
          clearable
        />
      );
    }
    if (kind === "currency")
      return (
        <KEditableCell
          label={label}
          display={formatCurrencyMinorUnits(values.currency as number | null, {
            currency: "EUR",
            locale: "de-DE",
          })}
          editing={editing === kind}
          onEdit={() => setEditing(kind)}
          editor={
            <KCurrencyInput
              aria-label={label}
              autoFocus
              currency="EUR"
              locale="de-DE"
              value={values.currency as number | null}
              onCommit={(v) => {
                update(kind, v);
                setEditing(null);
              }}
              onKeyDown={(e) => {
                if (e.key === "Escape") setEditing(null);
              }}
            />
          }
        />
      );
    return (
      <KEditableCell
        label={label}
        display={String(values[kind])}
        editing={editing === kind}
        onEdit={
          kind === "readonly"
            ? undefined
            : () => {
                setDraft(String(values[kind]));
                setEditing(kind);
              }
        }
        editor={
          <KInput
            aria-label={label}
            autoFocus
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            onBlur={() => {
              update(kind, draft);
              setEditing(null);
            }}
            onKeyDown={(e) => {
              if (e.key === "Escape") {
                e.preventDefault();
                setEditing(null);
              }
              if (e.key === "Enter") {
                e.preventDefault();
                update(kind, draft);
                setEditing(null);
              }
            }}
          />
        }
      />
    );
  };
  return (
    <div className="k-primitive-fixture">
      <KContainer>
        <KStack gap="section" align="stretch">
          <KText variant="heading4">Properties</KText>
          <KDataTable
            label="Document properties"
            rows={[...kinds]}
            rowId={(v) => v}
            empty={<KText>No cells</KText>}
            columns={[
              {
                id: "kind",
                label: "Type",
                width: 140,
                cell: (k) => (
                  <span
                    style={{
                      display: "inline-flex",
                      alignItems: "center",
                      gap: "var(--k-space-control-gap)",
                      color: "var(--k-color-text-muted)",
                    }}
                  >
                    <KIcon name={property[k].icon} />
                    {property[k].label}
                  </span>
                ),
              },
              {
                id: "value",
                label: "Value",
                minWidth: 300,
                paddingInline: 0,
                cell,
              },
            ]}
          />
        </KStack>
      </KContainer>
    </div>
  );
}
