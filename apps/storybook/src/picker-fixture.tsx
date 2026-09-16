import { useState } from "react";
import {
  KContainer,
  KStack,
  KText,
  KField,
  KDatePicker,
  KTimePicker,
  KDateTimePicker,
} from "@k-design-system/ui";

export interface PickerFixtureProps {
  kind?: "date" | "time" | "date-time";
  timeZone?: string;
  allowTextInput?: boolean;
  minuteStep?: number;
  locale?:
    | "inherit"
    | "en"
    | "de"
    | "fr"
    | "es"
    | "it"
    | "pt"
    | "nl"
    | "pl"
    | "cs"
    | "sv"
    | "da"
    | "nb"
    | "fi"
    | "tr";
  dateFormat?: "iso" | "dayMonthYear" | "monthDayYear";
  timeFormat?: "h24" | "h12";
  disambiguation?: "reject" | "earlier" | "later";
}

export const pickerControls = {
  allowTextInput: { control: "boolean" as const },
  minuteStep: { control: "select" as const, options: [1, 5, 15] },
  kind: { table: { disable: true } },
  timeZone: {
    control: {
      type: "select" as const,
      labels: {
        UTC: "UTC",
        Europe_Berlin: "Europe/Berlin",
        America_New_York: "America/New_York",
      },
    },
    options: ["UTC", "Europe_Berlin", "America_New_York"],
    mapping: {
      UTC: "UTC",
      Europe_Berlin: "Europe/Berlin",
      America_New_York: "America/New_York",
    },
  },
  locale: {
    control: "select" as const,
    options: [
      "inherit",
      "en",
      "de",
      "fr",
      "es",
      "it",
      "pt",
      "nl",
      "pl",
      "cs",
      "sv",
      "da",
      "nb",
      "fi",
      "tr",
    ],
  },
  dateFormat: {
    control: "select" as const,
    options: ["iso", "dayMonthYear", "monthDayYear"],
  },
  timeFormat: { control: "select" as const, options: ["h24", "h12"] },
  disambiguation: {
    control: "select" as const,
    options: ["reject", "earlier", "later"],
  },
};
export const pickerDefaults = {
  timeZone: "Europe_Berlin",
  allowTextInput: false,
  minuteStep: 1,
  locale: "inherit",
  dateFormat: "dayMonthYear",
  timeFormat: "h24",
  disambiguation: "reject",
} as const;

export function PickerFixture({
  kind = "date",
  allowTextInput = false,
  minuteStep = 1,
  timeZone = "Europe/Berlin",
  locale = "inherit",
  dateFormat = "dayMonthYear",
  timeFormat = "h24",
  disambiguation = "reject",
}: PickerFixtureProps) {
  const initial =
    kind === "date"
      ? "2026-09-16"
      : kind === "time"
        ? "14:30"
        : "2026-09-16T12:30:00.000Z";
  const [value, setValue] = useState<string | null>(initial);
  const Control =
    kind === "date"
      ? KDatePicker
      : kind === "time"
        ? KTimePicker
        : KDateTimePicker;
  const label =
    kind === "date" ? "Date" : kind === "time" ? "Time" : "Date and time";
  const configuration = {
    allowTextInput,
    minuteStep,
    timeZone,
    locale: locale === "inherit" ? undefined : locale,
    dateFormat,
    timeFormat,
    disambiguation,
    now: new Date("2026-09-16T10:00:00Z"),
  };
  return (
    <div className="k-primitive-fixture">
      <KContainer>
        <KStack align="stretch" gap="section">
          <KText variant="heading4">Schedule</KText>
          <KField label={label}>
            <Control
              {...configuration}
              value={value}
              onValueChange={setValue}
              clearable
            />
          </KField>
          <KField label="Read only">
            <Control
              {...configuration}
              value={initial}
              onValueChange={() => {}}
              readOnly
            />
          </KField>
          <KField label="Unavailable">
            <Control
              {...configuration}
              value={initial}
              onValueChange={() => {}}
              disabled
            />
          </KField>
          <KText role="status">{`Value: ${value ?? "None"}`}</KText>
        </KStack>
      </KContainer>
    </div>
  );
}
