import { useMemo } from "react";
import QRCode from "qrcode";
import { KStack } from "../primitives/layout.js";
import { KText } from "../primitives/text.js";

export type KQrCodeVariant = "classic" | "soft" | "portrait" | "card";
export type KQrCodeModuleShape = "square" | "rounded" | "dots" | "fluid";
export type KQrCodeEyeShape = "square" | "rounded" | "circle";
export interface KQrCodeProps {
  eyeShape?: KQrCodeEyeShape;
  moduleShape?: KQrCodeModuleShape;
  data: string;
  variant?: KQrCodeVariant;
  size?: number;
  /** A dark six-digit hex color. Light colors are darkened for scanning. */
  color?: string;
  imageUrl?: string;
  label: string;
  title?: string;
  caption?: string;
}

/** Keep a light, opaque quiet zone even in dark themes. */
export function qrInk(color: string): string {
  if (!/^#[0-9a-f]{6}$/i.test(color)) return "#18181b";
  const rgb = [1, 3, 5].map((offset) =>
    parseInt(color.slice(offset, offset + 2), 16),
  );
  const max = Math.max(...rgb);
  const scale = max > 150 ? 150 / max : 1;
  return `#${rgb
    .map((channel) =>
      Math.round(channel * scale)
        .toString(16)
        .padStart(2, "0"),
    )
    .join("")}`;
}

export function KQrCode({
  data,
  variant = "classic",
  size = 240,
  moduleShape,
  eyeShape = "square",
  color = "#18181b",
  imageUrl,
  label,
  title,
  caption,
}: KQrCodeProps) {
  const result = useMemo(() => {
    try {
      return QRCode.create(data, { errorCorrectionLevel: "H" }).modules;
    } catch {
      return null;
    }
  }, [data]);
  if (!result)
    return (
      <span role="img" aria-label={label}>
        —
      </span>
    );
  const count = result.size;
  const extent = count + 8;
  const ink = qrInk(color);
  const shape = moduleShape ?? (variant === "classic" ? "square" : "rounded");
  const portrait = variant === "portrait" && imageUrl;
  const centerSize = count * 0.16;
  return (
    <KStack
      align="center"
      gap="control"
      style={{ width: size, maxWidth: "100%" }}
    >
      {variant === "card" && imageUrl && (
        <img
          src={imageUrl}
          alt=""
          style={{
            width: size * 0.22,
            height: size * 0.22,
            borderRadius: "50%",
            objectFit: "cover",
          }}
        />
      )}
      {variant === "card" && title && <KText variant="heading3">{title}</KText>}
      <div style={{ position: "relative", width: "100%", aspectRatio: "1" }}>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          role="img"
          aria-label={label}
          viewBox={`0 0 ${extent} ${extent}`}
          style={{ display: "block", width: "100%", height: "100%" }}
        >
          <rect width={extent} height={extent} fill="#ffffff" />
          {Array.from({ length: count * count }, (_, i) => {
            const x = i % count;
            const y = Math.floor(i / count);
            if (!result.get(y, x)) return null;
            const finderArea =
              (x < 8 && y < 8) ||
              (x >= count - 8 && y < 8) ||
              (x < 8 && y >= count - 8);
            if (finderArea && eyeShape !== "square") return null;
            const finder = finderArea || !!result.isReserved(y, x);
            if (shape === "fluid" && !finder) {
              const dark = (dx: number, dy: number) =>
                x + dx >= 0 &&
                y + dy >= 0 &&
                x + dx < count &&
                y + dy < count &&
                result.get(y + dy, x + dx);
              const tl = !dark(-1, 0) && !dark(0, -1) ? 0.5 : 0;
              const tr = !dark(1, 0) && !dark(0, -1) ? 0.5 : 0;
              const br = !dark(1, 0) && !dark(0, 1) ? 0.5 : 0;
              const bl = !dark(-1, 0) && !dark(0, 1) ? 0.5 : 0;
              return (
                <path
                  key={i}
                  transform={`translate(${x + 4} ${y + 4})`}
                  fill={ink}
                  d={`M ${tl} 0 H ${1 - tr} Q 1 0 1 ${tr} V ${1 - br} Q 1 1 ${1 - br} 1 H ${bl} Q 0 1 0 ${1 - bl} V ${tl} Q 0 0 ${tl} 0 Z`}
                />
              );
            }
            return (
              <rect
                key={i}
                x={x + 4}
                y={y + 4}
                width={1}
                height={1}
                rx={
                  finder || shape === "square"
                    ? 0
                    : shape === "dots"
                      ? 0.5
                      : 0.35
                }
                fill={ink}
              />
            );
          })}
          {eyeShape !== "square" &&
            [
              [4, 4],
              [count - 3, 4],
              [4, count - 3],
            ].map(([x, y]) => (
              <g key={`${x}-${y}`} transform={`translate(${x} ${y})`}>
                {[
                  { offset: 0, size: 7, fill: ink },
                  { offset: 1, size: 5, fill: "#ffffff" },
                  { offset: 2, size: 3, fill: ink },
                ].map(({ offset, size, fill }) =>
                  eyeShape === "circle" ? (
                    <circle
                      key={offset}
                      cx={3.5}
                      cy={3.5}
                      r={size / 2}
                      fill={fill}
                    />
                  ) : (
                    <rect
                      key={offset}
                      x={offset}
                      y={offset}
                      width={size}
                      height={size}
                      rx={size * 0.25}
                      fill={fill}
                    />
                  ),
                )}
              </g>
            ))}
        </svg>
        {portrait && (
          <img
            src={imageUrl}
            onError={(event) => {
              event.currentTarget.style.display = "none";
            }}
            alt=""
            style={{
              position: "absolute",
              left: "50%",
              top: "50%",
              transform: "translate(-50%, -50%)",
              width: `${(centerSize / extent) * 100}%`,
              height: `${(centerSize / extent) * 100}%`,
              borderRadius: "50%",
              objectFit: "cover",
              border: `${(size / extent) * 0.6}px solid white`,
              background: "white",
            }}
          />
        )}
      </div>
      {variant === "card" && caption && <KText variant="body">{caption}</KText>}
    </KStack>
  );
}
