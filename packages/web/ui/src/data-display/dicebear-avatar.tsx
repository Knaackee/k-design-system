import { Avatar, type Style, type StyleOptions } from "@dicebear/core";
import { useEffect, useMemo, useRef } from "react";
import { KAvatar, type KAvatarProps } from "../basic-components.js";

export interface KDiceBearAvatarProps<D = unknown> extends Omit<
  KAvatarProps,
  "src" | "style"
> {
  avatarStyle: Style<D>;
  seed: string;
  options?: Omit<StyleOptions<D>, "seed" | "idRandomization">;
  style?: KAvatarProps["style"];
  /** Freeze or resume the current animation without regenerating the artwork. */
  motionPaused?: boolean;
}

/** Locally rendered, deterministic DiceBear artwork in the standard KAvatar frame. */
export function KDiceBearAvatar<D = unknown>({
  avatarStyle,
  seed,
  options,
  motionPaused = false,
  ...props
}: KDiceBearAvatarProps<D>) {
  const svg = useMemo(
    () =>
      new Avatar(avatarStyle, {
        ...options,
        seed,
        idRandomization: false,
      }).toString(),
    [avatarStyle, seed, options],
  );
  const animated = svg.includes("@keyframes");
  return animated ? (
    <KAvatar
      {...props}
      role={props.role ?? "img"}
      aria-label={props["aria-label"] ?? props.alt}
      fallback={<AnimatedArtwork svg={svg} paused={motionPaused} />}
    />
  ) : (
    <KAvatar
      {...props}
      src={`data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`}
    />
  );
}

/** Shadow DOM isolates each avatar's SVG IDs, CSS variables and keyframes. */
function AnimatedArtwork({ svg, paused }: { svg: string; paused: boolean }) {
  const host = useRef<HTMLSpanElement>(null);
  const pausedRef = useRef(paused);
  pausedRef.current = paused;
  useEffect(() => {
    const element = host.current;
    if (!element) return;
    const root = element.shadowRoot ?? element.attachShadow({ mode: "open" });
    const parsed = new DOMParser().parseFromString(svg, "image/svg+xml");
    // Definitions may be supplied by consumers. Allow artwork, never active content.
    parsed
      .querySelectorAll("script, foreignObject, iframe, object, embed")
      .forEach((node) => node.remove());
    parsed.querySelectorAll("*").forEach((node) => {
      for (const attribute of [...node.attributes]) {
        if (
          /^on/i.test(attribute.name) ||
          (/(^|:)href$/.test(attribute.name) &&
            !attribute.value.startsWith("#"))
        ) {
          node.removeAttribute(attribute.name);
        }
      }
    });
    const artwork = document.importNode(parsed.documentElement, true);
    artwork.setAttribute("width", "100%");
    artwork.setAttribute("height", "100%");
    root.replaceChildren(artwork);
    const frame = requestAnimationFrame(() => {
      for (const animation of artwork.getAnimations({ subtree: true })) {
        if (pausedRef.current) animation.pause();
      }
    });
    return () => {
      cancelAnimationFrame(frame);
      root.replaceChildren();
    };
  }, [svg]);
  useEffect(() => {
    const artwork = host.current?.shadowRoot?.querySelector("svg");
    for (const animation of artwork?.getAnimations({ subtree: true }) ?? []) {
      if (paused) animation.pause();
      else animation.play();
    }
  }, [paused]);
  return (
    <span
      ref={host}
      aria-hidden="true"
      style={{ width: "100%", height: "100%", display: "block" }}
    />
  );
}
