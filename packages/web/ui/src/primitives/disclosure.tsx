import {
  useId,
  useState,
  useRef,
  useEffect,
  type HTMLAttributes,
  type ReactNode,
} from "react";
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
  /** Reveal newly expanded content within its nearest scroll container. */
  scrollOnOpen?: boolean;
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
  scrollOnOpen = false,
  onOpenChange,
  disabled = false,
  className,
  ...props
}: KDisclosureProps) {
  const [internalOpen, setInternalOpen] = useState(defaultOpen);
  const expanded = open ?? internalOpen;
  const id = useId();
  const root = useRef<HTMLElement>(null);
  const previouslyExpanded = useRef(expanded);
  useEffect(() => {
    const opening = expanded && !previouslyExpanded.current;
    previouslyExpanded.current = expanded;
    if (!opening || !scrollOnOpen) return;
    const frame = requestAnimationFrame(() => {
      const element = root.current;
      if (!element) return;
      let parent = element.parentElement;
      while (
        parent &&
        !/(auto|scroll)/.test(getComputedStyle(parent).overflowY)
      )
        parent = parent.parentElement;
      if (!parent) return;
      const bounds = element.getBoundingClientRect();
      const viewport = parent.getBoundingClientRect();
      if (bounds.bottom <= viewport.bottom && bounds.top >= viewport.top)
        return;
      const distance = Math.min(
        bounds.top - viewport.top,
        bounds.bottom - viewport.bottom,
      );
      parent.scrollTo({
        top: parent.scrollTop + distance,
        behavior: matchMedia("(prefers-reduced-motion: reduce)").matches
          ? "instant"
          : "smooth",
      });
    });
    return () => cancelAnimationFrame(frame);
  }, [expanded, scrollOnOpen]);
  const toggle = () => {
    const next = !expanded;
    if (open === undefined) setInternalOpen(next);
    onOpenChange?.(next);
  };

  return (
    <section
      ref={root}
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
