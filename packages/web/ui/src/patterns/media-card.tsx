import type { ReactNode } from "react";
import { KCard, type KCardProps } from "../primitives/card.js";

export interface KMediaCardProps extends KCardProps {
  /** Image, map, video or any other host-owned visual. */
  media: ReactNode;
  /** Responsive moves media to the left in a wide container. */
  mediaPlacement?: "top" | "responsive";
  mediaOverlay?: ReactNode;
}

/** One rounded boundary, edge-to-edge media and exactly one content inset. */
export function KMediaCard({
  media,
  mediaOverlay,
  mediaPlacement = "top",
  children,
  className,
  ...props
}: KMediaCardProps) {
  return (
    <KCard
      {...props}
      className={["k-media-card", className].filter(Boolean).join(" ")}
    >
      <div className="k-media-card__layout" data-placement={mediaPlacement}>
        <div className="k-media-card__media">
          {media}
          {mediaOverlay && (
            <div className="k-media-card__overlay">{mediaOverlay}</div>
          )}
        </div>
        <div className="k-media-card__body">{children}</div>
      </div>
    </KCard>
  );
}
