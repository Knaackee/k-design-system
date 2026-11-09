import { useState } from "react";
import { KText } from "../primitives/text.js";

/** Keyed by source in the renderer so a changed source can load again. */
export function MarkdownImage({
  src,
  alt = "",
  title,
}: {
  src: string;
  alt?: string;
  title?: string;
}) {
  const [failed, setFailed] = useState(false);
  return failed ? (
    <KText as="span" variant="bodySmall" title={title}>
      {alt}
    </KText>
  ) : (
    <img
      src={src}
      alt={alt}
      title={title}
      loading="lazy"
      referrerPolicy="no-referrer"
      onError={() => setFailed(true)}
    />
  );
}
