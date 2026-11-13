import { useRef, type ReactNode } from "react";
import { KCard } from "../primitives/card.js";
import { KButton } from "../primitives/button.js";
import { KIconButton } from "../actions/icon-button.js";
import { KIcon, type KIconName } from "../primitives/icon.js";
import { KPresentationPicture } from "./presentation-picture.js";

export interface KPresentationCardProps {
  title: string;
  description?: string;
  eyebrow?: string;
  image?: { src: string; alt: string; fit?: "cover" | "contain" };
  variant?: "standard" | "cover";
  action?: { label: string; onClick: () => void };
}
/** Presentation only: navigation and content permissions belong to the consumer. */
export function KPresentationCard({
  title,
  description,
  eyebrow,
  image,
  variant = "standard",
  action,
}: KPresentationCardProps) {
  return (
    <KCard
      className={`k-presentation k-presentation-card k-presentation-card--${variant}`}
    >
      {image && (
        <KPresentationPicture
          className="k-presentation-card__image"
          src={image.src}
          alt={image.alt}
          style={{ objectFit: image.fit ?? "cover" }}
        />
      )}
      <div className="k-presentation-card__body">
        <div className="k-presentation-card__content">
          {eyebrow && <span className="k-presentation__meta">{eyebrow}</span>}
          <h3>{title}</h3>
          {description && <p>{description}</p>}
        </div>
        {action &&
          (variant === "standard" ? (
            <KIconButton
              icon="arrow-up-right"
              label={action.label}
              onClick={action.onClick}
            />
          ) : (
            <KButton variant="secondary" onClick={action.onClick}>
              {action.label}
              <KIcon name="arrow-up-right" />
            </KButton>
          ))}
      </div>
    </KCard>
  );
}

export interface KPresentationReferenceProps {
  title: string;
  metadata: string;
  icon?: KIconName;
  image?: string;
  onOpen: () => void;
}
export function KPresentationReference({
  title,
  metadata,
  icon = "file-text",
  image,
  onOpen,
}: KPresentationReferenceProps) {
  return (
    <button
      type="button"
      className="k-presentation k-presentation-reference"
      onClick={onOpen}
    >
      <span className="k-presentation-reference__symbol">
        {image ? (
          <KPresentationPicture
            src={image}
            alt=""
            style={{ objectFit: "contain" }}
          />
        ) : (
          <KIcon name={icon} size={20} />
        )}
      </span>
      <span className="k-presentation-reference__text">
        <strong>{title}</strong>
        <span className="k-presentation__meta">{metadata}</span>
      </span>
      <KIcon name="arrow-up-right" />
    </button>
  );
}

export function KPresentationCollection({
  children,
  label,
  layout = "carousel",
}: {
  children: ReactNode;
  label: string;
  layout?: "carousel" | "list";
}) {
  const track = useRef<HTMLDivElement>(null);
  function move(direction: number) {
    track.current?.scrollBy({
      left: direction * track.current.clientWidth * 0.8,
      behavior: matchMedia("(prefers-reduced-motion: reduce)").matches
        ? "instant"
        : "smooth",
    });
  }
  return (
    <section className="k-presentation-collection" aria-label={label}>
      <header>
        <strong>{label}</strong>
        {layout === "carousel" && (
          <span className="k-presentation-collection__controls">
            <KButton
              variant="ghost"
              aria-label="Vorherige Karten"
              onClick={() => move(-1)}
            >
              <KIcon name="chevron-left" />
            </KButton>
            <KButton
              variant="ghost"
              aria-label="Weitere Karten"
              onClick={() => move(1)}
            >
              <KIcon name="chevron-right" />
            </KButton>
          </span>
        )}
      </header>
      <div
        ref={track}
        className={`k-presentation-collection__${layout}`}
        tabIndex={layout === "carousel" ? 0 : undefined}
      >
        {children}
      </div>
    </section>
  );
}

export interface KPresentationParty {
  name: string;
  image?: string;
  detail?: string;
}
export function KPresentationComparison({
  label,
  left,
  right,
  value,
  detail,
}: {
  label: string;
  left: KPresentationParty;
  right: KPresentationParty;
  value: string;
  detail?: string;
}) {
  const party = (item: KPresentationParty) => (
    <div className="k-presentation-comparison__party">
      {item.image && <KPresentationPicture src={item.image} alt={item.name} />}
      <strong>{item.name}</strong>
      {item.detail && <small>{item.detail}</small>}
    </div>
  );
  return (
    <KCard className="k-presentation k-presentation-comparison">
      <span className="k-presentation__meta">{label}</span>
      <div className="k-presentation-comparison__row">
        {party(left)}
        <div className="k-presentation-comparison__score">
          <strong>{value}</strong>
        </div>
        {party(right)}
      </div>
      {detail && (
        <small className="k-presentation-comparison__detail">{detail}</small>
      )}
    </KCard>
  );
}

export function KPresentationMetrics({
  label,
  value,
  description,
  icon,
  metrics,
}: {
  label: string;
  value: string;
  description?: string;
  icon?: KIconName;
  metrics: { label: string; value: string }[];
}) {
  return (
    <KCard className="k-presentation k-presentation-metrics">
      <span className="k-presentation__meta">{label}</span>
      <div className="k-presentation-metrics__primary">
        <strong>{value}</strong>
        {icon && <KIcon name={icon} size={32} />}
      </div>
      {description && <p>{description}</p>}
      <dl>
        {metrics.map((item) => (
          <div key={item.label}>
            <dt>{item.label}</dt>
            <dd>{item.value}</dd>
          </div>
        ))}
      </dl>
    </KCard>
  );
}

export function KPresentationTimeline({
  label,
  stops,
}: {
  label: string;
  stops: {
    id: string;
    title: string;
    time: string;
    description?: string;
    current?: boolean;
  }[];
}) {
  return (
    <KCard className="k-presentation k-presentation-timeline">
      <span className="k-presentation__meta">{label}</span>
      <ol>
        {stops.map((stop) => (
          <li key={stop.id} aria-current={stop.current ? "step" : undefined}>
            <span className="k-presentation-timeline__dot" />
            <time>{stop.time}</time>
            <div>
              <strong>{stop.title}</strong>
              {stop.description && <p>{stop.description}</p>}
            </div>
          </li>
        ))}
      </ol>
    </KCard>
  );
}
