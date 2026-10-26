import {
  cloneElement,
  isValidElement,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
  type CSSProperties,
  type HTMLAttributes,
  type KeyboardEvent,
  type ReactElement,
  type ReactNode,
  type RefObject,
} from "react";
import { createPortal } from "react-dom";
import { KIcon, type KIconName } from "./primitives/icon.js";
import { KButton } from "./primitives/button.js";
import { KIconButton } from "./actions/icon-button.js";
import { useHorizontalDragScroll } from "./util/use-horizontal-drag-scroll.js";
import {
  KBottomSheet,
  KDesktopDialog,
  KDialog,
  type KOverlayProps,
} from "./overlays/overlay.js";

export function KKbd({ className, ...props }: HTMLAttributes<HTMLElement>) {
  return (
    <kbd
      className={["k-kbd", className].filter(Boolean).join(" ")}
      {...props}
    />
  );
}

export function KKbdGroup({
  className,
  ...props
}: HTMLAttributes<HTMLSpanElement>) {
  return (
    <span
      className={["k-kbd-group", className].filter(Boolean).join(" ")}
      {...props}
    />
  );
}

export interface KProgressProps extends HTMLAttributes<HTMLDivElement> {
  value?: number;
  max?: number;
  label?: ReactNode;
  valueLabel?: ReactNode;
}
export function KProgress({
  value,
  max = 100,
  label,
  valueLabel,
  className,
  ...props
}: KProgressProps) {
  const safe =
    value === undefined ? undefined : Math.max(0, Math.min(max, value));
  return (
    <div
      className={["k-progress", className].filter(Boolean).join(" ")}
      {...props}
    >
      {label || valueLabel ? (
        <div className="k-progress__meta">
          <span>{label}</span>
          <span>
            {valueLabel ??
              (safe === undefined ? "" : `${Math.round((safe / max) * 100)}%`)}
          </span>
        </div>
      ) : null}
      <div
        className="k-progress__track"
        role="progressbar"
        aria-valuemin={0}
        aria-valuemax={max}
        aria-valuenow={safe}
        aria-label={typeof label === "string" ? label : undefined}
      >
        <span
          className="k-progress__indicator"
          data-indeterminate={safe === undefined || undefined}
          style={
            safe === undefined ? undefined : { width: `${(safe / max) * 100}%` }
          }
        />
      </div>
    </div>
  );
}

export interface KSkeletonProps extends HTMLAttributes<HTMLSpanElement> {
  circle?: boolean;
}
export function KSkeleton({ circle, className, ...props }: KSkeletonProps) {
  return (
    <span
      aria-hidden="true"
      className={["k-skeleton", circle && "k-skeleton--circle", className]
        .filter(Boolean)
        .join(" ")}
      {...props}
    />
  );
}

export interface KSpinnerProps extends HTMLAttributes<HTMLSpanElement> {
  label?: string;
  size?: number;
}
export function KSpinner({
  label = "Loading",
  size = 18,
  className,
  style,
  ...props
}: KSpinnerProps) {
  return (
    <span
      role="status"
      aria-label={label}
      className={["k-spinner", className].filter(Boolean).join(" ")}
      style={{ width: size, height: size, ...style }}
      {...props}
    />
  );
}

export interface KSwitchProps extends Omit<
  HTMLAttributes<HTMLButtonElement>,
  "onChange"
> {
  checked: boolean;
  onCheckedChange: (checked: boolean) => void;
  label: string;
  disabled?: boolean;
  /** Hide visible text when a surrounding settings row already supplies it. */
  showLabel?: boolean;
}
export function KSwitch({
  checked,
  onCheckedChange,
  label,
  showLabel = true,
  disabled,
  className,
  ...props
}: KSwitchProps) {
  const control = (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      disabled={disabled}
      className={["k-switch", className].filter(Boolean).join(" ")}
      onClick={() => onCheckedChange(!checked)}
      {...props}
    >
      <span className="k-switch__thumb" />
    </button>
  );
  return showLabel ? (
    <label className="k-switch-field" data-disabled={disabled || undefined}>
      {control}
      <span className="k-switch-field__label">{label}</span>
    </label>
  ) : (
    control
  );
}

export interface KSliderProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  "onChange"
> {
  value: number;
  onValueChange: (value: number) => void;
  min?: number;
  max?: number;
  step?: number;
  label: string;
  disabled?: boolean;
  valueLabel?: (value: number) => string;
}
export function KSlider({
  value,
  onValueChange,
  min = 0,
  max = 100,
  step = 1,
  label,
  disabled,
  valueLabel,
  className,
  ...props
}: KSliderProps) {
  const percent = ((value - min) / Math.max(1, max - min)) * 100;
  return (
    <div
      className={["k-slider", className].filter(Boolean).join(" ")}
      {...props}
    >
      <input
        type="range"
        value={value}
        min={min}
        max={max}
        step={step}
        disabled={disabled}
        aria-label={label}
        aria-valuetext={valueLabel?.(value)}
        style={{ "--k-slider-value": `${percent}%` } as CSSProperties}
        onChange={(event) => onValueChange(Number(event.target.value))}
      />
    </div>
  );
}

export interface KInputOtpProps {
  value: string;
  onValueChange: (value: string) => void;
  length?: number;
  label: string;
  separatorAfter?: number[];
  disabled?: boolean;
  invalid?: boolean;
  autoFocus?: boolean;
  inputMode?: "numeric" | "text";
}
export function KInputOtp({
  value,
  onValueChange,
  length = 6,
  label,
  separatorAfter = [3],
  disabled,
  invalid,
  autoFocus,
  inputMode = "numeric",
}: KInputOtpProps) {
  const ref = useRef<HTMLInputElement>(null);
  const clean = (next: string) =>
    (inputMode === "numeric" ? next.replace(/\D/g, "") : next).slice(0, length);
  return (
    <div
      className="k-otp"
      data-invalid={invalid || undefined}
      onClick={() => ref.current?.focus()}
    >
      <input
        ref={ref}
        className="k-otp__input"
        value={value}
        maxLength={length}
        aria-label={label}
        aria-invalid={invalid}
        autoComplete="one-time-code"
        inputMode={inputMode === "numeric" ? "numeric" : "text"}
        disabled={disabled}
        autoFocus={autoFocus}
        onChange={(event) => onValueChange(clean(event.target.value))}
      />
      {Array.from({ length }, (_, index) => (
        <span key={index} className="k-otp__fragment">
          <span
            className="k-otp__slot"
            data-active={index === value.length || undefined}
          >
            {value[index] ?? ""}
          </span>
          {separatorAfter.includes(index + 1) && index + 1 < length ? (
            <span className="k-otp__separator" aria-hidden="true">
              −
            </span>
          ) : null}
        </span>
      ))}
    </div>
  );
}

export interface KPaginationProps {
  page: number;
  pageCount: number;
  onPageChange: (page: number) => void;
  label?: string;
  previousLabel?: string;
  nextLabel?: string;
  siblingCount?: number;
}
function paginationItems(
  page: number,
  count: number,
  siblings: number,
): Array<number | "ellipsis"> {
  if (count <= 7) return Array.from({ length: count }, (_, index) => index + 1);
  const pages = new Set([1, count]);
  for (let i = page - siblings; i <= page + siblings; i++)
    if (i > 1 && i < count) pages.add(i);
  const sorted = [...pages].sort((a, b) => a - b);
  const result: Array<number | "ellipsis"> = [];
  sorted.forEach((item, index) => {
    if (index && item - sorted[index - 1]! > 1) result.push("ellipsis");
    result.push(item);
  });
  return result;
}
export function KPagination({
  page,
  pageCount,
  onPageChange,
  label = "Pagination",
  previousLabel = "Previous page",
  nextLabel = "Next page",
  siblingCount = 1,
}: KPaginationProps) {
  return (
    <nav className="k-pagination" aria-label={label}>
      <KIconButton
        icon="chevron-left"
        label={previousLabel}
        disabled={page <= 1}
        onClick={() => onPageChange(page - 1)}
      />
      {paginationItems(page, pageCount, siblingCount).map((item, index) =>
        item === "ellipsis" ? (
          <span key={`e${index}`} className="k-pagination__ellipsis">
            …
          </span>
        ) : (
          <button
            key={item}
            type="button"
            className="k-pagination__page"
            aria-current={item === page ? "page" : undefined}
            onClick={() => onPageChange(item)}
          >
            {item}
          </button>
        ),
      )}
      <KIconButton
        icon="chevron-right"
        label={nextLabel}
        disabled={page >= pageCount}
        onClick={() => onPageChange(page + 1)}
      />
    </nav>
  );
}

export interface KTabItem {
  id: string;
  label: ReactNode;
  content: ReactNode;
  disabled?: boolean;
  icon?: KIconName;
}
export interface KTabsProps {
  items: KTabItem[];
  value?: string;
  defaultValue?: string;
  onValueChange?: (id: string) => void;
  label?: string;
}
export function KTabs({
  items,
  value,
  defaultValue,
  onValueChange,
  label = "Tabs",
}: KTabsProps) {
  const dragScroll = useHorizontalDragScroll<HTMLDivElement>();
  const [internal, setInternal] = useState(defaultValue ?? items[0]?.id ?? "");
  const current = value ?? internal;
  const select = (id: string) => {
    if (value === undefined) setInternal(id);
    onValueChange?.(id);
  };
  const keyDown = (event: KeyboardEvent<HTMLButtonElement>, index: number) => {
    if (!["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) return;
    event.preventDefault();
    let next =
      event.key === "Home"
        ? 0
        : event.key === "End"
          ? items.length - 1
          : (index + (event.key === "ArrowRight" ? 1 : -1) + items.length) %
            items.length;
    while (items[next]?.disabled)
      next =
        (next + (event.key === "ArrowLeft" ? -1 : 1) + items.length) %
        items.length;
    select(items[next]!.id);
  };
  return (
    <div className="k-tabs">
      <div
        {...dragScroll}
        role="tablist"
        aria-label={label}
        className="k-tabs__list"
      >
        {items.map((item, index) => (
          <button
            key={item.id}
            type="button"
            role="tab"
            id={`tab-${item.id}`}
            aria-controls={`panel-${item.id}`}
            aria-selected={item.id === current}
            disabled={item.disabled}
            tabIndex={item.id === current ? 0 : -1}
            onKeyDown={(event) => keyDown(event, index)}
            onClick={() => select(item.id)}
          >
            {item.icon ? <KIcon name={item.icon} /> : null}
            {item.label}
          </button>
        ))}
      </div>
      {items.map((item) => (
        <div
          key={item.id}
          role="tabpanel"
          id={`panel-${item.id}`}
          aria-labelledby={`tab-${item.id}`}
          hidden={item.id !== current}
          className="k-tabs__panel"
        >
          {item.content}
        </div>
      ))}
    </div>
  );
}

export interface KPopoverProps {
  showArrow?: boolean;
  portal?: boolean;
  /** Keep a controlled popover open while a nested modal is active. */
  closeOnInteractOutside?: boolean;
  anchorRef?: RefObject<HTMLElement | null>;
  trigger: ReactElement;
  children: ReactNode;
  open?: boolean;
  defaultOpen?: boolean;
  onOpenChange?: (open: boolean) => void;
  align?: "start" | "center" | "end";
  placement?: "auto" | "top";
  label?: string;
}
export function KPopover({
  showArrow = false,
  portal = false,
  closeOnInteractOutside = true,
  anchorRef,
  trigger,
  children,
  open,
  defaultOpen = false,
  onOpenChange,
  align = "center",
  placement = "auto",
  label,
}: KPopoverProps) {
  const [internal, setInternal] = useState(defaultOpen);
  const shown = open ?? internal;
  const root = useRef<HTMLSpanElement>(null);
  const contentRef = useRef<HTMLDivElement>(null);
  const portalContainer =
    portal && shown && typeof document !== "undefined"
      ? (root.current?.closest<HTMLElement>('[role="dialog"]') ?? document.body)
      : null;
  const [position, setPosition] = useState<CSSProperties>();
  const setShown = (next: boolean) => {
    if (open === undefined) setInternal(next);
    onOpenChange?.(next);
  };
  useEffect(() => {
    if (!shown || !portal) return;
    const frame = requestAnimationFrame(() =>
      contentRef.current?.focus({ preventScroll: true }),
    );
    return () => cancelAnimationFrame(frame);
  }, [shown, portal]);
  useEffect(() => {
    if (!shown || !closeOnInteractOutside) return;
    const close = (event: PointerEvent) => {
      if (
        !root.current?.contains(event.target as Node) &&
        !contentRef.current?.contains(event.target as Node)
      )
        setShown(false);
    };
    document.addEventListener("pointerdown", close);
    return () => document.removeEventListener("pointerdown", close);
  }, [shown, closeOnInteractOutside]);
  useLayoutEffect(() => {
    if (!shown) return;
    const update = () => {
      const anchor = (
        anchorRef?.current ?? root.current
      )?.getBoundingClientRect();
      const content = contentRef.current;
      if (!anchor || !content) return;
      const gutter = 16;
      const gap = 8;
      const width = Math.min(
        content.offsetWidth,
        window.innerWidth - gutter * 2,
      );
      const height = Math.min(
        content.offsetHeight,
        window.innerHeight - gutter * 2,
      );
      const preferredLeft =
        align === "start"
          ? anchor.left
          : align === "end"
            ? anchor.right - width
            : anchor.left + (anchor.width - width) / 2;
      const left = Math.max(
        gutter,
        Math.min(window.innerWidth - width - gutter, preferredLeft),
      );
      const below = anchor.bottom + gap;
      const placeAbove =
        placement === "top" ||
        (!showArrow && below + height > window.innerHeight - gutter);
      const top = placeAbove
        ? Math.max(gutter, anchor.top - height - gap)
        : below;
      const host =
        portalContainer && portalContainer !== document.body
          ? portalContainer
          : null;
      const hostRect = host?.getBoundingClientRect();
      const vertical =
        placeAbove && !host
          ? {
              bottom: window.innerHeight - anchor.top + gap,
              maxHeight: anchor.top - gap - gutter,
            }
          : {
              top: top - (hostRect?.top ?? 0) + (host?.scrollTop ?? 0),
              maxHeight: window.innerHeight - top - gutter,
            };
      const next: CSSProperties & { "--k-popover-arrow-left": string } = {
        left: left - (hostRect?.left ?? 0) + (host?.scrollLeft ?? 0),
        ...vertical,
        ...(host ? { position: "absolute" } : {}),
        "--k-popover-arrow-left": `${Math.max(16, Math.min(width - 16, anchor.left + anchor.width / 2 - left))}px`,
      };
      setPosition((current) => {
        if (current && JSON.stringify(current) === JSON.stringify(next))
          return current;
        return next;
      });
    };
    update();
    // Follow anchors that resize during layout transitions (for example the
    // chat avatar shrinking when its usage popover opens).
    const resizeObserver = new ResizeObserver(update);
    const anchorElement = anchorRef?.current ?? root.current;
    if (anchorElement) resizeObserver.observe(anchorElement);
    if (contentRef.current) resizeObserver.observe(contentRef.current);
    window.addEventListener("resize", update);
    window.addEventListener("scroll", update, true);
    return () => {
      resizeObserver.disconnect();
      window.removeEventListener("resize", update);
      window.removeEventListener("scroll", update, true);
    };
  }, [align, shown, portalContainer, anchorRef, showArrow, placement]);
  const anchor = isValidElement(trigger)
    ? cloneElement(
        trigger as ReactElement<{
          onClick?: () => void;
          "aria-expanded"?: boolean;
        }>,
        { onClick: () => setShown(!shown), "aria-expanded": shown },
      )
    : trigger;
  const panel = shown ? (
    <div
      ref={contentRef}
      role="dialog"
      tabIndex={-1}
      data-k-escape-boundary=""
      aria-label={label}
      className="k-popover__content"
      data-align={align}
      data-arrow={showArrow || undefined}
      style={position}
      onKeyDown={(event) => {
        if (event.key === "Escape") {
          event.preventDefault();
          event.stopPropagation();
          setShown(false);
          root.current?.querySelector<HTMLElement>("button")?.focus();
        }
      }}
    >
      {showArrow ? (
        <div className="k-popover__scroll">{children}</div>
      ) : (
        children
      )}
    </div>
  ) : null;
  return (
    <span className="k-popover" ref={root}>
      {anchor}
      {portalContainer && panel ? createPortal(panel, portalContainer) : panel}
    </span>
  );
}

export interface KNavigationMenuItem {
  id: string;
  label: ReactNode;
  href?: string;
  content?: ReactNode;
  disabled?: boolean;
}
export function KNavigationMenu({
  items,
  label = "Main navigation",
  onNavigate,
}: {
  items: KNavigationMenuItem[];
  label?: string;
  onNavigate?: (item: KNavigationMenuItem) => void;
}) {
  const [open, setOpen] = useState<string | null>(null);
  const [dragging, setDragging] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);
  const dragRef = useRef({
    active: false,
    startX: 0,
    startScrollLeft: 0,
    suppressClick: false,
  });
  useEffect(() => {
    const move = (event: MouseEvent) => {
      const drag = dragRef.current;
      const element = scrollRef.current;
      if (!drag.active || !element) return;
      const delta = event.clientX - drag.startX;
      if (Math.abs(delta) > 4) {
        drag.suppressClick = true;
        setDragging(true);
      }
      if (!drag.suppressClick) return;
      event.preventDefault();
      element.scrollLeft = drag.startScrollLeft - delta;
    };
    const end = () => {
      dragRef.current.active = false;
      setDragging(false);
    };
    window.addEventListener("mousemove", move);
    window.addEventListener("mouseup", end);
    return () => {
      window.removeEventListener("mousemove", move);
      window.removeEventListener("mouseup", end);
    };
  }, []);
  return (
    <nav className="k-navigation-menu" aria-label={label}>
      <div
        ref={scrollRef}
        className={[
          "k-navigation-menu__scroll",
          dragging ? "is-dragging" : null,
        ]
          .filter(Boolean)
          .join(" ")}
        onMouseDown={(event) => {
          if (event.button !== 0) return;
          dragRef.current = {
            active: true,
            startX: event.clientX,
            startScrollLeft: event.currentTarget.scrollLeft,
            suppressClick: false,
          };
        }}
        onDragStart={(event) => event.preventDefault()}
        onWheel={(event) => {
          const element = event.currentTarget;
          const delta =
            Math.abs(event.deltaX) > Math.abs(event.deltaY)
              ? event.deltaX
              : event.deltaY;
          const maximum = element.scrollWidth - element.clientWidth;
          const next = Math.max(
            0,
            Math.min(maximum, element.scrollLeft + delta),
          );
          if (next === element.scrollLeft) return;
          event.preventDefault();
          element.scrollLeft = next;
        }}
        onClickCapture={(event) => {
          if (!dragRef.current.suppressClick) return;
          event.preventDefault();
          event.stopPropagation();
          dragRef.current.suppressClick = false;
        }}
      >
        {items.map((item) =>
          item.content ? (
            <KPopover
              key={item.id}
              open={open === item.id}
              onOpenChange={(next) => setOpen(next ? item.id : null)}
              align="start"
              trigger={
                <button
                  type="button"
                  disabled={item.disabled}
                  className="k-navigation-menu__trigger"
                >
                  {item.label}
                  <KIcon name="chevron-down" size={14} />
                </button>
              }
            >
              <div className="k-navigation-menu__panel">{item.content}</div>
            </KPopover>
          ) : (
            <a
              key={item.id}
              className="k-navigation-menu__link"
              href={item.href}
              aria-disabled={item.disabled}
              onClick={(event) => {
                if (item.disabled) event.preventDefault();
                else onNavigate?.(item);
              }}
            >
              {item.label}
            </a>
          ),
        )}
      </div>
    </nav>
  );
}

export interface KResponsiveDrawerProps extends KOverlayProps {
  /** Width below which detail content becomes a sheet. Use 0 for persistent side presentation (e.g. app navigation). */
  breakpoint?: number;
  side?: "left" | "right";
}
export function KResponsiveDrawer({
  breakpoint = 600,
  side = "right",
  className,
  ...props
}: KResponsiveDrawerProps) {
  const [compact, setCompact] = useState(
    () => typeof window !== "undefined" && window.innerWidth < breakpoint,
  );
  useEffect(() => {
    const query = matchMedia(`(max-width: ${breakpoint - 1}px)`);
    const update = () => setCompact(query.matches);
    update();
    query.addEventListener("change", update);
    return () => query.removeEventListener("change", update);
  }, [breakpoint]);
  return compact ? (
    <KBottomSheet {...props} className={className} />
  ) : (
    <KDesktopDialog
      {...props}
      className={[
        "k-responsive-drawer",
        `k-responsive-drawer--${side}`,
        className,
      ]
        .filter(Boolean)
        .join(" ")}
    />
  );
}

export interface KQuestionnaireStep {
  id: string;
  title: ReactNode;
  description?: ReactNode;
  content: ReactNode;
  optional?: boolean;
}
export interface KQuestionnaireProps {
  steps: KQuestionnaireStep[];
  step?: number;
  defaultStep?: number;
  onStepChange?: (step: number) => void;
  onComplete?: () => void;
  canContinue?: (step: number) => boolean;
  previousLabel?: string;
  nextLabel?: string;
  skipLabel?: string;
  completeLabel?: string;
  progressLabel?: (step: number, count: number) => string;
}
export function KQuestionnaire({
  steps,
  step,
  defaultStep = 0,
  onStepChange,
  onComplete,
  canContinue = () => true,
  previousLabel = "Previous",
  nextLabel = "Next",
  skipLabel = "Skip",
  completeLabel = "Complete",
  progressLabel = (current, count) => `Question ${current} of ${count}`,
}: KQuestionnaireProps) {
  const [internal, setInternal] = useState(defaultStep);
  const current = Math.max(0, Math.min(steps.length - 1, step ?? internal));
  const item = steps[current];
  if (!item) return null;
  const move = (next: number) => {
    if (step === undefined) setInternal(next);
    onStepChange?.(next);
  };
  return (
    <section className="k-questionnaire">
      <KProgress
        value={current + 1}
        max={steps.length}
        label={progressLabel(current + 1, steps.length)}
      />
      <header>
        <h3>{item.title}</h3>
        {item.description ? <p>{item.description}</p> : null}
      </header>
      <div className="k-questionnaire__content">{item.content}</div>
      <footer>
        <KButton
          variant="secondary"
          disabled={current === 0}
          onClick={() => move(current - 1)}
        >
          {previousLabel}
        </KButton>
        <span className="k-questionnaire__spacer" aria-hidden="true" />
        {item.optional && current < steps.length - 1 ? (
          <KButton variant="secondary" onClick={() => move(current + 1)}>
            {skipLabel}
          </KButton>
        ) : null}
        <KButton
          disabled={!canContinue(current)}
          onClick={() =>
            current === steps.length - 1 ? onComplete?.() : move(current + 1)
          }
        >
          {current === steps.length - 1 ? completeLabel : nextLabel}
        </KButton>
      </footer>
    </section>
  );
}

export { KToast, KToastViewport } from "./feedback/notifications.js";
export type { KToastProps } from "./feedback/notifications.js";
