import type { KDataTableGroupValue } from "./data-table-entries.js";
export type KDataTableDraftStatus = "pristine" | "dirty" | "saving" | "error";
export type KDataTableDraftReason =
  "programmatic" | "enter" | "escape" | "rowExit" | "action";
export interface KDataTableDraftRow<T> {
  row: T;
  originIndex?: number;
  originQueryRevision?: string;
  originPath: readonly KDataTableGroupValue[];
}
export interface KDataTableDraftSnapshot<T> {
  id: string;
  baseline: T;
  current: T;
  status: KDataTableDraftStatus;
  originIndex?: number;
  originQueryRevision?: string;
  originPath: readonly KDataTableGroupValue[];
  initialColumnId: string;
  error?: unknown;
}
export interface KDataTableDraftEvent<T> {
  type:
    | "started"
    | "changed"
    | "commitRequested"
    | "committed"
    | "cancelled"
    | "error";
  reason: KDataTableDraftReason;
  snapshot: KDataTableDraftSnapshot<T>;
  acceptedRow?: T;
}
export interface KDataTableDraftOptions<T> {
  rowId: (row: T) => string;
  cloneRow: (row: T) => T;
  isEqual: (a: T, b: T) => boolean;
  onCommit: (row: T, snapshot: KDataTableDraftSnapshot<T>) => T | Promise<T>;
  savePolicy?: "explicit" | "rowExit";
  onEvent?: (event: KDataTableDraftEvent<T>) => void;
}
/** Consumer-owned state: keep this controller outside recycled cells. */
export class KDataTableDraftController<T> {
  private records = new Map<string, KDataTableDraftSnapshot<T>>();
  private listeners = new Set<() => void>();
  private pending = new Map<string, Promise<boolean>>();
  private leases = new Map<string, number>();
  private disposed = false;
  private options: KDataTableDraftOptions<T>;
  constructor(options: KDataTableDraftOptions<T>) {
    this.options = options;
  }
  private copy(s: KDataTableDraftSnapshot<T>): KDataTableDraftSnapshot<T> {
    return {
      ...s,
      baseline: this.options.cloneRow(s.baseline),
      current: this.options.cloneRow(s.current),
      originPath: s.originPath.map((g) => ({ ...g })),
    };
  }
  get drafts() {
    return [...this.records.values()].map((s) => this.copy(s));
  }
  get(id: string) {
    const s = this.records.get(id);
    return s ? this.copy(s) : undefined;
  }
  subscribe = (listener: () => void) => {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  };
  private publish(
    type: KDataTableDraftEvent<T>["type"],
    s: KDataTableDraftSnapshot<T>,
    reason: KDataTableDraftReason,
    acceptedRow?: T,
  ) {
    try {
      this.options.onEvent?.({
        type,
        snapshot: this.copy(s),
        reason,
        acceptedRow:
          acceptedRow === undefined
            ? undefined
            : this.options.cloneRow(acceptedRow),
      });
    } catch (error) {
      // An observer failure cannot turn a successful persistence result into a failed save.
      console.error("KDataTable draft lifecycle observer failed", error);
    } finally {
      for (const listener of this.listeners) listener();
    }
  }

  begin(
    row: T,
    {
      originPath = [],
      initialColumnId,
      originIndex,
      originQueryRevision,
    }: {
      originPath?: readonly KDataTableGroupValue[];
      initialColumnId: string;
      originIndex?: number;
      originQueryRevision?: string;
    },
  ) {
    if (this.disposed) throw new Error("Draft controller is disposed");
    const id = this.options.rowId(row);
    if (!id.trim() || !initialColumnId.trim() || this.records.has(id))
      throw new Error(
        "Draft requires unique nonempty row ID and initial column",
      );
    const s: KDataTableDraftSnapshot<T> = {
      id,
      baseline: this.options.cloneRow(row),
      current: this.options.cloneRow(row),
      status: "pristine",
      originPath: originPath.map((g) => ({ ...g })),
      initialColumnId,
      originIndex,
      originQueryRevision,
    };
    this.records.set(id, s);
    this.publish("started", s, "programmatic");
    return this.copy(s);
  }
  update(id: string, row: T, reason: KDataTableDraftReason = "programmatic") {
    const s = this.records.get(id);
    if (!s || s.status === "saving" || this.disposed) return false;
    if (this.options.rowId(row) !== id)
      throw new Error("Draft row identity cannot change");
    const next = {
      ...s,
      current: this.options.cloneRow(row),
      status: this.options.isEqual(s.baseline, row)
        ? ("pristine" as const)
        : ("dirty" as const),
      error: undefined,
    };
    this.records.set(id, next);
    this.publish("changed", next, reason);
    return true;
  }
  commit(
    id: string,
    reason: KDataTableDraftReason = "programmatic",
  ): Promise<boolean> {
    const existing = this.pending.get(id);
    if (existing) return existing;
    const s = this.records.get(id);
    if (!s || this.disposed) return Promise.resolve(false);
    const saving = { ...s, status: "saving" as const, error: undefined };
    this.records.set(id, saving);
    // Install the promise before lifecycle callbacks, including reentrant consumers.
    const request = Promise.resolve()
      .then(() =>
        this.options.onCommit(
          this.options.cloneRow(s.current),
          this.copy(saving),
        ),
      )
      .then((row) => {
        if (this.disposed || this.records.get(id) !== saving) return false;
        if (this.options.rowId(row) !== id)
          throw new Error("Committed row identity cannot change");
        this.records.delete(id);

        this.publish("committed", saving, reason, row);
        return true;
      })
      .catch((error) => {
        if (this.disposed || this.records.get(id) !== saving) return false;
        const failed = { ...s, status: "error" as const, error };
        this.records.set(id, failed);
        this.publish("error", failed, reason);
        return false;
      })
      .finally(() => {
        if (this.pending.get(id) === request) this.pending.delete(id);
      });
    this.pending.set(id, request);
    this.publish("commitRequested", saving, reason);
    return request;
  }
  cancel(id: string, reason: KDataTableDraftReason = "programmatic") {
    const s = this.records.get(id);
    if (!s || s.status === "saving" || this.disposed) return false;
    this.records.delete(id);

    this.publish("cancelled", s, reason);
    return true;
  }
  leave(id: string) {
    const s = this.records.get(id);
    if (!s || this.disposed || s.status === "saving") return;
    if (this.leases.get(id)) {
      return;
    }
    if (this.options.isEqual(s.baseline, s.current)) this.cancel(id, "rowExit");
    else if (this.options.savePolicy === "rowExit")
      void this.commit(id, "rowExit");
  }
  retainInteraction(id: string) {
    this.leases.set(id, (this.leases.get(id) ?? 0) + 1);
    let released = false;
    return () => {
      if (released) return;
      released = true;
      const n = (this.leases.get(id) ?? 1) - 1;
      if (n) this.leases.set(id, n);
      else {
        this.leases.delete(id);
      }
    };
  }
  dispose() {
    this.disposed = true;
    this.records.clear();
    this.listeners.clear();
    this.leases.clear();
  }
}
