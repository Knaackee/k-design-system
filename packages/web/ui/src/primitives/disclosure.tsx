import { useId, useState, type HTMLAttributes, type ReactNode } from "react";
import { KIcon } from "./icon.js";

export interface KDisclosureProps extends Omit<
  HTMLAttributes<HTMLElement>,
  "title"
> {
  title: string;
  children: ReactNode;
  leadingIcon?: ReactNode;
  titleIcon?: ReactNode;
  actions?: ReactNode;
  open?: boolean;
  defaultOpen?: boolean;
  onOpenChange?: (open: boolean) => void;
  disabled?: boolean;
}

export function KDisclosure({
  title,
  children,
  leadingIcon,
  titleIcon,
  actions,
  open,
  defaultOpen = false,
  onOpenChange,
  disabled = false,
  className,
  ...props
}: KDisclosureProps) {
  const [internalOpen, setInternalOpen] = useState(defaultOpen);
  const expanded = open ?? internalOpen;
  const id = useId();
  const toggle = () => {
    const next = !expanded;
    if (open === undefined) setInternalOpen(next);
    onOpenChange?.(next);
  };

  return (
    <section
      className={["k-disclosure", className].filter(Boolean).join(" ")}
      {...props}
    >
      <div className="k-disclosure__header">
        <button
          type="button"
          className="k-disclosure__toggle"
          aria-expanded={expanded}
          aria-controls={`${id}-panel`}
          id={`${id}-trigger`}
          disabled={disabled}
          onClick={toggle}
        >
          <KIcon name={expanded ? "chevron-down" : "chevron-right"} size={18} />
          {leadingIcon}
          <span className="k-disclosure__title">{title}</span>
          {titleIcon}
        </button>
        {actions ? (
          <div className="k-disclosure__actions">{actions}</div>
        ) : null}
      </div>
      <div
        className="k-disclosure__panel"
        id={`${id}-panel`}
        aria-labelledby={`${id}-trigger`}
        hidden={!expanded}
      >
        {children}
      </div>
    </section>
  );
}

export interface KAccordionItem {
  id: string;
  title: string;
  content: ReactNode;
  leadingIcon?: ReactNode;
  titleIcon?: ReactNode;
  actions?: ReactNode;
  disabled?: boolean;
}

export interface KAccordionProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  "onChange"
> {
  items: readonly KAccordionItem[];
  multiple?: boolean;
  value?: readonly string[];
  defaultValue?: readonly string[];
  onValueChange?: (value: string[]) => void;
}

export function KAccordion({
  items,
  multiple = false,
  value,
  defaultValue = [],
  onValueChange,
  className,
  ...props
}: KAccordionProps) {
  const [internalValue, setInternalValue] =
    useState<readonly string[]>(defaultValue);
  const expanded = value ?? internalValue;
  const update = (id: string, open: boolean) => {
    const next = open
      ? multiple
        ? [...expanded.filter((item) => item !== id), id]
        : [id]
      : expanded.filter((item) => item !== id);
    if (value === undefined) setInternalValue(next);
    onValueChange?.(next);
  };

  return (
    <div
      className={["k-accordion", className].filter(Boolean).join(" ")}
      {...props}
    >
      {items.map((item) => (
        <KDisclosure
          key={item.id}
          title={item.title}
          leadingIcon={item.leadingIcon}
          titleIcon={item.titleIcon}
          actions={item.actions}
          disabled={item.disabled}
          open={expanded.includes(item.id)}
          onOpenChange={(open) => update(item.id, open)}
        >
          {item.content}
        </KDisclosure>
      ))}
    </div>
  );
}
