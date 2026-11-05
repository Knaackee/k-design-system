import {
  Children,
  type HTMLAttributes,
  type MouseEvent,
  type ReactNode,
} from "react";
import { KIcon, type KIconName } from "../primitives/icon.js";
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
 * wrapping title and description, trailing value (at most half the row)
 * that moves under the copy from 1.3× text, chevron when the row navigates.
 */
export function KListItem({
  title,
  description,
  leading,
  leadingIcon,
  trailing,
  value,
  onClick,
  href,
  disclosure,
  selected = false,
  disabled = false,
  titleMaxLines,
  className,
  style,
  ...props
}: KListItemProps) {
  const interactive = Boolean(onClick || href);
  const showChevron = disclosure ?? interactive;
  const visual =
    leading ??
    (leadingIcon ? (
      <KIcon name={leadingIcon} size={24} className="k-list-item__icon" />
    ) : null);
  const content = (
    <span className="k-list-item__row">
      {visual ? <span className="k-list-item__leading">{visual}</span> : null}
      <span className="k-list-item__body">
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
    "data-disabled": disabled || undefined,
  };
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
        onClick={onClick}
      >
        {content}
      </button>
    );
  return <div {...common}>{content}</div>;
}
