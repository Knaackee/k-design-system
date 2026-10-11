import {
  Fragment,
  type KeyboardEvent,
  type MouseEvent,
  type PointerEvent,
  type ReactNode,
  useId,
  useEffect,
  useRef,
  useState,
} from "react";
import { KIcon } from "../primitives/icon.js";
import type { KMenuAction } from "./menu-button.js";

export interface KContextMenuProps {
  label: string;
  actions: readonly KMenuAction[];
  children: ReactNode;
  disabled?: boolean;
  onOpenChange?(open: boolean): void;
}

function enabledItems(level: HTMLElement) {
  return Array.from(
    level.querySelectorAll<HTMLButtonElement>(
      ":scope > .k-context-menu__entry > [role=menuitem]:not(:disabled)",
    ),
  );
}

function MenuLevel({
  actions,
  close,
  nested = false,
  label,
}: {
  actions: readonly KMenuAction[];
  close: () => void;
  nested?: boolean;
  label?: string;
}) {
  const level = useRef<HTMLDivElement>(null);
  const [openId, setOpenId] = useState<string>();
  function openSubmenu(id: string, focus = false) {
    setOpenId(id);
    requestAnimationFrame(() => {
      const container = level.current?.querySelector<HTMLElement>(
        `[data-context-submenu="${id}"]`,
      );
      const submenu = container?.querySelector<HTMLElement>(
        ".k-context-menu__submenu",
      );
      if (!container || !submenu) return;
      container.dataset.side = "right";
      if (submenu.getBoundingClientRect().right > innerWidth - 8) {
        container.dataset.side = "left";
      }
      if (focus) {
        enabledItems(submenu)[0]?.focus();
      }
    });
  }
  function navigate(event: KeyboardEvent<HTMLDivElement>) {
    const items = enabledItems(event.currentTarget);
    const current = items.indexOf(document.activeElement as HTMLButtonElement);
    let next: number | undefined;
    if (event.key === "ArrowDown") next = (current + 1) % items.length;
    if (event.key === "ArrowUp")
      next = (current - 1 + items.length) % items.length;
    if (event.key === "Home") next = 0;
    if (event.key === "End") next = items.length - 1;
    if (event.key === "Escape") {
      event.preventDefault();
      close();
      return;
    }
    if (event.key === "ArrowLeft" && nested) {
      event.preventDefault();
      setOpenId(undefined);
      event.currentTarget.parentElement
        ?.querySelector<HTMLButtonElement>(":scope > [role=menuitem]")
        ?.focus();
      return;
    }
    if (next !== undefined && items.length) {
      event.preventDefault();
      items[next]?.focus();
    }
  }
  return (
    <div
      ref={level}
      role="menu"
      aria-label={label}
      className={nested ? "k-context-menu__submenu" : "k-context-menu__level"}
      onKeyDown={navigate}
    >
      {actions.map((action, index) => {
        const hasChildren =
          !action.disabled && Boolean(action.children?.length);
        return (
          <Fragment key={action.id}>
            {index > 0 && action.separatorBefore ? (
              <div role="separator" className="k-menu__separator" />
            ) : null}
            <div
              className="k-context-menu__entry"
              data-open={openId === action.id || undefined}
              onPointerEnter={() => hasChildren && openSubmenu(action.id)}
              onPointerLeave={() => hasChildren && setOpenId(undefined)}
            >
              <button
                type="button"
                role="menuitem"
                tabIndex={-1}
                disabled={action.disabled}
                className="k-menu__item"
                data-destructive={action.destructive || undefined}
                aria-haspopup={hasChildren ? "menu" : undefined}
                aria-expanded={hasChildren ? openId === action.id : undefined}
                onFocus={() => {
                  if (!hasChildren) setOpenId(undefined);
                }}
                onClick={() => {
                  if (hasChildren) {
                    openSubmenu(action.id, true);
                    return;
                  }
                  close();
                  action.onSelect?.();
                }}
                onKeyDown={(event) => {
                  if (hasChildren && event.key === "ArrowRight") {
                    event.preventDefault();
                    event.stopPropagation();
                    openSubmenu(action.id, true);
                  }
                }}
              >
                <span className="k-context-menu__icon">
                  {action.icon ? (
                    <KIcon name={action.icon} color="currentColor" />
                  ) : null}
                </span>
                <span>{action.label}</span>
                {hasChildren ? (
                  <KIcon name="chevron-right" color="currentColor" />
                ) : null}
              </button>
              {hasChildren ? (
                <div data-context-submenu={action.id}>
                  <MenuLevel actions={action.children!} close={close} nested />
                </div>
              ) : null}
            </div>
          </Fragment>
        );
      })}
    </div>
  );
}

export function KContextMenu({
  label,
  actions,
  children,
  disabled = false,
  onOpenChange,
}: KContextMenuProps) {
  const id = useId();
  const target = useRef<HTMLDivElement>(null);
  const menu = useRef<HTMLDivElement>(null);
  const open = useRef(false);
  const openChange = useRef(onOpenChange);
  openChange.current = onOpenChange;
  useEffect(
    () => () => {
      if (open.current) openChange.current?.(false);
    },
    [],
  );
  const longPressTimer = useRef<number | undefined>(undefined);
  const longPressTriggered = useRef(false);
  useEffect(() => () => window.clearTimeout(longPressTimer.current), []);
  const pointerStart = useRef<{ x: number; y: number } | undefined>(undefined);
  function cancelLongPress() {
    if (longPressTimer.current !== undefined) {
      window.clearTimeout(longPressTimer.current);
      longPressTimer.current = undefined;
    }
  }
  function close() {
    menu.current?.hidePopover();
  }
  function openAt(x: number, y: number) {
    if (disabled || actions.length === 0) return;
    const panel = menu.current;
    if (!panel) return;
    panel.showPopover();
    const bounds = panel.getBoundingClientRect();
    panel.style.left = `${Math.max(8, Math.min(x, innerWidth - bounds.width - 8))}px`;
    panel.style.top = `${Math.max(8, Math.min(y, innerHeight - bounds.height - 8))}px`;
    requestAnimationFrame(() => {
      const root = panel.querySelector<HTMLElement>(".k-context-menu__level");
      if (root) enabledItems(root)[0]?.focus();
    });
  }
  function openFromPointer(event: MouseEvent<HTMLDivElement>) {
    event.preventDefault();
    openAt(event.clientX, event.clientY);
  }
  function startLongPress(event: PointerEvent<HTMLDivElement>) {
    longPressTriggered.current = false;
    if (event.pointerType === "mouse") return;
    cancelLongPress();
    pointerStart.current = { x: event.clientX, y: event.clientY };
    longPressTimer.current = window.setTimeout(() => {
      longPressTriggered.current = true;
      openAt(event.clientX, event.clientY);
      longPressTimer.current = undefined;
    }, 500);
  }
  function trackLongPress(event: PointerEvent<HTMLDivElement>) {
    const start = pointerStart.current;
    if (
      start &&
      Math.hypot(event.clientX - start.x, event.clientY - start.y) > 8
    ) {
      cancelLongPress();
    }
  }
  return (
    <>
      <div
        ref={target}
        className="k-context-menu__target"
        tabIndex={disabled ? undefined : 0}
        aria-controls={id}
        onContextMenu={openFromPointer}
        onPointerDown={startLongPress}
        onPointerMove={trackLongPress}
        onPointerUp={cancelLongPress}
        onPointerCancel={cancelLongPress}
        onClickCapture={(event) => {
          if (longPressTriggered.current) {
            event.preventDefault();
            event.stopPropagation();
            longPressTriggered.current = false;
          }
        }}
        onKeyDown={(event) => {
          if (
            event.key !== "ContextMenu" &&
            !(event.shiftKey && event.key === "F10")
          ) {
            return;
          }
          event.preventDefault();
          const rect = target.current?.getBoundingClientRect();
          if (rect) openAt(rect.left + 12, rect.top + 12);
        }}
      >
        {children}
      </div>
      <div
        id={id}
        ref={menu}
        popover="auto"
        className="k-menu k-context-menu"
        role="presentation"
        onToggle={(event) => {
          open.current = event.newState === "open";
          onOpenChange?.(open.current);
        }}
      >
        <MenuLevel actions={actions} close={close} label={label} />
      </div>
    </>
  );
}
