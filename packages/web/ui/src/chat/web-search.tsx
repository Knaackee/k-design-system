import {
  useEffect,
  useRef,
  useState,
  type HTMLAttributes,
  type ReactNode,
} from "react";
import { KAvatar } from "../basic-components.js";
import { KDisclosure } from "../primitives/disclosure.js";
import { KIcon } from "../primitives/icon.js";
import { KAnimatedIcon } from "../primitives/animated-icon.js";

export interface KWebSearchResult {
  id: string;
  url: string;
  title: string;
  description?: string;
  faviconUrl?: string;
}

export interface KWebSearchData {
  id: string;
  query?: string;
  state: "running" | "succeeded" | "failed";
  results: readonly KWebSearchResult[];
  error?: string;
}

export interface KWebSearchLabels {
  title: string;
  running: string;
  empty: string;
  failed: string;
  sourceCount: (count: number) => string;
}

export interface KWebSearchProps extends Omit<
  HTMLAttributes<HTMLElement>,
  "children"
> {
  data: KWebSearchData;
  labels: KWebSearchLabels;
  expanded?: boolean;
  defaultExpanded?: boolean;
  onExpandedChange?: (expanded: boolean) => void;
  onSourceActivate?: (source: KWebSearchResult) => void;
  renderFavicon?: (source: KWebSearchResult) => ReactNode;
  loadingIndicator?: "shimmer" | "animated-icon";
}

function SearchLoadingIcon() {
  const [progressIcon, setProgressIcon] = useState(false);
  const host = useRef<HTMLSpanElement>(null);
  useEffect(() => {
    const preference = window.matchMedia("(prefers-reduced-motion: reduce)");
    let timer: ReturnType<typeof setInterval> | undefined;
    const sync = () => {
      if (timer !== undefined) clearInterval(timer);
      setProgressIcon(false);
      if (preference.matches) return;
      const duration = host.current
        ? getComputedStyle(host.current)
            .getPropertyValue("--k-motion-skeleton")
            .trim()
        : "";
      const parsed = Number.parseFloat(duration);
      const milliseconds = duration.endsWith("ms") ? parsed : parsed * 1000;
      timer = setInterval(
        () => setProgressIcon((current) => !current),
        Number.isFinite(milliseconds) && milliseconds > 0 ? milliseconds : 1400,
      );
    };
    sync();
    preference.addEventListener("change", sync);
    return () => {
      if (timer !== undefined) clearInterval(timer);
      preference.removeEventListener("change", sync);
    };
  }, []);
  return (
    <span ref={host} className="k-web-search__search-icon" aria-hidden="true">
      <KAnimatedIcon
        name={progressIcon ? "loader-circle" : "search"}
        size={16}
        reducedMotion="user"
      />
    </span>
  );
}

function sourceDomain(url: string) {
  try {
    return new URL(url).hostname.replace(/^www\./, "");
  } catch {
    return url;
  }
}

// Only absolute HTTP(S) sources can navigate. The consumer owns custom activation.
function sourceHref(url: string) {
  try {
    const parsed = new URL(url);
    return ["http:", "https:"].includes(parsed.protocol)
      ? parsed.href
      : undefined;
  } catch {
    return undefined;
  }
}

export function KWebSearch({
  data,
  labels,
  expanded,
  defaultExpanded,
  onExpandedChange,
  onSourceActivate,
  renderFavicon,
  loadingIndicator = "shimmer",
  className,
  ...props
}: KWebSearchProps) {
  const status =
    data.state === "running" && data.results.length === 0
      ? labels.running
      : data.state === "failed"
        ? labels.failed
        : labels.sourceCount(data.results.length);
  const favicon = (source: KWebSearchResult) =>
    renderFavicon?.(source) ?? (
      <KAvatar
        className="k-web-search__favicon"
        size="small"
        src={source.faviconUrl}
        alt=""
        fallback={<KIcon name="globe" size={14} />}
      />
    );
  return (
    <KDisclosure
      {...props}
      id={props.id ?? data.id}
      className={["k-web-search", className].filter(Boolean).join(" ")}
      data-state={data.state}
      data-loading-indicator={loadingIndicator}
      title={labels.title}
      open={expanded}
      defaultOpen={defaultExpanded}
      onOpenChange={onExpandedChange}
      leadingIcon={
        data.state === "running" && loadingIndicator === "animated-icon" ? (
          <SearchLoadingIcon />
        ) : (
          <KIcon
            name="search"
            size={16}
            className="k-web-search__search-icon"
          />
        )
      }
      titleIcon={
        <span className="k-web-search__header-detail">
          {data.query ? (
            <span className="k-web-search__query">{data.query}</span>
          ) : null}
          <span className="k-web-search__summary" role="status">
            {data.results.length > 0 ? (
              <span className="k-web-search__favicon-stack" aria-hidden="true">
                {data.results.slice(0, 3).map((source) => (
                  <span key={source.id}>{favicon(source)}</span>
                ))}
              </span>
            ) : null}
            <span>{status}</span>
          </span>
          <KIcon
            name="chevron-right"
            size={16}
            className="k-web-search__chevron"
          />
        </span>
      }
    >
      {data.results.length > 0 ? (
        <ul className="k-web-search__sources">
          {data.results.map((source) => {
            const content = (
              <>
                {favicon(source)}
                <span className="k-web-search__source-text">
                  <span className="k-web-search__source-title">
                    {source.title}
                  </span>
                  <span className="k-web-search__domain">
                    {sourceDomain(source.url)}
                  </span>
                  {source.description ? (
                    <span className="k-web-search__description">
                      {source.description}
                    </span>
                  ) : null}
                </span>
              </>
            );
            return (
              <li key={source.id}>
                {onSourceActivate ? (
                  <button
                    className="k-web-search__source"
                    type="button"
                    onClick={() => onSourceActivate(source)}
                  >
                    {content}
                  </button>
                ) : (
                  <a
                    className="k-web-search__source"
                    href={sourceHref(source.url)}
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    {content}
                  </a>
                )}
              </li>
            );
          })}
        </ul>
      ) : null}
      {data.state === "failed" || !data.results.length ? (
        <p className="k-web-search__status" role="status">
          {data.state === "running"
            ? labels.running
            : data.state === "failed"
              ? (data.error ?? labels.failed)
              : labels.empty}
        </p>
      ) : null}
    </KDisclosure>
  );
}
