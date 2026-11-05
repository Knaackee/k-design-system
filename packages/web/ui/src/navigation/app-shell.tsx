import {
  useLayoutEffect,
  useRef,
  useState,
  type HTMLAttributes,
  type ReactNode,
} from "react";
import { kWindowClassForWidth, type KWindowClass } from "../adaptive.js";
import { KBadge } from "../basic-components.js";
import { useOptionalKHaptics } from "../feedback/haptics.js";
import { KIcon, type KIconName } from "../primitives/icon.js";
import { KMobileAppBar } from "./mobile-app-bar.js";
import {
  KSidebar,
  KSidebarBody,
  KSidebarFooter,
  KSidebarHeader,
  KSidebarItem,
} from "./sidebar.js";

export interface KAppDestination {
  id: string;
  label: string;
  icon: KIconName;
  selectedIcon?: KIconName;
  /** Short count or marker ("2", "99+"): tab bar badge, sidebar KBadge. */
  badge?: string;
}

export interface KAppShellProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  "onSelect"
> {
  destinations: readonly KAppDestination[];
  selectedId: string;
  onSelectedChange: (id: string) => void;
  children: ReactNode;
  /** Above the destinations in the expanded sidebar (app name, account). */
  sidebarHeader?: ReactNode;
  /** Below the destinations in the expanded sidebar (settings, help). */
  sidebarFooter?: ReactNode;
  label?: string;
}

/**
 * Adaptive app frame for top-level destinations (Decision 0012): below
 * 600 px a tab bar (2–5 destinations), 600–839 px a sidebar rail, from
 * 840 px the expanded sidebar. The shell's own width decides, so a split
 * view behaves like a small window. The shell holds no routes.
 */
export function KAppShell({
  destinations,
  selectedId,
  onSelectedChange,
  children,
  sidebarHeader,
  sidebarFooter,
  label = "Primary navigation",
  className,
  ...props
}: KAppShellProps) {
  const ref = useRef<HTMLDivElement>(null);
  const haptics = useOptionalKHaptics();
  const [windowClass, setWindowClass] = useState<KWindowClass>(() =>
    typeof window === "undefined"
      ? "compact"
      : kWindowClassForWidth(window.innerWidth),
  );
  useLayoutEffect(() => {
    const element = ref.current;
    if (!element) return;
    const update = () =>
      setWindowClass(kWindowClassForWidth(element.clientWidth));
    update();
    if (typeof ResizeObserver === "undefined") return;
    const observer = new ResizeObserver(update);
    observer.observe(element);
    return () => observer.disconnect();
  }, []);
  if (destinations.length < 2 || destinations.length > 5)
    console.error(
      'KAppShell: a tab bar holds 2 to 5 destinations (Apple HIG); group the rest inside an existing tab (no "More" tab).',
    );
  const select = (id: string) => {
    if (id === selectedId) return;
    haptics?.perform("selection");
    onSelectedChange(id);
  };
  const compact = windowClass === "compact";
  const rail = windowClass === "medium";
  return (
    <div
      ref={ref}
      className={["k-app-shell", className].filter(Boolean).join(" ")}
      data-layout={compact ? "tab-bar" : rail ? "rail" : "sidebar"}
      {...props}
    >
      {compact ? null : (
        <KSidebar mode={rail ? "rail" : "expanded"} label={label}>
          {sidebarHeader && !rail ? (
            <KSidebarHeader>{sidebarHeader}</KSidebarHeader>
          ) : null}
          <KSidebarBody>
            {destinations.map((destination) => {
              const active = destination.id === selectedId;
              return (
                <KSidebarItem
                  key={destination.id}
                  label={destination.label}
                  textLabel={destination.label}
                  leading={
                    <KIcon
                      name={
                        active
                          ? (destination.selectedIcon ?? destination.icon)
                          : destination.icon
                      }
                      size={20}
                    />
                  }
                  badge={
                    destination.badge ? (
                      <KBadge>{destination.badge}</KBadge>
                    ) : undefined
                  }
                  active={active}
                  onSelect={() => select(destination.id)}
                />
              );
            })}
          </KSidebarBody>
          {sidebarFooter && !rail ? (
            <KSidebarFooter>{sidebarFooter}</KSidebarFooter>
          ) : null}
        </KSidebar>
      )}
      <div className="k-app-shell__content">{children}</div>
      {compact ? (
        <KMobileAppBar
          variant="fixed"
          labelVisibility="always"
          visibility="always"
          label={label}
          selectedId={selectedId}
          onSelectionChange={select}
          items={destinations.map((destination) => ({
            id: destination.id,
            label: destination.label,
            icon: <KIcon name={destination.icon} size={24} />,
            selectedIcon: destination.selectedIcon ? (
              <KIcon name={destination.selectedIcon} size={24} />
            ) : undefined,
            badge: destination.badge,
          }))}
        />
      ) : null}
    </div>
  );
}
