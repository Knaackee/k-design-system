import { useId, type HTMLAttributes, type ReactNode } from "react";

import { KBadge } from "../basic-components.js";
import { KSearchField } from "../forms/input.js";
import { KButton } from "../primitives/button.js";
import { KText } from "../primitives/text.js";

export type KIntegrationConnectionState =
  "disconnected" | "pending" | "connected" | "error" | "unavailable";

export interface KIntegrationItem {
  id: string;
  name: string;
  description: ReactNode;
  category: string;
  icon: ReactNode;
  state?: KIntegrationConnectionState;
  availabilityLabel?: ReactNode;
  accountLabel?: ReactNode;
}

export interface KIntegrationCategory {
  id: string;
  label: ReactNode;
}

export interface KIntegrationMarketplaceLabels {
  title?: ReactNode;
  description?: ReactNode;
  searchPlaceholder?: string;
  filtersLabel?: string;
  connectedTitle?: ReactNode;
  catalogTitle?: ReactNode;
  emptyLabel?: ReactNode;
  connectLabel?: ReactNode;
  disconnectLabel?: ReactNode;
  retryLabel?: ReactNode;
  disconnectedLabel?: ReactNode;
  pendingLabel?: ReactNode;
  connectedLabel?: ReactNode;
  errorLabel?: ReactNode;
  unavailableLabel?: ReactNode;
}

export interface KIntegrationMarketplaceProps extends Omit<
  HTMLAttributes<HTMLElement>,
  "title" | "onChange"
> {
  integrations: readonly KIntegrationItem[];
  categories: readonly KIntegrationCategory[];
  activeCategory: string;
  searchValue: string;
  labels?: KIntegrationMarketplaceLabels;
  onCategoryChange: (category: string) => void;
  onSearchChange: (value: string) => void;
  onConnect: (integration: KIntegrationItem) => void;
  onDisconnect?: (integration: KIntegrationItem) => void;
  renderPanel?: (integration: KIntegrationItem) => ReactNode;
  activeIntegrationId?: string;
}

const defaultMarketplaceLabels: Required<KIntegrationMarketplaceLabels> = {
  title: "Integrationen",
  description:
    "Verbinde Werkzeuge und bestimme, welche Inhalte verwendet werden dürfen.",
  searchPlaceholder: "Integrationen suchen",
  filtersLabel: "Integrationen filtern",
  connectedTitle: "Verbunden",
  catalogTitle: "Alle Integrationen",
  emptyLabel: "Keine Integrationen gefunden.",
  connectLabel: "Verbinden",
  disconnectLabel: "Trennen",
  retryLabel: "Erneut versuchen",
  disconnectedLabel: "Nicht verbunden",
  pendingLabel: "Wird verbunden",
  connectedLabel: "Verbunden",
  errorLabel: "Fehler",
  unavailableLabel: "Voraussetzungen fehlen",
};

export function KIntegrationMarketplace({
  integrations,
  categories,
  activeCategory,
  searchValue,
  labels,
  onCategoryChange,
  onSearchChange,
  onConnect,
  onDisconnect,
  renderPanel,
  activeIntegrationId,
  className,
  ...props
}: KIntegrationMarketplaceProps) {
  const titleId = useId();
  const copy = { ...defaultMarketplaceLabels, ...labels };
  const query = searchValue.trim().toLocaleLowerCase();
  const visible = integrations.filter(
    (item) =>
      (activeCategory === "all" || item.category === activeCategory) &&
      (!query ||
        `${item.name} ${item.category}`.toLocaleLowerCase().includes(query)),
  );
  const connected = visible.filter((item) => item.state === "connected");
  const active = integrations.find((item) => item.id === activeIntegrationId);

  return (
    <section
      {...props}
      className={["k-integration-marketplace", className]
        .filter(Boolean)
        .join(" ")}
      aria-labelledby={titleId}
    >
      <header className="k-integration-marketplace__header">
        <div>
          <KText as="h1" variant="heading2" id={titleId}>
            {copy.title}
          </KText>
          <KText
            as="p"
            variant="body"
            className="k-integration-marketplace__muted"
          >
            {copy.description}
          </KText>
        </div>
        <KSearchField
          aria-label={copy.searchPlaceholder}
          placeholder={copy.searchPlaceholder}
          value={searchValue}
          clearable
          onClear={() => onSearchChange("")}
          onChange={(event) => onSearchChange(event.currentTarget.value)}
        />
      </header>

      <div
        className="k-integration-marketplace__filters"
        aria-label={copy.filtersLabel}
      >
        {categories.map((category) => (
          <button
            key={category.id}
            type="button"
            className="k-integration-marketplace__filter"
            aria-pressed={category.id === activeCategory}
            onClick={() => onCategoryChange(category.id)}
          >
            {category.label}
          </button>
        ))}
      </div>

      {active && renderPanel ? (
        <div className="k-integration-marketplace__panel">
          {renderPanel(active)}
        </div>
      ) : null}

      {connected.length ? (
        <MarketplaceSection title={copy.connectedTitle}>
          {connected.map((item) => (
            <IntegrationCard
              key={item.id}
              item={item}
              labels={copy}
              onConnect={onConnect}
              onDisconnect={onDisconnect}
            />
          ))}
        </MarketplaceSection>
      ) : null}

      <MarketplaceSection title={copy.catalogTitle}>
        {visible.length ? (
          visible.map((item) => (
            <IntegrationCard
              key={item.id}
              item={item}
              labels={copy}
              onConnect={onConnect}
              onDisconnect={onDisconnect}
            />
          ))
        ) : (
          <KText
            as="p"
            variant="bodySmall"
            className="k-integration-marketplace__empty"
          >
            {copy.emptyLabel}
          </KText>
        )}
      </MarketplaceSection>
    </section>
  );
}

function MarketplaceSection({
  title,
  children,
}: {
  title: ReactNode;
  children: ReactNode;
}) {
  return (
    <section className="k-integration-marketplace__section">
      <KText as="h2" variant="heading5">
        {title}
      </KText>
      <div className="k-integration-marketplace__grid">{children}</div>
    </section>
  );
}

function IntegrationCard({
  item,
  labels,
  onConnect,
  onDisconnect,
}: {
  item: KIntegrationItem;
  labels: Required<KIntegrationMarketplaceLabels>;
  onConnect: (integration: KIntegrationItem) => void;
  onDisconnect?: (integration: KIntegrationItem) => void;
}) {
  const state = item.state ?? "disconnected";
  const stateLabel = labels[`${state}Label`];
  return (
    <article className="k-integration-card" data-state={state}>
      <div className="k-integration-card__icon" aria-hidden="true">
        {item.icon}
      </div>
      <div className="k-integration-card__body">
        <div className="k-integration-card__heading">
          <KText as="h3" variant="body">
            <strong>{item.name}</strong>
          </KText>
          {item.availabilityLabel ? (
            <KBadge variant="info">{item.availabilityLabel}</KBadge>
          ) : null}
        </div>
        <KText
          as="p"
          variant="bodySmall"
          className="k-integration-marketplace__muted"
        >
          {item.description}
        </KText>
        {item.accountLabel ? (
          <KText
            as="p"
            variant="caption"
            className="k-integration-card__account"
          >
            {item.accountLabel}
          </KText>
        ) : null}
      </div>
      <div className="k-integration-card__action">
        {state === "connected" ? (
          <KButton
            variant="ghost"
            onClick={() => onDisconnect?.(item)}
            disabled={!onDisconnect}
          >
            {labels.disconnectLabel}
          </KButton>
        ) : state === "pending" ? (
          <KButton variant="secondary" loading>
            {labels.pendingLabel}
          </KButton>
        ) : state === "unavailable" ? (
          <KBadge variant="warning">{stateLabel}</KBadge>
        ) : (
          <KButton
            variant={state === "error" ? "secondary" : "primary"}
            onClick={() => onConnect(item)}
          >
            {state === "error" ? labels.retryLabel : labels.connectLabel}
          </KButton>
        )}
      </div>
      <span
        className="k-integration-card__status"
        role="status"
        aria-live="polite"
      >
        {stateLabel}
      </span>
    </article>
  );
}

export interface KIntegrationConnectionCardProps extends Omit<
  HTMLAttributes<HTMLElement>,
  "title"
> {
  name: ReactNode;
  icon: ReactNode;
  description: ReactNode;
  permissions: readonly ReactNode[];
  state?: KIntegrationConnectionState;
  availability?: ReactNode;
  connectLabel?: ReactNode;
  retryLabel?: ReactNode;
  disconnectLabel?: ReactNode;
  permissionsTitle?: ReactNode;
  stateLabel: ReactNode;
  onConnect?: () => void;
  onRetry?: () => void;
  onDisconnect?: () => void;
}

export function KIntegrationConnectionCard({
  name,
  icon,
  description,
  permissions,
  state = "disconnected",
  availability,
  connectLabel = "Verbinden",
  retryLabel = "Erneut versuchen",
  disconnectLabel = "Verbindung trennen",
  permissionsTitle = "Zugriff auf",
  stateLabel,
  onConnect,
  onRetry,
  onDisconnect,
  className,
  ...props
}: KIntegrationConnectionCardProps) {
  return (
    <article
      {...props}
      className={["k-integration-connect", className].filter(Boolean).join(" ")}
    >
      <div className="k-integration-connect__identity">
        <div className="k-integration-card__icon" aria-hidden="true">
          {icon}
        </div>
        <div>
          <KText as="h2" variant="heading4">
            {name}
          </KText>
          {availability ? <KBadge variant="info">{availability}</KBadge> : null}
        </div>
      </div>
      <KText as="p" variant="body" className="k-integration-marketplace__muted">
        {description}
      </KText>
      <div className="k-integration-connect__permissions">
        <KText as="h3" variant="label">
          {permissionsTitle}
        </KText>
        <ul>
          {permissions.map((permission, index) => (
            <li key={index}>{permission}</li>
          ))}
        </ul>
      </div>
      <div className="k-integration-connect__footer">
        <span
          role="status"
          aria-live="polite"
          className="k-integration-connect__status"
        >
          <StatusDot state={state} /> {stateLabel}
        </span>
        {state === "pending" ? (
          <KButton loading>{connectLabel}</KButton>
        ) : state === "connected" ? (
          <KButton variant="secondary" onClick={onDisconnect}>
            {disconnectLabel}
          </KButton>
        ) : state === "error" ? (
          <KButton variant="secondary" onClick={onRetry}>
            {retryLabel}
          </KButton>
        ) : (
          <KButton onClick={onConnect} disabled={state === "unavailable"}>
            {connectLabel}
          </KButton>
        )}
      </div>
    </article>
  );
}

function StatusDot({ state }: { state: KIntegrationConnectionState }) {
  return (
    <span
      className="k-integration-status-dot"
      data-state={state}
      aria-hidden="true"
    />
  );
}

export * from "./integrations-admin.js";

export * from "./integration-editor.js";
