import { useEffect, useRef, useState } from "react";
import type { KMapZoneCommitPlan } from "../maps/map-zone-boolean.js";
import type { KMapZone } from "../maps/map-zone-geometry.js";
import type { KMapZoneUndoAction } from "./map-zone-editor-types.js";

const zonesKey = (zones: readonly KMapZone[]) => JSON.stringify(zones);

export function useZoneEditorCommit({
  zones,
  onChange,
  onExternalChange,
  blocked,
  message,
  label,
  onUndoActionChange,
}: {
  zones: readonly KMapZone[];
  onChange: (zones: readonly KMapZone[]) => void;
  onExternalChange: () => void;
  blocked: boolean;
  message: string;
  label: string;
  onUndoActionChange?: (action: KMapZoneUndoAction | null) => void;
}) {
  const [pending, setPending] = useState<KMapZoneCommitPlan | null>(null);
  const [transaction, setTransaction] = useState<{
    previousZones: KMapZone[];
    afterKey: string;
  } | null>(null);
  const current = useRef(zones);
  current.current = zones;
  const afterCommit = useRef<(() => void) | null>(null);
  const active = useRef(transaction);
  active.current = transaction;
  const isBlocked = useRef(blocked);
  isBlocked.current = blocked;
  const change = useRef(onChange);
  change.current = onChange;
  const documentKey = zonesKey(zones);
  useEffect(() => {
    if (!transaction || blocked || transaction.afterKey !== documentKey) {
      if (transaction) setTransaction(null);
      onUndoActionChange?.(null);
      return;
    }
    onUndoActionChange?.({
      message,
      label,
      undo: () => {
        if (
          active.current !== transaction ||
          isBlocked.current ||
          zonesKey(current.current) !== transaction.afterKey
        )
          return;
        active.current = null;
        current.current = transaction.previousZones;
        change.current(transaction.previousZones);
        setTransaction(null);
      },
    });
    return () => onUndoActionChange?.(null);
  }, [transaction, blocked, documentKey, message, label, onUndoActionChange]);

  const finalize = (plan: KMapZoneCommitPlan) => {
    if (zonesKey(current.current) !== zonesKey(plan.previousZones)) {
      setPending(null);
      afterCommit.current = null;
      onExternalChange();
      return false;
    }
    current.current = plan.zones;
    onChange(plan.zones);
    setTransaction({
      previousZones: plan.previousZones,
      afterKey: zonesKey(plan.zones),
    });
    setPending(null);
    const done = afterCommit.current;
    afterCommit.current = null;
    done?.();
    return true;
  };

  return {
    pending,
    previewZones: pending?.zones,
    request: (plan: KMapZoneCommitPlan, done: () => void) => {
      afterCommit.current = done;
      if (plan.impacts.length) {
        setPending(plan);
        return false;
      }
      return finalize(plan);
    },
    confirm: () => (pending ? finalize(pending) : false),
    cancel: () => {
      setPending(null);
      afterCommit.current = null;
    },
  };
}
