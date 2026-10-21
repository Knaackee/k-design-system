import { useKLocalization } from "../localization/provider.js";
import {
  useEffect,
  useId,
  useRef,
  useState,
  type KeyboardEvent,
  type ChangeEventHandler,
  type ReactNode,
} from "react";
import { useField } from "./field.js";
import { KIcon, type KIconName } from "../primitives/icon.js";
import { OptionMedia } from "./option-media.js";
import { ClearButton } from "./clear-button.js";
export interface KSelectOption {
  value: string;
  label: string;
  description?: string;
  disabled?: boolean;
  icon?: KIconName;
  /** Decorative media; takes precedence over icon and imageSrc. */
  leading?: ReactNode;
  imageSrc?: string;
}
export interface KSelectProps {
  multiple?: boolean;
  values?: readonly string[];
  defaultValues?: readonly string[];
  onValuesChange?: (values: string[]) => void;
  selectionLabel?: string;
  presentation?: "standard" | "inline";
  /** Picker-width popup, bounded by the viewport, with concise option labels. */
  expandedPopup?: boolean;
  options: readonly KSelectOption[];
  value?: string | null;
  defaultValue?: string;
  onValueChange?: (value: string) => void;
  onChange?: ChangeEventHandler<HTMLSelectElement>;
  name?: string;
  form?: string;
  id?: string;
  required?: boolean;
  label?: string;
  placeholder?: string;
  disabled?: boolean;
  clearable?: boolean;
  clearLabel?: string;
  optionsLabel?: string;
  noResultsLabel?: string;
  onClear?: () => void;
}
export function KSelect(props: KSelectProps) {
  return <Selection {...props} searchable={false} />;
}
export function KCombobox(props: KSelectProps) {
  return <Selection {...props} searchable />;
}
function Selection({
  multiple = false,
  values: controlledValues,
  defaultValues = [],
  onValuesChange,
  selectionLabel,
  options,
  value: controlledValue,
  defaultValue,
  onChange,
  name,
  form,
  id: suppliedId,
  required,
  onValueChange,
  label,
  placeholder,
  disabled = false,
  clearable = false,
  clearLabel,
  optionsLabel,
  noResultsLabel,
  onClear,
  expandedPopup = false,
  presentation = "standard",
  searchable,
}: KSelectProps & { searchable: boolean }) {
  const { messages } = useKLocalization();
  const field = useField();
  const generated = useId();
  const id = suppliedId ?? field.id ?? generated;
  const initialValue = useRef(
    defaultValue ??
      (controlledValue === undefined
        ? (options.find((option) => !option.disabled)?.value ?? "")
        : (controlledValue ?? "")),
  );
  const [localValue, setLocalValue] = useState(initialValue.current);
  const initialValues = useRef(defaultValues);
  const [localValues, setLocalValues] = useState<readonly string[]>(
    initialValues.current,
  );
  const values = controlledValues ?? localValues;
  const isSelected = (candidate: string) =>
    multiple ? values.includes(candidate) : candidate === value;
  const value = controlledValue === undefined ? localValue : controlledValue;
  const native = useRef<HTMLSelectElement>(null);
  const [validationMessage, setValidationMessage] = useState("");
  const input = useRef<HTMLInputElement>(null);
  const popup = useRef<HTMLDivElement>(null);
  const target = useRef<HTMLDivElement>(null);
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [active, setActive] = useState<string | null>(null);
  const selectedOptions = options.filter((option) => isSelected(option.value));
  const selectedOption = multiple
    ? selectedOptions.length === 1
      ? selectedOptions[0]
      : undefined
    : options.find((option) => option.value === value);
  const showMedia =
    !!(
      selectedOption?.leading ||
      selectedOption?.icon ||
      selectedOption?.imageSrc
    ) && !(searchable && open);
  const canClear =
    clearable &&
    (multiple || !!onClear) &&
    !disabled &&
    (multiple ? values.length > 0 : value !== null || query.length > 0);
  const selected = multiple
    ? (selectionLabel ??
      selectedOptions.map((option) => option.label).join(", "))
    : (options.find((option) => option.value === value)?.label ?? "");
  const filtered = options.filter(
    (option) =>
      !searchable ||
      !open ||
      option.label.toLowerCase().includes(query.toLowerCase()),
  );
  const enabled = filtered.filter((option) => !option.disabled);
  const close = () => {
    setOpen(false);
    setQuery("");
    setActive(null);
  };
  function show() {
    if (!disabled) {
      setQuery("");
      setOpen(true);
      setActive(
        options.find((option) => isSelected(option.value) && !option.disabled)
          ?.value ??
          options.find((option) => !option.disabled)?.value ??
          null,
      );
    }
  }
  function choose(next: string) {
    if (native.current) {
      if (multiple) {
        for (const option of native.current.options)
          option.selected =
            option.value === next
              ? !values.includes(next)
              : values.includes(option.value);
      } else native.current.value = next;
      native.current.dispatchEvent(new Event("change", { bubbles: true }));
    }
    if (!multiple) close();
    input.current?.focus();
  }
  useEffect(() => {
    const owner = native.current?.form;
    if (!owner) return;
    const reset = (event: Event) => {
      // Native reset applies after event dispatch; restore controlled state afterwards.
      setTimeout(() => {
        if (event.defaultPrevented) return;
        setLocalValue(initialValue.current);
        setLocalValues(initialValues.current);
        if (multiple) onValuesChange?.([...initialValues.current]);
        setValidationMessage("");
        if (!multiple) onValueChange?.(initialValue.current);
        close();
        if (native.current && !multiple)
          native.current.value =
            controlledValue === undefined
              ? initialValue.current
              : (controlledValue ?? "");
      });
    };
    owner.addEventListener("reset", reset);
    return () => owner.removeEventListener("reset", reset);
  }, [form, controlledValue, onValueChange, multiple, onValuesChange]);
  useEffect(() => {
    setValidationMessage("");
  }, [value]);
  useEffect(() => {
    if (disabled) setOpen(false);
  }, [disabled]);
  useEffect(() => {
    const panel = popup.current;
    if (!open || !panel || !target.current) return;
    panel.showPopover();
    function position() {
      const rect = target.current!.getBoundingClientRect();
      const pickerWidth = parseFloat(
        getComputedStyle(target.current!).getPropertyValue(
          "--k-layout-picker-width",
        ),
      );
      const width = Math.min(
        Math.max(rect.width, expandedPopup ? pickerWidth : 0),
        innerWidth - 16,
      );
      panel!.style.width = `${width}px`;
      panel!.style.left = `${Math.max(8, Math.min(rect.left, innerWidth - width - 8))}px`;
      const gap = parseFloat(
        getComputedStyle(target.current!).getPropertyValue(
          "--k-space-control-gap",
        ),
      );
      const below = innerHeight - rect.bottom - gap - 8;
      const above = rect.top - gap - 8;
      const opensAbove = below < 120 && above > below;
      panel!.style.maxHeight = `${Math.max(0, Math.min(280, opensAbove ? above : below))}px`;
      const height = panel!.getBoundingClientRect().height;
      panel!.style.top = `${opensAbove ? rect.top - gap - height : rect.bottom + gap}px`;
    }
    position();
    const observer = new ResizeObserver(position);
    observer.observe(panel);
    const outside = (event: PointerEvent) => {
      if (
        !target.current?.contains(event.target as Node) &&
        !panel.contains(event.target as Node)
      )
        close();
    };
    document.addEventListener("pointerdown", outside);
    window.addEventListener("resize", position);
    const onScroll = (event: Event) => {
      if (
        event.target !== input.current &&
        !panel.contains(event.target as Node)
      )
        close();
    };
    window.addEventListener("scroll", onScroll, true);
    return () => {
      observer.disconnect();
      if (panel.matches(":popover-open")) panel.hidePopover();
      document.removeEventListener("pointerdown", outside);
      window.removeEventListener("resize", position);
      window.removeEventListener("scroll", onScroll, true);
    };
  }, [open, expandedPopup]);
  useEffect(() => {
    if (open)
      document
        .getElementById(`${id}-option-${active}`)
        ?.scrollIntoView({ block: "nearest" });
  }, [active, id, open]);
  function keyDown(event: KeyboardEvent<HTMLInputElement>) {
    if (
      !searchable &&
      (event.ctrlKey || event.metaKey) &&
      event.key.toLowerCase() === "a"
    ) {
      event.preventDefault();
      return;
    }
    if (event.key === "Escape" && open) {
      event.preventDefault();
      event.stopPropagation();
      close();
    } else if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault();
      if (!open) {
        show();
        return;
      }
      const index = enabled.findIndex((option) => option.value === active);
      const next =
        enabled[
          (index + (event.key === "ArrowDown" ? 1 : -1) + enabled.length) %
            enabled.length
        ];
      setActive(next?.value ?? null);
    } else if (event.key === "Enter" || (!searchable && event.key === " ")) {
      event.preventDefault();
      if (!open) show();
      else if (
        active !== null &&
        enabled.some((option) => option.value === active)
      )
        choose(active);
    } else if (!searchable && (event.key === "Home" || event.key === "End")) {
      event.preventDefault();
      if (!open) show();
      setActive(
        (event.key === "Home" ? enabled[0] : enabled.at(-1))?.value ?? null,
      );
    } else if (!searchable && event.key.length === 1) {
      const match = options.find(
        (option) =>
          !option.disabled &&
          option.label.toLowerCase().startsWith(event.key.toLowerCase()),
      );
      if (match) {
        event.preventDefault();
        if (!open) show();
        setActive(match.value);
      }
    }
  }
  return (
    <div
      className="k-selection"
      data-presentation={presentation}
      data-open={open || undefined}
      ref={target}
      onBlur={(event) => {
        if (!event.currentTarget.contains(event.relatedTarget)) close();
      }}
      data-media={showMedia || undefined}
      data-clearable={canClear || undefined}
    >
      <span className="k-input-target">
        <input
          ref={input}
          className="k-input"
          id={id}
          role="combobox"
          aria-label={label}
          aria-describedby={
            [
              field.description,
              validationMessage ? `${id}-validation` : undefined,
            ]
              .filter(Boolean)
              .join(" ") || undefined
          }
          aria-invalid={field.invalid || !!validationMessage || undefined}
          aria-required={(required ?? field.required) || undefined}
          aria-expanded={open}
          aria-controls={open ? `${id}-list` : undefined}
          aria-activedescendant={
            open &&
            active !== null &&
            filtered.some((option) => option.value === active)
              ? `${id}-option-${active}`
              : undefined
          }
          aria-autocomplete={searchable ? "list" : "none"}
          readOnly={!searchable}
          disabled={disabled}
          placeholder={placeholder ?? messages.choose}
          value={searchable && open ? query : selected}
          onFocus={(event) => {
            if (!searchable) event.currentTarget.setSelectionRange(0, 0);
          }}
          onPointerDown={(event) => {
            if (!searchable && !disabled) {
              event.preventDefault();
              input.current?.focus();
            }
          }}
          onSelect={(event) => {
            if (
              !searchable &&
              (event.currentTarget.selectionStart !== 0 ||
                event.currentTarget.selectionEnd !== 0)
            )
              event.currentTarget.setSelectionRange(0, 0);
          }}
          onClick={() => {
            if (open && !searchable) close();
            else if (!open) show();
          }}

          onChange={(event) => {
            setOpen(true);
            setQuery(event.target.value);
            setActive(
              options.find(
                (option) =>
                  !option.disabled &&
                  option.label
                    .toLowerCase()
                    .includes(event.target.value.toLowerCase()),
              )?.value ?? null,
            );
          }}
          onKeyDown={keyDown}
        />
      </span>
      <select
        ref={native}
        className="k-selection__native"
        aria-hidden="true"
        tabIndex={-1}
        name={name}
        form={form}
        required={required ?? field.required}
        disabled={disabled}
        multiple={multiple}
        value={multiple ? [...values] : (value ?? "")}
        onChange={(event) => {
          setLocalValue(event.currentTarget.value);
          setValidationMessage("");
          if (multiple) {
            const next = Array.from(
              event.currentTarget.selectedOptions,
              (option) => option.value,
            );
            setLocalValues(next);
            onValuesChange?.(next);
          } else onValueChange?.(event.currentTarget.value);
          onChange?.(event);
        }}
        onInvalid={(event) => {
          event.preventDefault();
          setValidationMessage(event.currentTarget.validationMessage);
          input.current?.focus();
        }}
      >
        {!multiple && !options.some((option) => option.value === "") && (
          <option value="" />
        )}
        {options.map((option) => (
          <option
            key={option.value}
            value={option.value}
            disabled={option.disabled}
          >
            {option.label}
          </option>
        ))}
      </select>
      {showMedia && (
        <span className="k-selection__media">
          <OptionMedia {...selectedOption} />
        </span>
      )}
      {canClear && (
        <ClearButton
          label={clearLabel ?? messages.clear}
          onClear={() => {
            if (multiple && native.current) {
              for (const option of native.current.options)
                option.selected = false;
              native.current.dispatchEvent(
                new Event("change", { bubbles: true }),
              );
            } else choose("");
            onClear?.();
            close();
            input.current?.focus();
          }}
        />
      )}
      <span className="k-selection__arrow">
        <KIcon name="chevron-down" />
      </span>
      {open && (
        <div
          ref={popup}
          popover="manual"
          className="k-select-list"
          data-expanded={expandedPopup || undefined}
          id={`${id}-list`}
          role="listbox"
          aria-multiselectable={multiple || undefined}
          aria-label={optionsLabel ?? label ?? messages.options}
          onPointerDown={(event) => event.preventDefault()}
        >
          {filtered.map((option) => (
            <div
              id={`${id}-option-${option.value}`}
              key={option.value}
              role="option"
              aria-selected={isSelected(option.value)}
              aria-disabled={option.disabled || undefined}
              data-active={active === option.value || undefined}
              className="k-select-option"
              onPointerMove={() => {
                if (!option.disabled) setActive(option.value);
              }}
              onClick={() => {
                if (!option.disabled) choose(option.value);
              }}
            >
              <span className="k-select-option__label">
                <OptionMedia {...option} />
                <span className="k-select-option__text">
                  <span className="k-select-option__title">{option.label}</span>
                  {option.description && (
                    <span className="k-select-option__description">
                      {option.description}
                    </span>
                  )}
                </span>
              </span>
              {multiple ? (
                <KIcon
                  name={isSelected(option.value) ? "square-check" : "square"}
                />
              ) : (
                isSelected(option.value) && <KIcon name="check" />
              )}
            </div>
          ))}
          {!filtered.length && (
            <div className="k-select-empty" role="status">
              {noResultsLabel ?? messages.noResults}
            </div>
          )}
        </div>
      )}
      {validationMessage && (
        <span
          id={`${id}-validation`}
          className="k-field__description k-field__error"
          role="alert"
        >
          {validationMessage}
        </span>
      )}
    </div>
  );
}
