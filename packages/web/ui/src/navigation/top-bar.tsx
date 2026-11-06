import {
  Children,
  createContext,
  isValidElement,
  useContext,
  useLayoutEffect,
  type ReactNode,
} from "react";
import { KIconButton } from "../actions/icon-button.js";
import { KMenuButton, type KMenuAction } from "../actions/menu-button.js";
import { KButton } from "../primitives/button.js";

/** What a `KPageHeader` hands to the phone top bar of `KAppShell`. */
export interface KTopBarEntry {
  backLabel?: string;
  onBack?: () => void;
  backHistory?: readonly KMenuAction[];
  actions?: ReactNode;
}

export const KTopBarContext = createContext<
  ((entry: KTopBarEntry | null) => void) | null
>(null);

/** Registers the header's back control and actions with the top bar. */
export function useKTopBarEntry(entry: KTopBarEntry) {
  const register = useContext(KTopBarContext);
  const { backLabel, onBack, backHistory, actions } = entry;
  useLayoutEffect(() => {
    if (!register) return;
    register({ backLabel, onBack, backHistory, actions });
    return () => register(null);
  }, [register, backLabel, onBack, backHistory, actions]);
}

type ActionProps = {
  label?: string;
  icon?: string;
  children?: ReactNode;
  onClick?: () => void;
  disabled?: boolean;
};

/**
 * Icon actions (at most two) stay in the bar; text buttons and the rest go
 * into a More menu, so the bar never overflows (Decision 0015). Mirrors
 * `_barActions` in Flutter.
 */
export function kTopBarActions(actions: ReactNode, moreLabel: string) {
  const visible: ReactNode[] = [];
  const menu: KMenuAction[] = [];
  Children.toArray(actions).forEach((action, index) => {
    if (!isValidElement<ActionProps>(action)) return;
    const props = action.props;
    if (action.type === KIconButton && visible.length < 2) visible.push(action);
    else if (action.type === KIconButton || action.type === KButton)
      menu.push({
        id: String(index),
        label: props.label ?? props.children,
        icon: props.icon as KMenuAction["icon"],
        onSelect: props.onClick,
        disabled: props.disabled,
      });
    else if (visible.length < 2) visible.push(action);
  });
  if (menu.length)
    visible.push(
      <KMenuButton key="more" label={moreLabel} overflow actions={menu} />,
    );
  return visible;
}
