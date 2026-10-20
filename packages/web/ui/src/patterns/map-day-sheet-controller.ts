import {
  useCallback,
  useEffect,
  useRef,
  useState,
  type RefObject,
} from "react";

export type KMapDayPanelState = 0 | 1 | 2;

type SheetBinding = {
  getIsSheet: () => boolean;
  getFraction: () => number;
  getState: () => KMapDayPanelState | null;
  animateTo: (fraction: number) => Promise<void>;
  snapTo: (state: KMapDayPanelState) => Promise<void>;
};

/** Imperative position control for the mobile KMapDayView sheet. */
export class KMapDaySheetController {
  #binding: SheetBinding | null = null;

  get isAttached() {
    return this.#binding !== null;
  }

  get isSheet() {
    return this.#binding?.getIsSheet() ?? false;
  }

  get fraction() {
    return this.#binding?.getFraction() ?? 0;
  }

  /** Non-null only while the actual sheet position exactly matches a snap. */
  get state() {
    return this.#binding?.getState() ?? null;
  }

  animateTo(fraction: number) {
    if (!Number.isFinite(fraction) || fraction < 0 || fraction > 1)
      return Promise.reject(
        new RangeError("Sheet fraction must be finite and within 0–1."),
      );
    return this.#binding?.animateTo(fraction) ?? Promise.resolve();
  }

  snapTo(state: KMapDayPanelState) {
    if (state !== 0 && state !== 1 && state !== 2)
      return Promise.reject(new RangeError("Sheet state must be 0, 1, or 2."));
    return this.#binding?.snapTo(state) ?? Promise.resolve();
  }

  /** @internal KMapDayView owns controller attachment. */
  _attach(binding: SheetBinding) {
    if (this.#binding && this.#binding !== binding)
      throw new Error("KMapDaySheetController is already attached.");
    this.#binding = binding;
    return () => {
      if (this.#binding === binding) this.#binding = null;
    };
  }
}

type SheetOptions = {
  root: RefObject<HTMLDivElement | null>;
  presentation: "auto" | "sidebar" | "sheet";
  snap: KMapDayPanelState;
  heights: readonly [number, number, number];
  controller?: KMapDaySheetController;
  onSnapChange: (state: KMapDayPanelState) => void;
  onFractionChanged?: (fraction: number) => void;
};

const parseDuration = (value: string) => {
  const duration = Number.parseFloat(value);
  if (!Number.isFinite(duration)) return 0;
  return value.trim().endsWith("ms") ? duration : duration * 1000;
};

/** @internal Shared sheet geometry and motion for KMapDayView. */
export function useKMapDaySheet({
  root,
  presentation,
  snap,
  heights,
  controller,
  onSnapChange,
  onFractionChanged,
}: SheetOptions) {
  const [compact, medium, expanded] = heights;
  const [isSheet, setIsSheet] = useState(presentation === "sheet");
  const [viewportHeight, setViewportHeight] = useState(0);
  const [fractionValue, setFractionValue] = useState(heights[snap] / 100);
  const [moving, setMoving] = useState(false);
  const fraction = useRef(fractionValue);
  const animation = useRef(0);
  const animationResolve = useRef<(() => void) | null>(null);
  const drag = useRef<{ y: number; fraction: number } | null>(null);
  const fractionChanged = useRef(onFractionChanged);
  fractionChanged.current = onFractionChanged;
  const snapChanged = useRef(onSnapChange);
  snapChanged.current = onSnapChange;

  const clamp = useCallback(
    (value: number) =>
      Math.max(
        Math.max(compact / 100, viewportHeight ? 230 / viewportHeight : 0),
        Math.min(expanded / 100, value),
      ),
    [compact, expanded, viewportHeight],
  );
  const publish = useCallback(
    (value: number) => {
      const next = clamp(value);
      fraction.current = next;
      setFractionValue(next);
      fractionChanged.current?.(next);
    },
    [clamp],
  );
  const stateForFraction = useCallback(
    (value: number): KMapDayPanelState | null => {
      const index = [compact, medium, expanded].findIndex(
        (height) => Math.abs(clamp(height / 100) - value) < 1e-6,
      );
      return index < 0 ? null : (index as KMapDayPanelState);
    },
    [clamp, compact, expanded, medium],
  );
  const stopAnimation = useCallback(() => {
    cancelAnimationFrame(animation.current);
    animation.current = 0;
    animationResolve.current?.();
    animationResolve.current = null;
    setMoving(false);
  }, []);
  const animateTo = useCallback(
    (requested: number) => {
      if (!isSheet) return Promise.resolve();
      stopAnimation();
      const target = clamp(requested);
      const from = fraction.current;
      const reduceMotion = matchMedia(
        "(prefers-reduced-motion: reduce)",
      ).matches;
      const duration = root.current
        ? parseDuration(
            getComputedStyle(root.current).getPropertyValue(
              "--k-motion-standard",
            ),
          )
        : 0;
      if (reduceMotion || duration === 0 || Math.abs(from - target) < 1e-6) {
        publish(target);
        return Promise.resolve();
      }
      setMoving(true);
      return new Promise<void>((resolve) => {
        animationResolve.current = resolve;
        const started = performance.now();
        const frame = (now: number) => {
          const progress = Math.min(1, (now - started) / duration);
          const eased = 1 - (1 - progress) ** 3;
          publish(from + (target - from) * eased);
          if (progress < 1) animation.current = requestAnimationFrame(frame);
          else {
            animation.current = 0;
            animationResolve.current = null;
            setMoving(false);
            resolve();
          }
        };
        animation.current = requestAnimationFrame(frame);
      });
    },
    [clamp, isSheet, publish, root, stopAnimation],
  );
  const snapTo = useCallback(
    (state: KMapDayPanelState) => {
      if (!isSheet) return Promise.resolve();
      snapChanged.current(state);
      return animateTo([compact, medium, expanded][state]! / 100);
    },
    [animateTo, compact, expanded, isSheet, medium],
  );

  useEffect(() => {
    const element = root.current;
    if (!element) return;
    const update = () => {
      setViewportHeight(element.clientHeight);
      setIsSheet(
        presentation === "sheet" ||
          (presentation === "auto" && element.clientWidth <= 700),
      );
    };
    update();
    const observer = new ResizeObserver(update);
    observer.observe(element);
    return () => observer.disconnect();
  }, [presentation, root]);
  useEffect(() => {
    if (!isSheet) return;
    const target = [compact, medium, expanded][snap]! / 100;
    if (stateForFraction(fraction.current) !== snap) publish(target);
  }, [compact, expanded, isSheet, medium, publish, snap, stateForFraction]);
  useEffect(() => {
    if (!controller) return;
    return controller._attach({
      getIsSheet: () => isSheet,
      getFraction: () => fraction.current,
      getState: () => stateForFraction(fraction.current),
      animateTo,
      snapTo,
    });
  }, [animateTo, controller, snapTo, stateForFraction]);
  useEffect(
    () => () => {
      cancelAnimationFrame(animation.current);
      animationResolve.current?.();
      animationResolve.current = null;
    },
    [],
  );

  return {
    fraction: fractionValue,
    state: stateForFraction(fractionValue),
    isSheet,
    moving,
    snapTo,
    startDrag(clientY: number) {
      if (!isSheet) return;
      stopAnimation();
      setMoving(true);
      drag.current = { y: clientY, fraction: fraction.current };
    },
    dragTo(clientY: number) {
      if (!drag.current || !root.current) return;
      publish(
        drag.current.fraction +
          (drag.current.y - clientY) / root.current.clientHeight,
      );
    },
    finishDrag() {
      if (!drag.current) return;
      drag.current = null;
      setMoving(false);
      const values = [compact, medium, expanded];
      const nearest = values.reduce(
        (best, height, index) =>
          Math.abs(clamp(height / 100) - fraction.current) <
          Math.abs(clamp(values[best]! / 100) - fraction.current)
            ? index
            : best,
        0,
      ) as KMapDayPanelState;
      void snapTo(nearest);
    },
    cancelDrag() {
      drag.current = null;
      setMoving(false);
      void animateTo([compact, medium, expanded][snap]! / 100);
    },
  };
}
