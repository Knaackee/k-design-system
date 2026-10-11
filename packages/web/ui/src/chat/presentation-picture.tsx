import { useState, type ImgHTMLAttributes } from "react";
import { KIcon } from "../primitives/icon.js";

/** Keeps the reserved media area stable when a source expires or fails. */
export function KPresentationPicture({
  src,
  alt = "",
  className,
  style,
  ...props
}: ImgHTMLAttributes<HTMLImageElement>) {
  const [failedSource, setFailedSource] = useState<string>();
  if (src && failedSource === src)
    return (
      <span
        data-image-unavailable="true"
        className={className}
        style={style}
        role="img"
        aria-label={alt || "Image unavailable"}
      >
        <KIcon name="image-off" />
      </span>
    );
  return (
    <img
      {...props}
      src={src}
      alt={alt}
      className={className}
      style={style}
      loading="lazy"
      referrerPolicy="no-referrer"
      onError={() => setFailedSource(src)}
    />
  );
}
