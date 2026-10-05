import {
  createContext,
  useContext,
  useState,
  type CSSProperties,
  type HTMLAttributes,
  type MouseEvent,
  type ReactNode,
} from "react";
import { KIcon } from "../primitives/icon.js";

export type KSidebarMode = "expanded" | "rail" | "hidden";

interface KSidebarContextValue {
  mode: KSidebarMode;
  setMode?: (mode: KSidebarMode) => void;
}

const KSidebarContext = createContext<KSidebarContextValue>({
  mode: "expanded",
});

export interface KSidebarProps extends HTMLAttributes<HTMLElement> {
  mode?: KSidebarMode;
  defaultMode?: KSidebarMode;
  onModeChange?: (mode: KSidebarMode) => void;
  label?: string;
  children: ReactNode;
}

export function KSidebar({
  mode,
  defaultMode = "expanded",
  onModeChange,
  label = "Sidebar",
  className,
  children,
  ...props
}: KSidebarProps) {
  const [internalMode, setInternalMode] = useState(defaultMode);
  const currentMode = mode ?? internalMode;
  const setMode = (nextMode: KSidebarMode) => {
    if (mode === undefined) setInternalMode(nextMode);
    onModeChange?.(nextMode);
  };
  return (
    <KSidebarContext.Provider value={{ mode: currentMode, setMode }}>
      <aside
        aria-label={label}
        aria-hidden={currentMode === "hidden" || undefined}
        className={["k-sidebar", className].filter(Boolean).join(" ")}
        data-mode={currentMode}
        {...props}
      >
        {children}
      </aside>
    </KSidebarContext.Provider>
  );
}

function SidebarRegion({
  region,
  className,
  ...props
}: HTMLAttributes<HTMLDivElement> & {
  region: "header" | "body" | "footer";
}) {
  return (
    <div
      className={[`k-sidebar__${region}`, className].filter(Boolean).join(" ")}
      {...props}
    />
  );
}

export function KSidebarHeader(props: HTMLAttributes<HTMLDivElement>) {
  return <SidebarRegion region="header" {...props} />;
}

export function KSidebarBody(props: HTMLAttributes<HTMLDivElement>) {
  return <SidebarRegion region="body" {...props} />;
}

export function KSidebarFooter(props: HTMLAttributes<HTMLDivElement>) {
  return <SidebarRegion region="footer" {...props} />;
}

export function KSidebarExpandedContent({
  className,
  ...props
}: HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={["k-sidebar__expanded-only", className]
        .filter(Boolean)
        .join(" ")}
      {...props}
    />
  );
}

export function KSidebarRailContent({
  className,
  ...props
}: HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={["k-sidebar__rail-only", className].filter(Boolean).join(" ")}
      {...props}
    />
  );
}

export interface KSidebarGroupProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  "title"
> {
  label?: ReactNode;
  badge?: ReactNode;
  action?: ReactNode;
  collapsible?: boolean;
  expanded?: boolean;
  defaultExpanded?: boolean;
  onExpandedChange?: (expanded: boolean) => void;
  children: ReactNode;
}

export function KSidebarGroup({
  label,
  badge,
  action,
  collapsible = false,
  expanded,
  defaultExpanded = true,
  onExpandedChange,
  className,
  children,
  ...props
}: KSidebarGroupProps) {
  const [internalExpanded, setInternalExpanded] = useState(defaultExpanded);
  const isExpanded = expanded ?? internalExpanded;
  const changeExpanded = () => {
    const next = !isExpanded;
    if (expanded === undefined) setInternalExpanded(next);
    onExpandedChange?.(next);
  };
  return (
    <section
      className={["k-sidebar-group", className].filter(Boolean).join(" ")}
      data-expanded={isExpanded || undefined}
      {...props}
    >
      {label || badge || action ? (
        <div className="k-sidebar-group__heading">
          {collapsible ? (
            <button
              type="button"
              className="k-sidebar-group__toggle"
              aria-expanded={isExpanded}
              onClick={changeExpanded}
            >
              <KIcon
                name={isExpanded ? "chevron-down" : "chevron-right"}
                size={12}
              />
              <span className="k-sidebar-group__label">{label}</span>
            </button>
          ) : (
            <span className="k-sidebar-group__label">{label}</span>
          )}
          {badge ? (
            <span className="k-sidebar-group__badge">{badge}</span>
          ) : null}
          {action ? (
            <span className="k-sidebar-group__action">{action}</span>
          ) : null}
        </div>
      ) : null}
      <div className="k-sidebar-group__items" hidden={!isExpanded}>
        {children}
      </div>
    </section>
  );
}

export interface KSidebarItemProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  "onSelect"
> {
  label: ReactNode;
  textLabel?: string;
  leading?: ReactNode;
  badge?: ReactNode;
  trailing?: ReactNode;
  action?: ReactNode;
  href?: string;
  active?: boolean;
  disabled?: boolean;
  depth?: number;
  expanded?: boolean;
  onSelect?: () => void;
}

export function KSidebarItem({
  label,
  textLabel,
  leading,
  badge,
  trailing,
  action,
  href,
  active = false,
  disabled = false,
  depth = 0,
  expanded,
  onSelect,
  className,
  style,
  ...props
}: KSidebarItemProps) {
  const { mode } = useContext(KSidebarContext);
  const accessibleLabel =
    textLabel ?? (typeof label === "string" ? label : undefined);
  const content = (
    <>
      {leading ? (
        <span className="k-sidebar-item__leading">{leading}</span>
      ) : null}
      <span className="k-sidebar-item__label">{label}</span>
      {badge ? <span className="k-sidebar-item__badge">{badge}</span> : null}
      {trailing ? (
        <span className="k-sidebar-item__trailing">{trailing}</span>
      ) : null}
    </>
  );
  const common = {
    className: "k-sidebar-item__control",
    "aria-current": active ? ("page" as const) : undefined,
    "aria-expanded": expanded,
    "aria-label": textLabel
      ? accessibleLabel
      : mode === "rail"
        ? accessibleLabel
        : undefined,
    title: mode === "rail" ? accessibleLabel : undefined,
    onClick: (event: MouseEvent<HTMLElement>) => {
      if (disabled) {
        event.preventDefault();
        return;
      }
      onSelect?.();
    },
  };
  return (
    <div
      className={["k-sidebar-item", className].filter(Boolean).join(" ")}
      data-active={active || undefined}
      data-disabled={disabled || undefined}
      style={{ "--k-sidebar-depth": depth, ...style } as CSSProperties}
      {...props}
    >
      {href && !disabled ? (
        <a href={href} {...common}>
          {content}
        </a>
      ) : (
        <button type="button" disabled={disabled} {...common}>
          {content}
        </button>
      )}
      {action ? <span className="k-sidebar-item__action">{action}</span> : null}
    </div>
  );
}

export interface KSidebarSubgroupProps extends Omit<
  HTMLAttributes<HTMLElement>,
  "onSelect"
> {
  label: ReactNode;
  textLabel?: string;
  leading?: ReactNode;
  badge?: ReactNode;
  action?: ReactNode;
  depth?: number;
  expanded?: boolean;
  defaultExpanded?: boolean;
  onExpandedChange?: (expanded: boolean) => void;
  children: ReactNode;
}

export function KSidebarSubgroup({
  label,
  textLabel,
  leading,
  badge,
  action,
  depth = 0,
  expanded,
  defaultExpanded = true,
  onExpandedChange,
  className,
  children,
  ...props
}: KSidebarSubgroupProps) {
  const [internalExpanded, setInternalExpanded] = useState(defaultExpanded);
  const isExpanded = expanded ?? internalExpanded;
  const toggle = () => {
    const next = !isExpanded;
    if (expanded === undefined) setInternalExpanded(next);
    onExpandedChange?.(next);
  };
  return (
    <section
      className={["k-sidebar-subgroup", className].filter(Boolean).join(" ")}
      data-expanded={isExpanded || undefined}
      {...props}
    >
      <KSidebarItem
        label={label}
        textLabel={textLabel}
        leading={leading}
        badge={badge}
        action={action}
        depth={depth}
        expanded={isExpanded}
        onSelect={toggle}
      />
      <div className="k-sidebar-subgroup__items" hidden={!isExpanded}>
        {children}
      </div>
    </section>
  );
}

export function KSidebarSeparator({
  className,
  ...props
}: HTMLAttributes<HTMLHRElement>) {
  return (
    <hr
      className={["k-sidebar-separator", className].filter(Boolean).join(" ")}
      {...props}
    />
  );
}

export interface KSidebarToggleProps extends Omit<
  HTMLAttributes<HTMLButtonElement>,
  "children"
> {
  expandedLabel?: string;
  railLabel?: string;
  expandedContent?: ReactNode;
  railContent?: ReactNode;
}

export function KSidebarToggle({
  expandedLabel = "Collapse sidebar",
  railLabel = "Expand sidebar",
  expandedContent,
  railContent,
  className,
  ...props
}: KSidebarToggleProps) {
  const { mode, setMode } = useContext(KSidebarContext);
  if (mode === "hidden") return null;
  const expanded = mode === "expanded";
  return (
    <button
      type="button"
      className={["k-sidebar-toggle", className].filter(Boolean).join(" ")}
      aria-label={expanded ? expandedLabel : railLabel}
      aria-expanded={expanded}
      title={expanded ? expandedLabel : railLabel}
      onClick={() => setMode?.(expanded ? "rail" : "expanded")}
      {...props}
    >
      {expanded
        ? (expandedContent ?? <KIcon name="chevron-left" />)
        : (railContent ?? <KIcon name="chevron-right" />)}
    </button>
  );
}
