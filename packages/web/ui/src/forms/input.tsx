import { useKLocalization } from "../localization/provider.js";
import { useEffect, useRef, useState, type InputHTMLAttributes } from "react";
import { KIcon } from "../primitives/icon.js";
import { useField } from "./field.js";
import { ClearButton } from "./clear-button.js";
export interface KInputProps extends Omit<
  InputHTMLAttributes<HTMLInputElement>,
  "size"
> {
  clearable?: boolean;
  clearLabel?: string;
  /** Update the application value when a controlled input is cleared. */
  onClear?: () => void;
}
export function KInput({
  className = "",
  clearable = false,
  clearLabel,
  onClear,
  value,
  defaultValue,
  onChange,
  ...props
}: KInputProps) {
  const { messages } = useKLocalization();
  const field = useField();
  const input = useRef<HTMLInputElement>(null);
  const [localValue, setLocalValue] = useState(defaultValue ?? "");
  useEffect(() => {
    const form = input.current?.form;
    const reset = () =>
      queueMicrotask(() => setLocalValue(input.current?.value ?? ""));
    form?.addEventListener("reset", reset);
    return () => form?.removeEventListener("reset", reset);
  });
  const current = value ?? localValue;
  const canClear =
    clearable &&
    String(current).length > 0 &&
    !props.disabled &&
    !props.readOnly &&
    (value === undefined || !!onClear);
  return (
    <span
      className="k-input-target k-input-clearable"
      data-clearable={canClear || undefined}
    >
      <input
        id={field.id}
        aria-describedby={field.description}
        aria-invalid={field.invalid || undefined}
        required={field.required}
        {...props}
        ref={input}
        value={value}
        defaultValue={defaultValue}
        onChange={(event) => {
          setLocalValue(event.target.value);
          onChange?.(event);
        }}
        className={`k-input ${className}`}
      />
      {canClear && (
        <ClearButton
          label={clearLabel ?? messages.clear}
          onClear={() => {
            if (value === undefined && input.current) input.current.value = "";
            setLocalValue("");
            onClear?.();
            input.current?.focus();
          }}
        />
      )}
    </span>
  );
}
export function KSearchField(props: KInputProps) {
  return (
    <span className="k-search-field">
      <KIcon name="search" />
      <KInput type="search" {...props} />
    </span>
  );
}
