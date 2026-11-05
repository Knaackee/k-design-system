/**
 * Haptic cues shared with Flutter (Decision 0013). Use them sparingly and
 * always together with visible feedback; never for scrolling, hover or typing.
 */
export type KHapticCue =
  "selection" | "light" | "medium" | "heavy" | "success" | "warning" | "error";

/**
 * Vibration patterns in ms for the Vibration API. Browsers without it
 * (Safari on iOS and macOS, desktop browsers) stay silent.
 */
export const kHapticPatterns: Readonly<Record<KHapticCue, number | number[]>> =
  {
    selection: 8,
    light: 10,
    medium: 18,
    heavy: 28,
    success: [10, 60, 14],
    warning: [18, 80, 18],
    error: [24, 50, 24, 50, 24],
  };

export interface KHapticControllerOptions {
  enabled?: boolean;
  /** Cues closer together are dropped (ms). */
  minInterval?: number;
  /** Transport; defaults to `navigator.vibrate`. Allows tests and native shells. */
  vibrate?: (pattern: number | number[]) => boolean;
  /** Clock for tests. */
  now?: () => number;
}

function defaultVibrate(): KHapticControllerOptions["vibrate"] {
  if (typeof navigator === "undefined") return undefined;
  const vibrate = (navigator as Navigator & { vibrate?: Navigator["vibrate"] })
    .vibrate;
  return typeof vibrate === "function" ? vibrate.bind(navigator) : undefined;
}

/** Off by default; the host decides and persists whether haptics are on. */
export class KHapticController {
  private enabledValue: boolean;
  private active = true;
  private last = Number.NEGATIVE_INFINITY;
  private readonly vibrate?: (pattern: number | number[]) => boolean;
  private readonly minInterval: number;
  private readonly now: () => number;
  constructor(options: KHapticControllerOptions = {}) {
    this.enabledValue = options.enabled ?? false;
    this.vibrate = options.vibrate ?? defaultVibrate();
    this.minInterval = Math.max(0, options.minInterval ?? 60);
    this.now = options.now ?? (() => Date.now());
  }
  /** False where the browser has no Vibration API (for example iOS Safari). */
  get isSupported() {
    return Boolean(this.vibrate);
  }
  get enabled() {
    return this.enabledValue;
  }
  setEnabled(enabled: boolean) {
    this.enabledValue = enabled;
  }
  setActive(active: boolean) {
    this.active = active;
  }
  /** Plays the cue when enabled, visible, supported and outside the interval. */
  perform(cue: KHapticCue) {
    if (!this.enabledValue || !this.active || !this.vibrate) return;
    const now = this.now();
    if (now - this.last < this.minInterval) return;
    this.last = now;
    try {
      this.vibrate(kHapticPatterns[cue]);
    } catch {
      /* Haptics are supplementary; blocked vibration is silent. */
    }
  }
}
