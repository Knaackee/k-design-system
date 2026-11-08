import { MenuLevel, KContextMenu } from "./context-menu.js";
import {
  Fragment,
  useEffect,
  useId,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { KButton, type KButtonVariant } from "../primitives/button.js";
import { KIcon, type KIconName } from "../primitives/icon.js";

export interface KMenuAction {
  id: string;
  label: ReactNode;
  /** Navigation links retain native href and modifier-key behavior. */
  href?: string;
  icon?: KIconName;
  /** Consumer-provided leading visual, e.g. a file-type icon. */
  iconContent?: ReactNode;
  disabled?: boolean;
  /** Radio-menu selection; omit for ordinary actions. */
  checked?: boolean;
  destructive?: boolean;
  separatorBefore?: boolean;
  onSelect?: () => void;
  children?: readonly KMenuAction[];
  /** Secondary actions on long press, right click, or the context-menu key. */
  contextActions?: readonly KMenuAction[];
}

export function MenuActionContext({
  action,
  close,
  children,
}: {
  action: KMenuAction;
  close: () => void;
  children: ReactNode;
}) {
  if (action.disabled || !action.contextActions?.length) return <>{children}</>;
  const bind = (items: readonly KMenuAction[]): KMenuAction[] =>
    items.map((item) => ({
      ...item,
      children: item.children ? bind(item.children) : undefined,
      onSelect: () => {
        close();
        item.onSelect?.();
      },
    }));
  return (
    <KContextMenu
      label={typeof action.label === "string" ? action.label : "Aktionen"}
      actions={bind(action.contextActions)}
    >
      {children}
    </KContextMenu>
  );
}
export interface KMenuButtonProps {
  label: string;
  actions: readonly KMenuAction[];
  disabled?: boolean;
  /** Compact overflow trigger, with the same labelled action menu. */
  overflow?: boolean;
  /** Consumer-owned trigger composition; the accessible name still comes from label. */
  triggerContent?: ReactNode;
  triggerVariant?: KButtonVariant;
  triggerClassName?: string;
  fullWidth?: boolean;
  /** Non-interactive menu heading, e.g. account details. */
  header?: ReactNode;
  align?: "start" | "end";
  onOpenChange?: (open: boolean) => void;
}

export function KMenuButton({
  label,
  actions,
  disabled = false,
  overflow = false,
  triggerContent,
  triggerVariant,
  triggerClassName,
  fullWidth = false,
  header,
  align = "start",
  onOpenChange,
}: KMenuButtonProps) {
  const nested = actions.some((action) => action.children?.length);
  const id = useId();
  const trigger = useRef<HTMLButtonElement>(null);
  const menu = useRef<HTMLDivElement>(null);
  const [open, setOpen] = useState(false);
  const search = useRef({ text: "", time: 0 });
  const items = () =>
    Array.from(
      menu.current?.querySelectorAll<HTMLElement>(
        '[role="menuitem"]:not(:disabled), [role="menuitemradio"]:not(:disabled)',
      ) ?? [],
    ).filter(
      (item) =>
        item.closest('[role="menu"]') ===
        (nested
          ? menu.current?.querySelector(":scope > .k-context-menu__level")
          : menu.current),
    );
  function close(restore = true) {
    menu.current?.hidePopover();
    setOpen(false);
    if (restore) trigger.current?.focus();
  }
  function position() {
    const panel = menu.current,
      button = trigger.current;
    if (!panel || !button) return;
    const rect = (
      button.closest(".k-button-target") ?? button
    ).getBoundingClientRect();
    const bounds = panel.getBoundingClientRect();
    const gutter = 8;
    const gap =
      parseFloat(
        getComputedStyle(button).getPropertyValue("--k-space-control-gap"),
      ) || 4;
    const left = align === "end" ? rect.right - bounds.width : rect.left;
    const below = rect.bottom + gap;
    const above = rect.top - gap - bounds.height;
    const top =
      below + bounds.height <= innerHeight - gutter || above < gutter
        ? below
        : above;
    panel.style.left = `${Math.max(gutter, Math.min(left, innerWidth - bounds.width - gutter))}px`;
    panel.style.top = `${Math.max(gutter, Math.min(top, innerHeight - bounds.height - gutter))}px`;
  }
  function show(last = false) {
    if (disabled || actions.length === 0) return;
    menu.current?.showPopover();
    position();
    setOpen(true);
    if (nested) {
      requestAnimationFrame(() => {
        const buttons = items();
        (last ? buttons.at(-1) : buttons[0])?.focus();
      });
      return;
    }
    const buttons = items();
    (last ? buttons.at(-1) : buttons[0])?.focus();
    if (!buttons.length) menu.current?.focus();
  }
  useEffect(() => {
    if (!open) return;
    const reposition = () => position();
    window.addEventListener("resize", reposition);
    window.addEventListener("scroll", reposition, true);
    const observer = new ResizeObserver(reposition);
    if (menu.current) observer.observe(menu.current);
    return () => {
      observer.disconnect();
      window.removeEventListener("resize", reposition);
      window.removeEventListener("scroll", reposition, true);
    };
  }, [open, align]);
  useEffect(() => {
    if (disabled || actions.length === 0) close(false);
  }, [disabled, actions.length]);
  return (
    <>
      <KButton
        ref={trigger}
        variant={triggerVariant ?? (overflow ? "ghost" : "secondary")}
        className={[
          overflow ? "k-icon-button" : "k-menu-trigger",
          triggerClassName,
        ]
          .filter(Boolean)
          .join(" ")}
        fullWidth={fullWidth}
        disabled={disabled || actions.length === 0}
        aria-label={label}
        title={overflow ? label : undefined}
        aria-haspopup="menu"
        aria-expanded={open}
        aria-controls={id}
        onClick={() => (open ? close() : show())}
        onKeyDown={(event) => {
          if (event.defaultPrevented) return;
          if (event.key === "ArrowDown" || event.key === "ArrowUp") {
            event.preventDefault();
            event.stopPropagation();
            show(event.key === "ArrowUp");
          }
        }}
      >
        {triggerContent ??
          (overflow ? (
            <KIcon name="ellipsis" color="currentColor" />
          ) : (
            <span className="k-menu-trigger__content">
              {label}
              <KIcon name="chevron-down" color="currentColor" />
            </span>
          ))}
      </KButton>
      <div
        id={id}
        ref={menu}
        className={nested ? "k-menu k-context-menu" : "k-menu"}
        popover="auto"
        role={nested ? "presentation" : "menu"}
        aria-label={label}
        tabIndex={-1}
        onToggle={(event) => {
          const next = event.newState === "open";
          setOpen(next);
          onOpenChange?.(next);
        }}
        onKeyDown={(event) => {
          if (event.defaultPrevented) return;
          if (nested && event.key !== "Tab") return;
          event.stopPropagation();
          const buttons = items();
          const current = buttons.indexOf(
            document.activeElement as HTMLElement,
          );
          let next: number | undefined;
          switch (event.key) {
            case "Escape":
              event.preventDefault();
              close();
              return;
            case "Tab":
              close();
              return;
            case "ArrowDown":
              next = (current + 1) % buttons.length;
              break;
            case "ArrowUp":
              next = (current - 1 + buttons.length) % buttons.length;
              break;
            case "Home":
              next = 0;
              break;
            case "End":
              next = buttons.length - 1;
              break;
            default:
              if (
                event.key.length === 1 &&
                !event.ctrlKey &&
                !event.metaKey &&
                event.key !== " "
              ) {
                const now = Date.now();
                search.current.text =
                  now - search.current.time > 700
                    ? event.key
                    : search.current.text + event.key;
                search.current.time = now;
                const ordered = [
                  ...buttons.slice(current + 1),
                  ...buttons.slice(0, current + 1),
                ];
                ordered
                  .find((button) =>
                    button.textContent
                      ?.trim()
                      .toLowerCase()
                      .startsWith(search.current.text.toLowerCase()),
                  )
                  ?.focus();
              }
          }
          if (next !== undefined) {
            event.preventDefault();
            buttons[next]?.focus();
          }
        }}
      >
        {header != null ? (
          <div role="presentation" className="k-menu__header">
            {header}
          </div>
        ) : null}
        {nested ? (
          <MenuLevel
            key={String(open)}
            actions={actions}
            close={close}
            label={label}
          />
        ) : (
          actions.map((action, index) => {
            const Item = action.href && !action.disabled ? "a" : "button";
            return (
              <Fragment key={action.id}>
                {index > 0 && action.separatorBefore ? (
                  <div role="separator" className="k-menu__separator" />
                ) : null}
                <MenuActionContext action={action} close={close}>
                  <Item
                    {...(action.href && !action.disabled
                      ? { href: action.href }
                      : { type: "button" as const, disabled: action.disabled })}
                    role={
                      action.checked === undefined
                        ? "menuitem"
                        : "menuitemradio"
                    }
                    aria-checked={action.checked}
                    tabIndex={-1}
                    className="k-menu__item"
                    data-destructive={action.destructive || undefined}
                    onClick={(event) => {
                      if (
                        action.href &&
                        (event.metaKey ||
                          event.ctrlKey ||
                          event.shiftKey ||
                          event.altKey ||
                          event.button !== 0)
                      )
                        return;
                      close();
                      action.onSelect?.();
                    }}
                  >
                    <span className="k-menu__icon">
                      {action.iconContent ??
                        (action.icon ? (
                          <KIcon name={action.icon} color="currentColor" />
                        ) : null)}
                    </span>
                    <span className="k-menu__label">{action.label}</span>
                    <span className="k-menu__trailing" aria-hidden="true">
                      {action.checked ? <KIcon name="check" size={16} /> : null}
                    </span>
                  </Item>
                </MenuActionContext>
              </Fragment>
            );
          })
        )}
      </div>
    </>
  );
}

export function KOverflowMenu(props: Omit<KMenuButtonProps, "overflow">) {
  return <KMenuButton {...props} overflow />;
}

// A stable name: page headers and rows recognise it across bundles.
KMenuButton.displayName = "KMenuButton";
