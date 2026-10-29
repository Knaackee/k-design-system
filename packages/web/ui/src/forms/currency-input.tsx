import { useEffect, useState, type Ref } from "react";
import { useField } from "./field.js";
import { KInput, type KInputProps } from "./input.js";
import {
  formatCurrencyMinorUnits,
  parseCurrencyMinorUnits,
  type KCurrencyFormat,
} from "./currency-value.js";
export interface KCurrencyInputProps
  extends
    Omit<
      KInputProps,
      "value" | "defaultValue" | "onChange" | "type" | "onClear"
    >,
    KCurrencyFormat {
  ref?: Ref<HTMLInputElement>;
  value: number | null;
  onCommit: (value: number | null) => void;
  onInvalidDraft?: (draft: string) => void;
}
export function KCurrencyInput({
  value,
  onCommit,
  onInvalidDraft,
  currency,
  locale,
  fractionDigits = 2,
  onFocus,
  onBlur,
  onKeyDown,
  ...props
}: KCurrencyInputProps) {
  const field = useField();
  const options = { currency, locale, fractionDigits };
  const [focused, setFocused] = useState(false);
  const [invalid, setInvalid] = useState(false);
  const [draft, setDraft] = useState(() =>
    formatCurrencyMinorUnits(value, options),
  );
  useEffect(() => {
    setDraft(
      formatCurrencyMinorUnits(
        value,
        { currency, locale, fractionDigits },
        !focused,
      ),
    );
    setInvalid(false);
  }, [value, currency, locale, fractionDigits, focused]);
  const commit = () => {
    if (props.disabled || props.readOnly) return true;
    const parsed = parseCurrencyMinorUnits(draft, options);
    setInvalid(!parsed.valid);
    if (!parsed.valid) {
      onInvalidDraft?.(draft);
      return false;
    }
    onCommit(parsed.value);
    return true;
  };
  return (
    <KInput
      {...props}
      type="text"
      inputMode="decimal"
      value={draft}
      aria-invalid={
        invalid || props["aria-invalid"] || field.invalid || undefined
      }
      onChange={(event) => {
        setDraft(event.target.value);
        setInvalid(false);
      }}
      onClear={() => {
        setDraft("");
        setInvalid(false);
        onCommit(null);
      }}
      onFocus={(event) => {
        setFocused(true);
        onFocus?.(event);
      }}
      onBlur={(event) => {
        if (commit()) setFocused(false);
        onBlur?.(event);
      }}
      onKeyDown={(event) => {
        if (!event.nativeEvent.isComposing && event.key === "Enter") {
          event.preventDefault();
          commit();
        }
        if (event.key === "Escape") {
          setDraft(formatCurrencyMinorUnits(value, options, !focused));
          setInvalid(false);
        }
        onKeyDown?.(event);
      }}
    />
  );
}
