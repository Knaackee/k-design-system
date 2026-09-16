import { useState } from "react";
import { PickerCalendar } from "./calendar.js";
import { PickerTime } from "./time.js";
import {
  parseDate,
  parseTime,
  formatTime,
  type PickerKind,
  type KDateFormat,
  type KTimeFormat,
  type KPickerLocale,
} from "./date-values.js";
import type { KPickerLabels } from "./labels.js";
export function PickerBody({
  kind,
  initialDayConfirmed,
  allowTextInput,
  dateDraft,
  timeDraft,
  onDateDraft,
  onTimeDraft,
  calendarDate,
  onCalendarDate,
  onSelectDate,
  locale,
  dateFormat,
  timeFormat,
  minuteStep,
  labels,
  min,
  max,
}: {
  kind: PickerKind;
  initialDayConfirmed: boolean;
  allowTextInput: boolean;
  dateDraft: string;
  timeDraft: string;
  onDateDraft: (v: string) => void;
  onTimeDraft: (v: string) => void;
  calendarDate: string;
  onCalendarDate: (v: string) => void;
  onSelectDate: (v: string) => void;
  locale: KPickerLocale;
  dateFormat: KDateFormat;
  timeFormat: KTimeFormat;
  minuteStep: number;
  labels: KPickerLabels;
  min?: string;
  max?: string;
}) {
  const [dayConfirmed, setDayConfirmed] = useState(initialDayConfirmed);
  return (
    <div className="k-picker-body">
      {kind !== "time" && (
        <div className="k-picker-body-section">
          {allowTextInput && (
            <label className="k-picker-draft">
              {labels.date}
              <span className="k-input-target">
                <input
                  className="k-input"
                  value={dateDraft}
                  onChange={(e) => {
                    onDateDraft(e.target.value);
                    const date = parseDate(e.target.value, dateFormat);
                    setDayConfirmed(Boolean(date));
                    if (date) onCalendarDate(date);
                  }}
                />
              </span>
            </label>
          )}
          <PickerCalendar
            value={calendarDate}
            onNavigate={() => setDayConfirmed(false)}
            onChange={(value) => {
              onSelectDate(value);
              setDayConfirmed(true);
            }}
            locale={locale}
            dateFormat={dateFormat}
            labels={labels}
            min={min}
            max={max}
          />
        </div>
      )}
      {kind !== "date" && (kind === "time" || dayConfirmed) && (
        <div className="k-picker-body-section">
          {allowTextInput && (
            <label className="k-picker-draft">
              {labels.time}
              <span className="k-input-target">
                <input
                  className="k-input"
                  value={timeDraft}
                  onChange={(e) => onTimeDraft(e.target.value)}
                />
              </span>
            </label>
          )}
          <PickerTime
            value={parseTime(timeDraft, timeFormat) ?? "00:00"}
            onChange={(v) => onTimeDraft(formatTime(v, timeFormat))}
            timeFormat={timeFormat}
            minuteStep={minuteStep}
            labels={labels}
          />
        </div>
      )}
    </div>
  );
}
