import {
  Children,
  type HTMLAttributes,
  type ReactNode,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
} from "react";

import { KIcon, type KIconName } from "./primitives/icon.js";
import { KButton } from "./primitives/button.js";
import { KMenuButton } from "./actions/menu-button.js";
import { KIconButton } from "./actions/icon-button.js";
import { KDialog } from "./overlays/overlay.js";
import { useKLocalization } from "./localization/provider.js";

export type KStatusTone = "neutral" | "info" | "success" | "warning" | "error";

export interface KAlertProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  "title"
> {
  title: ReactNode;
  description?: ReactNode;
  icon?: KIconName;
  action?: ReactNode;
  tone?: KStatusTone;
}

export function KAlert({
  title,
  description,
  icon,
  action,
  tone = "neutral",
  role = tone === "error" ? "alert" : undefined,
  className,
  ...props
}: KAlertProps) {
  return (
    <div
      {...props}
      role={role}
      className={["k-alert", className].filter(Boolean).join(" ")}
      data-tone={tone}
    >
      {icon ? <KIcon name={icon} color="currentColor" /> : null}
      <div className="k-alert__content">
        <strong className="k-alert__title">{title}</strong>
        {description ? (
          <div className="k-alert__description">{description}</div>
        ) : null}
      </div>
      {action ? <div className="k-alert__action">{action}</div> : null}
    </div>
  );
}

export interface KAlertDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: ReactNode;
  description: ReactNode;
  media?: ReactNode;
  cancelLabel?: ReactNode;
  actionLabel?: ReactNode;
  onAction: () => void;
  destructive?: boolean;
  actionDisabled?: boolean;
}

export function KAlertDialog({
  open,
  onOpenChange,
  title,
  description,
  media,
  cancelLabel,
  actionLabel,
  onAction,
  destructive = false,
  actionDisabled = false,
}: KAlertDialogProps) {
  const { messages } = useKLocalization();
  return (
    <KDialog
      open={open}
      onOpenChange={onOpenChange}
      title={title}
      description={description}
      dismissible={false}
      className="k-alert-dialog"
      actions={
        <div className="k-alert-dialog__actions">
          <KButton variant="secondary" onClick={() => onOpenChange(false)}>
            {cancelLabel ?? messages.cancel}
          </KButton>
          <KButton
            className={destructive ? "k-button--destructive" : undefined}
            disabled={actionDisabled}
            onClick={() => {
              onAction();
              onOpenChange(false);
            }}
          >
            {actionLabel ?? messages.apply}
          </KButton>
        </div>
      }
    >
      {media ? <div className="k-alert-dialog__media">{media}</div> : null}
    </KDialog>
  );
}

export type KAttachmentState =
  "ready" | "uploading" | "processing" | "error" | "complete";
export type KAttachmentSize = "standard" | "small" | "compact";

export interface KAttachmentProps extends Omit<
  HTMLAttributes<HTMLElement>,
  "title"
> {
  title: ReactNode;
  activateLabel?: string;
  description?: ReactNode;
  media?: ReactNode;
  actions?: ReactNode;
  state?: KAttachmentState;
  progress?: number;
  size?: KAttachmentSize;
  showLoadingIndicator?: boolean;
  loadingIndicator?: ReactNode;
  loadingLabel?: string;
  onActivate?: () => void;
}

export function KAttachment({
  title,
  activateLabel = "Open attachment",
  description,
  media,
  actions,
  state = "ready",
  progress,
  size = "standard",
  showLoadingIndicator = false,
  loadingIndicator,
  loadingLabel = "Uploading attachment",
  onActivate,
  className,
  ...props
}: KAttachmentProps) {
  const loading =
    showLoadingIndicator && (state === "uploading" || state === "processing");
  return (
    <article
      {...props}
      className={["k-attachment", className].filter(Boolean).join(" ")}
      data-state={state}
      data-size={size}
    >
      {onActivate ? (
        <button
          className="k-attachment__trigger"
          onClick={onActivate}
          aria-label={activateLabel}
        />
      ) : null}
      <div className="k-attachment__media">
        {loading ? (
          <span
            className="k-attachment__loading"
            role="status"
            aria-label={loadingLabel}
          >
            {loadingIndicator ?? (
              <span className="k-attachment__spinner" aria-hidden="true" />
            )}
          </span>
        ) : (
          (media ?? <KIcon name="file" />)
        )}
      </div>
      <div className="k-attachment__content">
        <strong className="k-attachment__title">{title}</strong>
        {description ? (
          <span className="k-attachment__description">{description}</span>
        ) : null}
        {progress !== undefined ? (
          <progress
            className="k-attachment__progress"
            max={1}
            value={Math.max(0, Math.min(1, progress))}
          />
        ) : null}
      </div>
      {actions ? <div className="k-attachment__actions">{actions}</div> : null}
    </article>
  );
}

export type KAvatarSize = "small" | "standard" | "large";

export interface KAvatarProps extends HTMLAttributes<HTMLSpanElement> {
  src?: string;
  alt: string;
  fallback?: ReactNode;
  badge?: ReactNode;
  size?: KAvatarSize;
}

export function KAvatar({
  src,
  alt,
  fallback,
  badge,
  size = "standard",
  className,
  ...props
}: KAvatarProps) {
  const [failed, setFailed] = useState(false);
  useEffect(() => setFailed(false), [src]);
  const fallbackContent = fallback ?? avatarInitials(alt);
  return (
    <span
      {...props}
      className={["k-avatar", className].filter(Boolean).join(" ")}
      data-size={size}
    >
      {src && !failed ? (
        <img src={src} alt={alt} onError={() => setFailed(true)} />
      ) : (
        <span className="k-avatar__fallback" aria-label={alt}>
          {fallbackContent}
        </span>
      )}
      {badge !== undefined && badge !== null ? (
        <span className="k-avatar__badge">{badge}</span>
      ) : null}
    </span>
  );
}

function avatarInitials(label: string) {
  return label
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map((part) => part[0]?.toLocaleUpperCase())
    .join("");
}

export function KAvatarGroup({
  children,
  className,
  ...props
}: HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      {...props}
      className={["k-avatar-group", className].filter(Boolean).join(" ")}
    >
      {children}
    </div>
  );
}

export type KBadgeVariant =
  | "primary"
  | "secondary"
  | "outline"
  | "ghost"
  | "info"
  | "success"
  | "warning"
  | "destructive";
export interface KBadgeProps extends HTMLAttributes<HTMLSpanElement> {
  variant?: KBadgeVariant;
  leading?: ReactNode;
  trailing?: ReactNode;
}

export function KBadge({
  children,
  variant = "primary",
  leading,
  trailing,
  className,
  ...props
}: KBadgeProps) {
  return (
    <span
      {...props}
      className={["k-badge", className].filter(Boolean).join(" ")}
      data-variant={variant}
    >
      {leading}
      <span>{children}</span>
      {trailing}
    </span>
  );
}

export interface KBreadcrumbItem {
  id: string;
  label: ReactNode;
  icon?: KIconName;
  href?: string;
  onSelect?: () => void;
}
export interface KBreadcrumbProps {
  items: readonly KBreadcrumbItem[];
  label?: string;
  separator?: ReactNode;
  overflowLabel?: string;
  /** @deprecated Icon strokes come from the style (`--k-size-icon-stroke`). */
  iconStrokeWidth?: number;
}

export function KBreadcrumb({
  items,
  label = "Breadcrumb",
  separator,
  overflowLabel,
  iconStrokeWidth,
}: KBreadcrumbProps) {
  const container = useRef<HTMLElement>(null);
  const probe = useRef<HTMLOListElement>(null);
  const [keep, setKeep] = useState(items.length);
  // Measure instead of breakpoints (Decision 0015): as many trailing levels
  // as fit stay visible, the rest go into the menu; only the last label is
  // ever shortened with "…". Mirrors KBreadcrumb in Flutter.
  useLayoutEffect(() => {
    const nav = container.current;
    const list = probe.current;
    if (!nav || !list) return;
    const compute = () => {
      const available = nav.clientWidth;
      const [menu, ...rows] = Array.from(list.children).map(
        (child) => child.getBoundingClientRect().width,
      );
      const gap = parseFloat(getComputedStyle(list).columnGap) || 0;
      const trailing = (count: number) =>
        rows.slice(rows.length - count).reduce((sum, w) => sum + w, 0) +
        gap * (count - 1);
      if (trailing(rows.length) <= available + 0.5) {
        setKeep(rows.length);
        return;
      }
      let count = 1;
      while (
        count < rows.length - 1 &&
        menu + gap + trailing(count + 1) <= available + 0.5
      )
        count++;
      setKeep(count);
    };
    compute();
    if (typeof ResizeObserver === "undefined") return;
    const observer = new ResizeObserver(compute);
    observer.observe(nav);
    let alive = true;
    void document.fonts?.ready.then(() => alive && compute());
    return () => {
      alive = false;
      observer.disconnect();
    };
  }, [items]);
  const hidden = items.slice(0, Math.max(0, items.length - keep));
  const visible = items.slice(hidden.length);
  const divider = (
    <span className="k-breadcrumb__separator" aria-hidden="true">
      {separator ?? (
        <KIcon name="chevron-right" strokeWidth={iconStrokeWidth} />
      )}
    </span>
  );
  const renderContent = (item: KBreadcrumbItem) => (
    <span className="k-breadcrumb__content">
      {item.icon ? (
        <KIcon name={item.icon} size={16} strokeWidth={iconStrokeWidth} />
      ) : null}
      <span
        className="k-breadcrumb__label"
        title={typeof item.label === "string" ? item.label : undefined}
      >
        {item.label}
      </span>
    </span>
  );
  return (
    <nav ref={container} className="k-breadcrumb" aria-label={label}>
      {/* Invisible natural-width copy used to measure what fits. */}
      <ol ref={probe} className="k-breadcrumb__probe" aria-hidden inert>
        <li className="k-breadcrumb__overflow">
          <KMenuButton label={overflowLabel ?? label} overflow actions={[]} />
          {divider}
        </li>
        {items.map((item, index) => (
          <li key={item.id}>
            {renderContent(item)}
            {index < items.length - 1 ? divider : null}
          </li>
        ))}
      </ol>
      <ol>
        {hidden.length > 0 && (
          <li className="k-breadcrumb__overflow">
            <KMenuButton
              key={hidden.map((item) => item.id).join(":")}
              label={overflowLabel ?? label}
              overflow
              actions={hidden.map((item) => ({
                id: item.id,
                label: item.label,
                icon: item.icon,
                href: item.href,
                onSelect: item.onSelect,
                disabled: !item.href && !item.onSelect,
              }))}
            />
            {divider}
          </li>
        )}
        {visible.map((item, index) => {
          const current = index === visible.length - 1;
          const content = renderContent(item);
          return (
            <li key={item.id} data-current={current || undefined}>
              {current ? (
                <span aria-current="page">{content}</span>
              ) : (
                <a
                  href={item.href ?? "#"}
                  onClick={(event) => {
                    if (!item.href) event.preventDefault();
                    if (
                      !item.href ||
                      (!event.metaKey &&
                        !event.ctrlKey &&
                        !event.shiftKey &&
                        !event.altKey &&
                        event.button === 0)
                    )
                      item.onSelect?.();
                  }}
                >
                  {content}
                </a>
              )}
              {!current ? divider : null}
            </li>
          );
        })}
      </ol>
    </nav>
  );
}

export interface KCarouselProps {
  children: ReactNode;
  label: string;
  previousLabel?: string;
  nextLabel?: string;
  previousIcon?: KIconName;
  nextIcon?: KIconName;
  initialIndex?: number;
  onIndexChange?: (index: number) => void;
  className?: string;
}

export function KCarousel({
  children,
  label,
  previousLabel = "Previous slide",
  nextLabel = "Next slide",
  previousIcon = "chevron-left",
  nextIcon = "chevron-right",
  initialIndex = 0,
  onIndexChange,
  className,
}: KCarouselProps) {
  const slides = Children.toArray(children);
  const [index, setIndex] = useState(
    Math.max(0, Math.min(initialIndex, slides.length - 1)),
  );
  const viewport = useRef<HTMLDivElement>(null);
  const pointerDrag = useRef<{
    pointerId: number;
    startX: number;
    scrollLeft: number;
  } | null>(null);
  useEffect(() => {
    if (index < slides.length || slides.length === 0) return;
    const next = Math.max(0, slides.length - 1);
    setIndex(next);
    viewport.current?.scrollTo({
      left: next * viewport.current.clientWidth,
      behavior: "auto",
    });
  }, [index, slides.length]);
  function select(next: number, behavior: ScrollBehavior = "smooth") {
    const safe = Math.max(0, Math.min(next, slides.length - 1));
    setIndex(safe);
    viewport.current?.scrollTo({
      left: safe * viewport.current.clientWidth,
      behavior,
    });
    onIndexChange?.(safe);
  }
  return (
    <section
      className={["k-carousel", className].filter(Boolean).join(" ")}
      aria-roledescription="carousel"
      aria-label={label}
      onKeyDown={(event) => {
        if (event.key === "ArrowLeft") select(index - 1);
        if (event.key === "ArrowRight") select(index + 1);
      }}
    >
      <div
        ref={viewport}
        className="k-carousel__viewport"
        tabIndex={0}
        onScroll={(event) => {
          const width = event.currentTarget.clientWidth;
          if (!width) return;
          const next = Math.round(event.currentTarget.scrollLeft / width);
          if (next !== index) {
            setIndex(next);
            onIndexChange?.(next);
          }
        }}
        onPointerDown={(event) => {
          if (event.pointerType !== "mouse" || event.button !== 0) return;
          if (
            (event.target as HTMLElement).closest(
              "a,button,input,select,textarea",
            )
          )
            return;
          pointerDrag.current = {
            pointerId: event.pointerId,
            startX: event.clientX,
            scrollLeft: event.currentTarget.scrollLeft,
          };
          event.currentTarget.setPointerCapture(event.pointerId);
          event.currentTarget.dataset.dragging = "true";
        }}
        onPointerMove={(event) => {
          const drag = pointerDrag.current;
          if (!drag || drag.pointerId !== event.pointerId) return;
          event.currentTarget.scrollLeft =
            drag.scrollLeft - (event.clientX - drag.startX);
        }}
        onPointerUp={(event) => {
          if (pointerDrag.current?.pointerId !== event.pointerId) return;
          pointerDrag.current = null;
          delete event.currentTarget.dataset.dragging;
          event.currentTarget.releasePointerCapture(event.pointerId);
          const width = event.currentTarget.clientWidth;
          if (width) {
            select(Math.round(event.currentTarget.scrollLeft / width));
          }
        }}
        onPointerCancel={(event) => {
          pointerDrag.current = null;
          delete event.currentTarget.dataset.dragging;
        }}
      >
        {slides.map((slide, slideIndex) => (
          <div
            className="k-carousel__slide"
            role="group"
            aria-roledescription="slide"
            aria-label={`${slideIndex + 1} of ${slides.length}`}
            key={slideIndex}
          >
            {slide}
          </div>
        ))}
      </div>
      <KIconButton
        className="k-carousel__control k-carousel__control--previous"
        icon={previousIcon}
        label={previousLabel}
        variant="secondary"
        disabled={index === 0}
        onClick={() => select(index - 1)}
      />
      <KIconButton
        className="k-carousel__control k-carousel__control--next"
        icon={nextIcon}
        label={nextLabel}
        variant="secondary"
        disabled={index === slides.length - 1}
        onClick={() => select(index + 1)}
      />
      <div className="k-carousel__dots" aria-hidden="true">
        {slides.map((_, dot) => (
          <span key={dot} data-active={dot === index || undefined} />
        ))}
      </div>
    </section>
  );
}
