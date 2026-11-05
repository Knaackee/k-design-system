import { useId, type HTMLAttributes } from "react";

export interface KRadioItem {
  value: string;
  label: string;
  disabled?: boolean;
}

export interface KRadioGroupProps extends Omit<
  HTMLAttributes<HTMLFieldSetElement>,
  "onChange"
> {
  label: string;
  items: readonly KRadioItem[];
  value: string | null;
  onValueChange?: (value: string) => void;
  name?: string;
  disabled?: boolean;
  required?: boolean;
  orientation?: "horizontal" | "vertical";
  /** Segmented choices retain native radio semantics and wrap when needed. */
  appearance?: "radio" | "segmented";
}

/** Native radios provide form submission, arrow navigation and single selection. */
export function KRadioGroup({
  label,
  items,
  value,
  onValueChange,
  name,
  disabled = false,
  required = false,
  orientation = "vertical",
  appearance = "radio",
  className = "",
  ...props
}: KRadioGroupProps) {
  const id = useId();
  return (
    <fieldset
      {...props}
      className={`k-radio-group ${className}`}
      disabled={disabled || !onValueChange}
      data-appearance={appearance}
    >
      <legend>{label}</legend>
      <div className="k-radio-group__items" data-orientation={orientation}>
        {items.map((item) => (
          <label className="k-radio" key={item.value}>
            <input
              type="radio"
              name={name ?? id}
              value={item.value}
              checked={value === item.value}
              disabled={item.disabled}
              required={required}
              onChange={() => onValueChange?.(item.value)}
            />
            <span className="k-radio__indicator" aria-hidden="true" />
            <span>{item.label}</span>
          </label>
        ))}
      </div>
    </fieldset>
  );
}
