import {
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  type SVGProps,
} from "react";
import { svgToIcon } from "morphicons/adapters";
import { canonicalD, createMorph, type Morph } from "morphicons/dom";
import {
  allocOutputs,
  buildPlan,
  interpPolar,
  resampleIcon,
  serialize,
} from "morphicons";
import { iconSvg, type KIconName } from "../generated/icons.js";

export type KAnimatedIconSpring = "smooth" | "snappy" | "bouncy";
export type KAnimatedIconReducedMotion = "user" | "always" | "never";

export interface KAnimatedIconProps extends Omit<
  SVGProps<SVGSVGElement>,
  "name" | "from" | "onAnimationStart" | "onAnimationEnd" | "strokeWidth"
> {
  /** Changing the destination animates from the current visible geometry. */
  name?: KIconName;
  /** Any stroke-based Lucide SVG. Takes precedence over name; parsed once per change. */
  svg?: string;
  /** Optional fixed source for externally controlled progress. */
  from?: KIconName;
  fromSvg?: string;
  /** Controlled progress, clamped to 0..1; omit to use the spring. */
  progress?: number;
  spring?: KAnimatedIconSpring;
  reducedMotion?: KAnimatedIconReducedMotion;
  size?: number;
  strokeWidth?: number;
  label?: string;
  onAnimationStart?: () => void;
  /** Fires after an automatic transition settles (also for an instant reduced-motion swap). */
  onAnimationEnd?: () => void;
}

const useClientLayoutEffect =
  typeof document === "undefined" ? useEffect : useLayoutEffect;

/** Lucide geometry with Morphicons physics; no icon-specific animation assets. */
export function KAnimatedIcon({
  name,
  svg,
  from,
  fromSvg,
  progress,
  spring = "snappy",
  reducedMotion = "user",
  size = 16,
  label,
  color = "currentColor",
  strokeWidth = 2,
  onAnimationStart,
  onAnimationEnd,
  style,
  ...props
}: KAnimatedIconProps) {
  if (!Number.isFinite(size) || size <= 0)
    throw new RangeError("KAnimatedIcon size must be positive and finite");
  if (!Number.isFinite(strokeWidth) || strokeWidth <= 0)
    throw new RangeError(
      "KAnimatedIcon strokeWidth must be positive and finite",
    );
  if (progress !== undefined && !Number.isFinite(progress))
    throw new RangeError("KAnimatedIcon progress must be finite");
  const markup = svg ?? (name ? iconSvg[name] : undefined);
  if (!markup) throw new Error("KAnimatedIcon requires name or svg");
  const target = useMemo(() => svgToIcon(markup), [markup]);
  const sourceMarkup = fromSvg ?? (from ? iconSvg[from] : undefined);
  const source = useMemo(
    () => (sourceMarkup ? svgToIcon(sourceMarkup) : undefined),
    [sourceMarkup],
  );
  const controlled = progress !== undefined;
  if (controlled && !source)
    throw new Error("Controlled KAnimatedIcon requires from or fromSvg");
  const t = Math.max(0, Math.min(1, progress ?? 1));
  const plan = useMemo(
    () =>
      controlled && source
        ? buildPlan(resampleIcon(source), resampleIcon(target))
        : undefined,
    [controlled, source, target],
  );
  const frozen = useMemo(() => {
    if (!plan || !source || t >= 1) return canonicalD(target);
    if (t <= 0) return canonicalD(source);
    const outputs = allocOutputs(plan);
    interpPolar(plan, t, outputs);
    return serialize(
      outputs,
      plan.items.map((item) => item.closed),
    );
  }, [plan, source, target, t]);
  const path = useRef<SVGPathElement>(null);
  const driver = useRef<Morph | null>(null);
  const previous = useRef(target);
  const resumeControlled = useRef(false);
  const endPath = useRef(canonicalD(target));
  const running = useRef(false);
  const callbacks = useRef({ onAnimationStart, onAnimationEnd });
  callbacks.current = { onAnimationStart, onAnimationEnd };
  // Keep React's initial attribute constant: the animation driver owns subsequent frames.
  const initial = useRef(frozen);

  useClientLayoutEffect(() => {
    if (!path.current) return;
    const element = path.current;
    driver.current = createMorph(
      {
        setAttribute(attribute, value) {
          element.setAttribute(attribute, value);
          if (running.current && value === endPath.current) {
            running.current = false;
            callbacks.current.onAnimationEnd?.();
          }
        },
      },
      target,
      { reducedMotion },
    );
    return () => {
      driver.current?.destroy();
      driver.current = null;
      running.current = false;
    };
    // The driver lives for this element's lifetime; later props are applied below.
  }, []);

  useClientLayoutEffect(() => {
    const animation = driver.current;
    if (!animation) return;
    animation.reducedMotion = reducedMotion;
    if (controlled && source) {
      running.current = false;
      animation.set(source);
      if (t >= 1) animation.set(target);
      else if (t > 0) animation.seek(target, t);
      previous.current = target;
      resumeControlled.current = t < 1;
    } else if (previous.current !== target || resumeControlled.current) {
      resumeControlled.current = false;
      previous.current = target;
      endPath.current = canonicalD(target);
      running.current = true;
      callbacks.current.onAnimationStart?.();
      animation.morphTo(target, spring);
    }
  }, [target, source, controlled, t, spring, reducedMotion]);

  return (
    <svg
      {...props}
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke={color}
      strokeWidth={strokeWidth}
      strokeLinecap="round"
      strokeLinejoin="round"
      role={label ? "img" : undefined}
      aria-label={label}
      aria-hidden={label ? undefined : true}
      style={{
        display: "inline-block",
        flexShrink: 0,
        verticalAlign: "middle",
        ...style,
      }}
    >
      {label ? <title>{label}</title> : null}
      <path ref={path} d={initial.current} />
    </svg>
  );
}
