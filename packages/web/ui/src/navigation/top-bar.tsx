import {
  Children,
  Fragment,
  createContext,
  isValidElement,
  useContext,
  useId,
  useLayoutEffect,
  type ReactNode,
} from "react";
import { KIconButton } from "../actions/icon-button.js";
import { KMenuButton, type KMenuAction } from "../actions/menu-button.js";
import { KButton } from "../primitives/button.js";
import { KIcon } from "../primitives/icon.js";

/** What a `KPageHeader` hands to the phone top bar of `KAppShell`. */
export interface KTopBarEntry {
  backLabel?: string;
  onBack?: () => void;
  backHistory?: readonly KMenuAction[];
  /** Navigation button (menu, chat history) when there is no back. */
  leading?: ReactNode;
  actions?: ReactNode;
}

/**
 * The page headers below a shell. Only a header that is on screen fills the
 * bar, so pages kept alive in hidden tabs never leak their actions
 * (Decision 0015). Mirrors `KTopBarTitleController` in Flutter.
 */
export interface KTopBarRegistry {
  register(
    id: string,
    entry: KTopBarEntry,
    element: () => HTMLElement | null,
  ): void;
  unregister(id: string): void;
}

export const KTopBarContext = createContext<KTopBarRegistry | null>(null);

/** Registers the header's back control and actions with the top bar. */
export function useKTopBarEntry(
  entry: KTopBarEntry,
  element: { current: HTMLElement | null },
): boolean {
  const registry = useContext(KTopBarContext);
  const id = useId();
  const { backLabel, onBack, backHistory, leading, actions } = entry;
  useLayoutEffect(() => {
    if (!registry) return;
    registry.register(
      id,
      { backLabel, onBack, backHistory, leading, actions },
      () => element.current,
    );
    return () => registry.unregister(id);
  }, [registry, id, element, backLabel, onBack, backHistory, leading, actions]);
  return registry !== null;
}

/** Whether an element is rendered (not inside `display: none` or hidden). */
export function kIsShown(element: HTMLElement | null): boolean {
  return Boolean(element && element.getClientRects().length > 0);
}

type ActionProps = {
  label?: string;
  icon?: string;
  variant?: string;
  overflow?: boolean;
  actions?: readonly KMenuAction[];
  children?: ReactNode;
  onClick?: () => void;
  disabled?: boolean;
};

/** Where a page's primary action goes on phones (Decision 0015). */
export type KPrimaryActionPlacement = "auto" | "bar" | "fab";

export interface KTopBarPrimary {
  label: ReactNode;
  icon?: KMenuAction["icon"];
  onClick?: () => void;
  disabled?: boolean;
}

/** Matches a K component by reference or by its stable display name, so it
 * also works when the app and the library resolve to different bundles. */
function isK(type: unknown, component: { displayName?: string }): boolean {
  return (
    type === component ||
    (typeof type === "object" || typeof type === "function"
      ? (type as { displayName?: string } | null)?.displayName ===
        component.displayName
      : false)
  );
}

/** The `KIcon` among a button's children. */
function iconOf(props: ActionProps): KMenuAction["icon"] | undefined {
  for (const child of Children.toArray(props.children))
    if (isValidElement<{ name?: string }>(child) && isK(child.type, KIcon))
      return child.props.name as KMenuAction["icon"];
  return undefined;
}

/** A button's text without its icon. */
function textOf(props: ActionProps): string {
  return Children.toArray(props.children)
    .filter((child) => typeof child === "string" || typeof child === "number")
    .join("")
    .trim();
}

/**
 * Distributes the page header's actions (Decision 0015), as `_splitActions`
 * in Flutter: the first primary `KButton` is the primary action (an
 * extended FAB when `fab`, else an icon in the bar); icon buttons stay in
 * the bar, at most two; text buttons, further actions and the entries of
 * a page's own overflow menu share one More menu.
 */
export function kSplitTopBarActions(
  actions: ReactNode,
  moreLabel: string,
  fab: boolean,
): { bar: ReactNode[]; primary: KTopBarPrimary | null } {
  const bar: ReactNode[] = [];
  const menu: KMenuAction[] = [];
  let primary: KTopBarPrimary | null = null;
  // Fragments (`actions={<>…</>}`) count as their children.
  const flatten = (nodes: ReactNode): ReactNode[] =>
    Children.toArray(nodes).flatMap((node) =>
      isValidElement<{ children?: ReactNode }>(node) && node.type === Fragment
        ? flatten(node.props.children)
        : [node],
    );
  flatten(actions).forEach((action, index) => {
    if (!isValidElement<ActionProps>(action)) return;
    const props = action.props;
    if (
      isK(action.type, KButton) &&
      primary === null &&
      (props.variant ?? "primary") === "primary"
    ) {
      const icon = iconOf(props);
      if (fab) {
        primary = {
          label: textOf(props),
          icon,
          onClick: props.onClick,
          disabled: props.disabled,
        };
        return;
      }
      if (icon && bar.length < 2) {
        bar.push(
          <KIconButton
            key={`primary-${index}`}
            label={textOf(props)}
            icon={icon}
            onClick={props.onClick}
            disabled={props.disabled}
          />,
        );
        return;
      }
    }
    if (isK(action.type, KIconButton) && bar.length < 2) bar.push(action);
    else if (isK(action.type, KIconButton) || isK(action.type, KButton))
      menu.push({
        id: String(index),
        label: props.label ?? textOf(props),
        icon: (props.icon as KMenuAction["icon"]) ?? iconOf(props),
        onSelect: props.onClick,
        disabled: props.disabled,
      });
    else if (isK(action.type, KMenuButton) && props.overflow && props.actions)
      menu.push(...props.actions);
    else if (bar.length < 2) bar.push(action);
  });
  if (menu.length)
    bar.push(
      <KMenuButton key="more" label={moreLabel} overflow actions={menu} />,
    );
  return { bar, primary };
}
