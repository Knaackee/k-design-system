import { useKLocalization } from "../localization/provider.js";
import { useEffect, useId, useRef, useState } from "react";
import { KInput } from "../forms/input.js";
import { useField } from "../forms/field.js";
import { KButton } from "../primitives/button.js";
import { KIconButton } from "../actions/icon-button.js";
import { PickerBody } from "./body.js";
import { type KPickerLabels } from "./labels.js";
import {
  formatDate,
  formatTime,
  parseDate,
  parseTime,
  valueParts,
  resolveLocal,
  inRange,
  validateConfiguration,
  validateMinuteStep,
  zoneParts,
  type PickerKind,
  type KDateFormat,
  type KTimeFormat,
  type KTimeDisambiguation,
  type KPickerLocale,
} from "./date-values.js";
type PickerError = "invalid" | "outOfRange" | "nonexistent" | "ambiguous";
export interface KPickerProps {
  /** Compact value trigger for table composition. */
  presentation?: "standard" | "inline";
  value: string | null;
  onValueChange: (value: string | null) => void;
  /** Balanced modal ownership notification; closing follows value/focus updates. */
  onOpenChange?: (open: boolean) => void;
  label?: string;
  timeZone?: string;
  locale?: KPickerLocale;
  dateFormat?: KDateFormat;
  timeFormat?: KTimeFormat;
  disambiguation?: KTimeDisambiguation;
  min?: string;
  max?: string;
  disabled?: boolean;
  readOnly?: boolean;
  clearable?: boolean;
  allowTextInput?: boolean;
  minuteStep?: number;
  labels?: Partial<KPickerLabels>;
  now?: Date;
}
export function KDatePicker(props: KPickerProps) {
  return <Picker {...props} kind="date" />;
}
export function KTimePicker(props: KPickerProps) {
  return <Picker {...props} kind="time" />;
}
export function KDateTimePicker(props: KPickerProps) {
  return <Picker {...props} kind="datetime" />;
}
function Picker({
  presentation = "standard",
  kind,
  value,
  onValueChange,
  onOpenChange,
  label,
  timeZone: explicitTimeZone,
  locale: explicitLocale,
  dateFormat: explicitDateFormat,
  timeFormat: explicitTimeFormat,
  disambiguation = "reject",
  min,
  max,
  disabled = false,
  readOnly = false,
  clearable = false,
  allowTextInput = false,
  minuteStep = 1,
  labels: overrides,
  now,
}: KPickerProps & { kind: PickerKind }) {
  const localization = useKLocalization(explicitLocale);
  const timeZone = explicitTimeZone ?? localization.timeZone;
  const dateFormat = explicitDateFormat ?? localization.dateFormat;
  const timeFormat = explicitTimeFormat ?? localization.timeFormat;
  const locale = localization.calendarLocale;
  validateConfiguration(kind, value, min, max, timeZone);
  validateMinuteStep(minuteStep);
  const labels = { ...localization.messages, ...overrides },
    field = useField(),
    id = useId();
  const title =
    kind === "date"
      ? labels.chooseDate
      : kind === "time"
        ? labels.chooseTime
        : labels.chooseDateTime;
  const formatValue = (v: string | null) => {
    if (!v) return "";
    const parts = valueParts(v, kind, timeZone, now ?? new Date());
    return kind === "date"
      ? formatDate(parts.date, dateFormat)
      : kind === "time"
        ? formatTime(parts.time, timeFormat)
        : `${formatDate(parts.date, dateFormat)} ${formatTime(parts.time, timeFormat)}`;
  };
  const formatted = formatValue(value);
  const [text, setText] = useState(formatted),
    [error, setError] = useState<PickerError | null>(null);
  const [open, setOpen] = useState(false),
    [dateDraft, setDateDraft] = useState(""),
    [timeDraft, setTimeDraft] = useState("");
  const [panelError, setPanelError] = useState<PickerError | null>(null);
  const [calendarDate, setCalendarDate] = useState(
    valueParts(value, kind, timeZone, now ?? new Date()).date,
  );
  const opened = useRef(false);
  const openListener = useRef<KPickerProps["onOpenChange"]>(undefined);
  function releaseOwnership() {
    if (!opened.current) return;
    opened.current = false;
    const listener = openListener.current;
    openListener.current = undefined;
    listener?.(false);
  }
  useEffect(() => () => releaseOwnership(), []);
  const dialog = useRef<HTMLDialogElement>(null),
    trigger = useRef<HTMLButtonElement>(null);
  useEffect(() => {
    setText(formatted);
    setError(null);
  }, [formatted]);
  const dateBoundary = (boundary?: string) =>
    !boundary
      ? undefined
      : kind === "datetime"
        ? zoneParts(new Date(boundary), timeZone).date
        : kind === "date"
          ? boundary
          : undefined;
  const dateMin = dateBoundary(min),
    dateMax = dateBoundary(max);
  function evaluate(
    dateText: string,
    timeText: string,
  ): { value: string | null; error?: PickerError } {
    const date =
      kind === "time" ? calendarDate : parseDate(dateText, dateFormat);
    const time = kind === "date" ? "00:00" : parseTime(timeText, timeFormat);
    if (!date || !time) return { value: null, error: "invalid" };
    let result: string;
    if (kind === "datetime") {
      const resolved = resolveLocal(date, time, timeZone, disambiguation);
      if (resolved.error) return { value: null, error: resolved.error };
      result = resolved.value;
    } else result = kind === "date" ? date : time;
    return inRange(result, kind, min, max)
      ? { value: result }
      : { value: null, error: "outOfRange" };
  }
  function commitText() {
    if (disabled || readOnly || !allowTextInput || text === formatted) return;
    if (!text.trim()) {
      onValueChange(null);
      setError(null);
      return;
    }
    const pieces = kind === "datetime" ? text.trim().split(/\s+/) : [];
    const result = evaluate(
      kind === "datetime" ? pieces[0] : text,
      kind === "datetime" ? pieces.slice(1).join(" ") : text,
    );
    if (result.error) setError(result.error);
    else {
      setError(null);
      onValueChange(result.value);
      setText(formatValue(result.value));
    }
  }
  function show() {
    if (disabled || readOnly || opened.current) return;
    const parts = valueParts(value, kind, timeZone, now ?? new Date());
    const date =
      dateMin && parts.date < dateMin
        ? dateMin
        : dateMax && parts.date > dateMax
          ? dateMax
          : parts.date;
    setCalendarDate(date);
    setDateDraft(formatDate(date, dateFormat));
    setTimeDraft(formatTime(parts.time, timeFormat));
    setPanelError(null);
    opened.current = true;
    openListener.current = onOpenChange;
    onOpenChange?.(true);
    setOpen(true);
  }
  function close() {
    dialog.current?.close();
    setOpen(false);
    trigger.current?.focus();
    releaseOwnership();
  }
  useEffect(() => {
    if (open) {
      dialog.current?.showModal();
      dialog.current
        ?.querySelector<HTMLElement>(
          'input, [data-date][tabindex="0"], [aria-pressed="true"]',
        )
        ?.focus({ preventScroll: true });
    }
  }, [open]);
  useEffect(() => {
    if ((disabled || readOnly) && open) {
      dialog.current?.close();
      setOpen(false);
      releaseOwnership();
    }
  }, [disabled, readOnly, open]);
  const placeholder =
    kind === "date"
      ? dateFormat === "iso"
        ? "YYYY-MM-DD"
        : dateFormat === "dayMonthYear"
          ? "DD.MM.YYYY"
          : "MM/DD/YYYY"
      : kind === "time"
        ? timeFormat === "h24"
          ? "HH:mm"
          : "hh:mm AM/PM"
        : `${dateFormat === "iso" ? "YYYY-MM-DD" : dateFormat === "dayMonthYear" ? "DD.MM.YYYY" : "MM/DD/YYYY"} ${timeFormat === "h24" ? "HH:mm" : "hh:mm AM/PM"}`;
  return (
    <div className="k-picker">
      {presentation === "inline" ? (
        <button
          type="button"
          ref={trigger}
          className="k-editable-cell"
          aria-label={label ?? title}
          aria-haspopup="dialog"
          aria-expanded={open}
          disabled={disabled || readOnly}
          onClick={show}
        >
          {formatted || placeholder}
        </button>
      ) : (
        <div
          className="k-picker-control"
          onClick={(e) => {
            if (!allowTextInput && !(e.target as HTMLElement).closest("button"))
              show();
          }}
          data-select-only={
            (!allowTextInput && !readOnly && !disabled) || undefined
          }
        >
          <KInput
            aria-label={label}
            aria-describedby={
              [field.description, error ? `${id}-error` : undefined]
                .filter(Boolean)
                .join(" ") || undefined
            }
            aria-invalid={!!error || field.invalid || undefined}
            value={text}
            placeholder={placeholder}
            disabled={disabled}
            readOnly={readOnly || !allowTextInput}

            onChange={(e) => setText(e.target.value)}
            onBlur={(e) => {
              if (e.relatedTarget !== trigger.current) commitText();
            }}
            onKeyDown={(e) => {
              if (!allowTextInput && (e.key === "Enter" || e.key === " ")) {
                e.preventDefault();
                show();
                return;
              }
              if (e.key === "Enter") {
                e.preventDefault();
                commitText();
              }
              if (e.key === "ArrowDown" && e.altKey) {
                e.preventDefault();
                show();
              }
            }}
          />
          <KIconButton
            ref={trigger}
            label={title}
            icon={kind === "time" ? "clock" : "calendar"}
            disabled={disabled || readOnly}
            aria-haspopup="dialog"
            aria-expanded={open}
            onClick={show}
          />
        </div>
      )}
      {error && (
        <span id={`${id}-error`} className="k-picker-error" role="alert">
          {labels[error]}
        </span>
      )}
      <dialog
        ref={dialog}
        className="k-picker-dialog"
        data-kind={kind}
        aria-labelledby={`${id}-title`}
        onClose={() => {
          if (opened.current) close();
        }}
        onCancel={(e) => {
          e.preventDefault();
          close();
        }}
        onClick={(e) => {
          if (e.target === e.currentTarget) {
            const r = e.currentTarget.getBoundingClientRect();
            if (
              e.clientX < r.left ||
              e.clientX > r.right ||
              e.clientY < r.top ||
              e.clientY > r.bottom
            )
              close();
          }
        }}
      >
        {open && (
          <div className="k-picker-panel">
            <div id={`${id}-title`} className="k-picker-title">
              {title}
            </div>
            <PickerBody
              kind={kind}
              initialDayConfirmed={Boolean(value)}
              allowTextInput={allowTextInput}
              dateDraft={dateDraft}
              timeDraft={timeDraft}
              onDateDraft={(v) => {
                setDateDraft(v);
                setPanelError(null);
              }}
              onTimeDraft={(v) => {
                setTimeDraft(v);
                setPanelError(null);
              }}
              calendarDate={calendarDate}
              onCalendarDate={setCalendarDate}
              onSelectDate={(date) => {
                setCalendarDate(date);
                setDateDraft(formatDate(date, dateFormat));
                setPanelError(null);
              }}
              locale={locale}
              dateFormat={dateFormat}
              timeFormat={timeFormat}
              minuteStep={minuteStep}
              labels={labels}
              min={dateMin}
              max={dateMax}
            />
            {panelError && (
              <span className="k-picker-error" role="alert">
                {labels[panelError]}
              </span>
            )}
            <div className="k-picker-footer">
              {clearable && (
                <KButton
                  variant="ghost"
                  disabled={value === null}
                  onClick={() => {
                    onValueChange(null);
                    setText("");
                    setError(null);
                    close();
                  }}
                >
                  {labels.clear}
                </KButton>
              )}
              <span className="k-picker-footer-space" />
              <KButton variant="ghost" onClick={close}>
                {labels.cancel}
              </KButton>
              <KButton
                onClick={() => {
                  const result = evaluate(dateDraft, timeDraft);
                  if (result.error) setPanelError(result.error);
                  else {
                    onValueChange(result.value);
                    setText(formatValue(result.value));
                    setError(null);
                    close();
                  }
                }}
              >
                {labels.apply}
              </KButton>
            </div>
          </div>
        )}
      </dialog>
    </div>
  );
}
