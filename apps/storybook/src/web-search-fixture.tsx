import { useState } from "react";
import { KAvatar } from "@k-design-system/ui";
import {
  KWebSearch,
  type KWebSearchData,
  type KWebSearchLabels,
  type KWebSearchResult,
} from "../../../packages/web/ui/src/chat/web-search.js";

export type WebSearchFixtureVariant =
  "review" | "running" | "animated-loading" | "empty" | "error" | "mobile";

// Embedded site marks keep gallery rendering deterministic and offline.
function siteMark(letter: string, color: string) {
  return `data:image/svg+xml,${encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><rect width="24" height="24" rx="5" fill="${color}"/><text x="12" y="17" text-anchor="middle" font-family="sans-serif" font-size="16" font-weight="700" fill="white">${letter}</text></svg>`)}`;
}

export const webSearchSources: readonly KWebSearchResult[] = [
  {
    id: "flutter",
    url: "https://docs.flutter.dev/ui/animations",
    title: "Flutter: Animationen und interaktive Oberflächen",
    description:
      "Offizielle Dokumentation zu Animationen, Übergängen und responsiven Oberflächen in Flutter.",
    faviconUrl: siteMark("F", "#027DFD"),
  },
  {
    id: "rive",
    url: "https://rive.app/docs/",
    title:
      "Rive: State Machines für interaktive Animationen in Web und Flutter",
    description:
      "Animationen mit Zustandsmaschinen verbinden und auf Benutzereingaben reagieren.",
    faviconUrl: siteMark("R", "#171717"),
  },
  {
    id: "foley",
    url: "https://usefoley.dev/",
    title: "Foley: Soundeffekte für interaktive Oberflächen",
    description: "Soundeffekte für interaktive Oberflächen.",
    faviconUrl: siteMark("F", "#7860C5"),
  },
];

const labels: KWebSearchLabels = {
  title: "Websuche",
  running: "Suche läuft…",
  empty: "Keine Quellen gefunden.",
  failed: "Suche fehlgeschlagen",
  sourceCount: (count) => `${count} ${count === 1 ? "Quelle" : "Quellen"}`,
};

export function WebSearchFixture({
  variant = "review",
}: {
  variant?: WebSearchFixtureVariant;
}) {
  const [expanded, setExpanded] = useState(variant === "mobile");
  const data: KWebSearchData = {
    id: `web-search-${variant}`,
    query: "Interaktive Oberflächen",
    state:
      variant === "running" || variant === "animated-loading"
        ? "running"
        : variant === "error"
          ? "failed"
          : "succeeded",
    results: ["running", "animated-loading", "empty", "error"].includes(variant)
      ? []
      : webSearchSources,
    error:
      variant === "error"
        ? "Die Suche konnte nicht abgeschlossen werden. Bitte später erneut versuchen."
        : undefined,
  };
  return (
    <div
      style={{
        width: "100%",
        minWidth: 0,
        maxWidth: variant === "mobile" ? 360 : 640,
        margin: "auto",
        padding: "var(--k-space-layout-gutter)",
        boxSizing: "border-box",
        fontFamily: "var(--k-font-family)",
        fontSize: "var(--k-font-body-size)",
        lineHeight: "var(--k-font-body-line-height)",
        color: "var(--k-color-text-primary)",
      }}
    >
      <p style={{ margin: "0 0 var(--k-space-control-gap)" }}>
        Hier sind die gefundenen Quellen.
      </p>
      <KWebSearch
        data={data}
        labels={labels}
        loadingIndicator={
          variant === "animated-loading" ? "animated-icon" : "shimmer"
        }
        expanded={expanded}
        onExpandedChange={setExpanded}
        renderFavicon={(source) => (
          <KAvatar
            className="k-web-search__favicon"
            src={source.faviconUrl}
            alt=""
            size="small"
          />
        )}
      />
      {data.state === "running" ? (
        <div style={{ marginTop: "var(--k-space-layout-section-gap)" }}>
          <KWebSearch
            data={{
              ...data,
              id: `${data.id}-with-sources`,
              state: "succeeded",
              results: webSearchSources,
            }}
            labels={labels}
          />
        </div>
      ) : null}
      {data.state === "succeeded" && data.results.length > 0 ? (
        <p style={{ margin: "var(--k-space-control-gap) 0 0" }}>
          Du kannst die Quellen aufklappen und die jeweiligen Websites öffnen.
        </p>
      ) : null}
    </div>
  );
}
