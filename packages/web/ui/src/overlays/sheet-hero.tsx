import { type ReactNode, type RefObject } from "react";
import { KIconButton } from "../actions/icon-button.js";
import type { KSheetDetent } from "./sheet-detents.js";

export interface KSheetHeroProps {
  /** Edge-to-edge media above the content. The system owns its height. */
  hero?: ReactNode;
  /** Secondary controls beside the system's close action. */
  floatingActions?: ReactNode;
  /** Media overlays, e.g. journey information and an expand control. */
  heroOverlays?: ReactNode;
  /** Fixed actions below the scrollable content, with the bottom safe area. */
  footer?: ReactNode;
  /** Optional phone resting heights; full always remains reachable. Full collapses a hero to its compact bar. */
  detents?: readonly KSheetDetent[];
  initialDetent?: KSheetDetent;
}

export function SheetHero({
  hero,
  floatingActions,
  heroOverlays,
  dismissible,
  closeLabel,
  onClose,
  closeRef,
  collapsed = false,
}: KSheetHeroProps & {
  dismissible: boolean;
  closeLabel: string;
  onClose: () => void;
  closeRef?: RefObject<HTMLButtonElement | null>;
  collapsed?: boolean;
}) {
  return (
    <div className="k-sheet-hero">
      <div className="k-sheet-hero__media" inert={collapsed || undefined}>
        {hero}
      </div>
      <div className="k-sheet-hero__floating">
        {floatingActions}
        {dismissible && (
          <KIconButton
            ref={closeRef}
            icon="x"
            label={closeLabel}
            onClick={onClose}
          />
        )}
      </div>
      {heroOverlays && (
        <div className="k-sheet-hero__overlays">{heroOverlays}</div>
      )}
    </div>
  );
}
