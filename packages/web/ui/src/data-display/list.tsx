import {
  Children,
  isValidElement,
  type HTMLAttributes,
  type MouseEvent,
  type ReactNode,
  useLayoutEffect,
  useRef,
  useState,
} from "react";
import { KIcon, type KIconName } from "../primitives/icon.js";
import { KButton } from "../primitives/button.js";
import { KIconButton } from "../actions/icon-button.js";
import { KMenuButton, type KMenuAction } from "../actions/menu-button.js";
import { KSwipeRow, type KSwipeAction } from "./swipe-row.js";
import { KSwitch } from "../extended-components.js";
import { KText } from "../primitives/text.js";

export interface KListProps extends Omit<HTMLAttributes<HTMLElement>, "title"> {
  children: ReactNode;
  /** Section title above the group. */
  title?: ReactNode;
  /** Note below the group. */
  footer?: ReactNode;
  /** Hairline between rows (default true). */
  separated?: boolean;
}

/**
 * One group of `KListItem`s on its own surface, with an optional section
 * title and footer (inset grouped list). The list draws its surface: place it
 * on the page, never inside a card. Stack lists with `KStack gap="section"`.
 */
export function KList({
  children,
  title,
  footer,
  separated = true,
  className,
  ...props
}: KListProps) {
  return (
    <section
      className={["k-list", className].filter(Boolean).join(" ")}
      {...props}
    >
      {title ? (
        <KText as="h3" variant="label" className="k-list__title">
          {title}
        </KText>
      ) : null}
      <ul className="k-list__group" data-separated={separated || undefined}>
        {Children.toArray(children).map((child, index) => (
          <li key={index} className="k-list__row">
            {child}
          </li>
        ))}
      </ul>
      {footer ? (
        <KText as="p" variant="caption" className="k-list__footer">
          {footer}
        </KText>
      ) : null}
    </section>
  );
}

export interface KListItemProps extends Omit<
  HTMLAttributes<HTMLElement>,
  "title" | "onClick"
> {
  title: ReactNode;
  description?: ReactNode;
  /** A custom leading visual; it sits on the first title line. */
  leading?: ReactNode;
  /** Shortcut for a leading icon in the default icon size. */
  leadingIcon?: KIconName;
  /**
   * An icon on a tonal media tile (a building, a folder). The row then
   * centres leading, value and chevron on the copy block.
   */
  mediaIcon?: KIconName;
  /**
   * A choice row: the whole row opens these options as a menu, with `value`
   * showing the current one (iOS pull-down, Android menu).
   */
  menu?: readonly KMenuAction[];
  /**
   * Swipe actions (Decision 0016): swipe right for `leadingActions`, left for
   * `trailingActions`. The style decides the look; pointer and keyboard users
   * get the same actions inline at the row end.
   */
  leadingActions?: readonly KSwipeAction[];
  trailingActions?: readonly KSwipeAction[];
  /** A boolean row: a switch at the end, and the whole row toggles it. */
  switchValue?: boolean;
  onSwitchChange?: (value: boolean) => void;
  /** Non-text trailing content (badge, dot), centred on the title line. */
  trailing?: ReactNode;
  /** Trailing value text ("12.4 GB") in the style's value role. */
  value?: ReactNode;
  onClick?: (event: MouseEvent<HTMLElement>) => void;
  /** Renders the row as a link. */
  href?: string;
  /** Shows the chevron; defaults to true for links and buttons. */
  disclosure?: boolean;
  selected?: boolean;
  disabled?: boolean;
  /** Truncates the title with "…" after this many lines. */
  titleMaxLines?: number;
}

/**
 * One list row (Decision 0012): leading icon on the first title line,
 * wrapping title and description, trailing value beside the copy when both
 * fit on one line and under it otherwise (iOS value cell), chevron when the
 * row navigates. Words are never broken (Decision 0015).
 */
export function KListItem({
  title,
  description,
  leading,
  leadingIcon,
  mediaIcon,
  menu,
  switchValue,
  onSwitchChange,
  trailing: trailingProp,
  value,
  onClick: onClickProp,
  href,
  disclosure,
  selected = false,
  disabled = false,
  titleMaxLines,
  leadingActions,
  trailingActions,
  className,
  style,
  ...props
}: KListItemProps) {
  const row = KListItemRow({
    title,
    description,
    leading,
    leadingIcon,
    mediaIcon,
    menu,
    switchValue,
    onSwitchChange,
    trailing: trailingProp,
    value,
    onClick: onClickProp,
    href,
    disclosure,
    selected,
    disabled,
    titleMaxLines,
    className,
    style,
    ...props,
  });
  return leadingActions?.length || trailingActions?.length ? (
    <KSwipeRow
      leadingActions={leadingActions}
      trailingActions={trailingActions}
      disabled={disabled}
    >
      {row}
    </KSwipeRow>
  ) : (
    row
  );
}

function KListItemRow({
  title,
  description,
  leading,
  leadingIcon,
  mediaIcon,
  menu,
  switchValue,
  onSwitchChange,
  trailing: trailingProp,
  value,
  onClick: onClickProp,
  href,
  disclosure,
  selected = false,
  disabled = false,
  titleMaxLines,
  className,
  style,
  ...props
}: Omit<KListItemProps, "leadingActions" | "trailingActions">) {
  const toggle = switchValue !== undefined;
  const onClick =
    onClickProp ??
    (toggle && onSwitchChange ? () => onSwitchChange(!switchValue) : undefined);
  const trailing =
    trailingProp ??
    (toggle ? (
      <span aria-hidden className="k-list-item__switch">
        <KSwitch
          checked={switchValue}
          label={typeof title === "string" ? title : ""}
          showLabel={false}
          disabled={disabled}
          tabIndex={-1}
          onCheckedChange={onSwitchChange ?? (() => {})}
        />
      </span>
    ) : menu ? (
      <span className="k-list-item__menu-chevron" aria-hidden>
        <KIcon name="chevrons-up-down" size={16} />
      </span>
    ) : null);
  if (
    !onClick &&
    !href &&
    !menu &&
    isValidElement(trailingProp) &&
    [KIconButton, KMenuButton, KButton, KSwitch].some(
      (component) =>
        trailingProp.type === component ||
        (trailingProp.type as { displayName?: string }).displayName ===
          (component as { displayName?: string }).displayName,
    )
  )
    console.warn(
      `KListItem "${String(title)}": a control in \`trailing\` makes only that control tappable. Use \`menu\` for a choice, \`switchValue\` for on/off or \`onClick\` so the whole row responds (Decision 0015).`,
    );
  const interactive = Boolean(onClick || href || menu);
  const showChevron = disclosure ?? (Boolean(onClickProp || href) && !toggle);
  const textRef = useRef<HTMLSpanElement>(null);
  const stacked = useStackedValue(textRef, value != null && value !== false, [
    title,
    description,
    value,
  ]);
  const visual =
    leading ??
    (mediaIcon ? (
      <span className="k-list-item__media">
        <KIcon name={mediaIcon} size={24} />
      </span>
    ) : null) ??
    (leadingIcon ? (
      <KIcon name={leadingIcon} size={24} className="k-list-item__icon" />
    ) : null);
  const content = (
    <span className="k-list-item__row">
      {visual ? <span className="k-list-item__leading">{visual}</span> : null}
      <span className="k-list-item__body">
        <span
          ref={textRef}
          className="k-list-item__text"
          data-stacked={stacked || undefined}
        >
          <span className="k-list-item__copy">
            <KText
              as="span"
              variant="label"
              className="k-list-item__title"
              style={
                titleMaxLines
                  ? ({ "--k-list-title-lines": titleMaxLines } as never)
                  : undefined
              }
              data-clamped={titleMaxLines ? true : undefined}
            >
              {title}
            </KText>
            {description ? (
              <KText
                as="span"
                variant="bodySmall"
                className="k-list-item__description"
              >
                {description}
              </KText>
            ) : null}
          </span>
          {value ? <span className="k-list-item__value">{value}</span> : null}
        </span>
        {trailing ? (
          <span className="k-list-item__trailing">{trailing}</span>
        ) : null}
      </span>
      {showChevron ? (
        <span className="k-list-item__chevron" aria-hidden>
          <KIcon name="chevron-right" size={16} />
        </span>
      ) : null}
    </span>
  );
  const common = {
    ...props,
    className: ["k-list-item", className].filter(Boolean).join(" "),
    style,
    "data-interactive": interactive || undefined,
    "data-selected": selected || undefined,
    "data-media": mediaIcon ? true : undefined,
    "data-disabled": disabled || undefined,
    // An explicit chevron survives styles that hide it by default.
    "data-disclosure": disclosure ? true : undefined,
  };
  if (menu)
    // The row draws itself; an invisible menu trigger covers it, so the
    // whole row opens the menu and the menu anchors to the row.
    return (
      <div {...common} data-interactive>
        <span aria-hidden className="k-list-item__menu-content">
          {content}
        </span>
        <span className="k-list-item__menu-trigger">
          <KMenuButton
            label={
              typeof value === "string"
                ? `${String(title)}, ${value}`
                : String(title)
            }
            actions={menu}
            disabled={disabled}
            fullWidth
            triggerVariant="ghost"
          />
        </span>
      </div>
    );
  if (href)
    return (
      <a
        {...common}
        href={disabled ? undefined : href}
        aria-disabled={disabled || undefined}
        aria-current={selected ? "page" : undefined}
        onClick={(event) => {
          if (disabled) {
            event.preventDefault();
            return;
          }
          onClick?.(event);
        }}
      >
        {content}
      </a>
    );
  if (onClick)
    return (
      <button
        {...common}
        type="button"
        disabled={disabled}
        aria-pressed={selected || undefined}
        role={toggle ? "switch" : undefined}
        aria-checked={toggle ? switchValue : undefined}
        onClick={onClick}
      >
        {content}
      </button>
    );
  return <div {...common}>{content}</div>;
}

/**
 * Side by side when copy and value both fit on one line, stacked otherwise.
 * Mirrors `KTitleValueLayout` in Flutter: natural widths plus the gap against
 * the available width.
 */
function useStackedValue(
  ref: { current: HTMLSpanElement | null },
  hasValue: boolean,
  deps: readonly unknown[],
) {
  const [stacked, setStacked] = useState(false);
  useLayoutEffect(() => {
    const element = ref.current;
    if (!element || !hasValue) return;
    let lastWidth = -1;
    const measure = (force = false) => {
      const width = element.clientWidth;
      if (!force && width === lastWidth) return;
      lastWidth = width;
      const copy = element.firstElementChild as HTMLElement | null;
      const value = element.lastElementChild as HTMLElement | null;
      if (!copy || !value || copy === value) return;
      element.setAttribute("data-measuring", "");
      // The token, not the value's margin: a stacked value has no margin,
      // and reading it would flip the decision at the threshold.
      const gap =
        parseFloat(
          getComputedStyle(element).getPropertyValue("--k-space-control-gap"),
        ) || 0;
      const needed =
        copy.getBoundingClientRect().width +
        gap +
        value.getBoundingClientRect().width;
      element.removeAttribute("data-measuring");
      setStacked(needed > width + 0.5);
    };
    measure(true);
    const observer = new ResizeObserver(() => measure());
    observer.observe(element);
    let alive = true;
    void document.fonts?.ready.then(() => alive && measure(true));
    return () => {
      alive = false;
      observer.disconnect();
    };
  }, [ref, hasValue, ...deps]);
  return stacked;
}
