import { useState, type HTMLAttributes, type ReactNode } from "react";
import { KBadge, type KBadgeVariant } from "../basic-components.js";
import { KSelect } from "../forms/selection.js";
import { KButton } from "../primitives/button.js";
import { KText } from "../primitives/text.js";
import type { KIntegrationItem } from "./integrations.js";
import { KTabStrip } from "./tab-strip.js";

export type KIntegrationCatalogState = "draft" | "tested" | "published";
export type KIntegrationCatalogView = "all" | "published";
export interface KIntegrationCatalogItem extends KIntegrationItem {
  catalogState: KIntegrationCatalogState;
  endpoint: ReactNode;
}
export interface KIntegrationAdminCatalogLabels {
  preview?: ReactNode;
  create?: ReactNode;
  list?: string;
  draft?: ReactNode;
  tested?: ReactNode;
  published?: ReactNode;
  allView?: string;
  publishedView?: string;
  views?: string;
  category?: string;
  allCategories?: string;
  empty?: ReactNode;
}
export interface KIntegrationAdminCatalogProps extends Omit<
  HTMLAttributes<HTMLElement>,
  "title" | "onSelect"
> {
  title?: ReactNode;
  integrations: readonly KIntegrationCatalogItem[];
  labels?: KIntegrationAdminCatalogLabels;
  activeView?: KIntegrationCatalogView;
  activeCategory?: string;
  onViewChange?: (view: KIntegrationCatalogView) => void;
  onCategoryChange?: (category: string) => void;
  onCreate: () => void;
  onEdit: (integration: KIntegrationCatalogItem) => void;
}
const defaultLabels: Required<KIntegrationAdminCatalogLabels> = {
  preview: "Vorschau",
  create: "Integration hinzufügen",
  list: "Katalogeinträge",
  draft: "Entwurf",
  tested: "Getestet",
  published: "Veröffentlicht",
  allView: "Alle",
  publishedView: "Veröffentlicht",
  views: "Katalogstatus",
  category: "Kategorie",
  allCategories: "Alle Kategorien",
  empty: "Keine Katalogeinträge für diese Filter.",
};
export function KIntegrationAdminCatalog({
  title = "Integrationskatalog verwalten",
  integrations,
  labels,
  activeView,
  activeCategory,
  onViewChange,
  onCategoryChange,
  onCreate,
  onEdit,
  className,
  ...props
}: KIntegrationAdminCatalogProps) {
  const copy = { ...defaultLabels, ...labels };
  const [localView, setLocalView] = useState<KIntegrationCatalogView>("all");
  const [localCategory, setLocalCategory] = useState("all");
  const view = activeView ?? localView;
  const categories = [...new Set(integrations.map((item) => item.category))]
    .filter(Boolean)
    .sort(compareText);
  const requestedCategory = activeCategory ?? localCategory;
  const category = categories.includes(requestedCategory)
    ? requestedCategory
    : "all";
  const visible = integrations.filter(
    (item) =>
      (category === "all" || item.category === category) &&
      matchesView(item.catalogState, view),
  );
  visible.sort((left, right) => {
    if (view === "all") {
      const stateOrder =
        Number(right.catalogState === "published") -
        Number(left.catalogState === "published");
      if (stateOrder) return stateOrder;
    }
    return compareText(left.name, right.name) || compareText(left.id, right.id);
  });
  const selectView = (next: string) => {
    const nextView = next as KIntegrationCatalogView;
    if (activeView === undefined) setLocalView(nextView);
    onViewChange?.(nextView);
  };
  const selectCategory = (next: string) => {
    if (activeCategory === undefined) setLocalCategory(next);
    onCategoryChange?.(next);
  };
  const variants: Record<KIntegrationCatalogState, KBadgeVariant> = {
    draft: "outline",
    tested: "info",
    published: "success",
  };
  return (
    <section
      {...props}
      className={["k-integration-admin", className].filter(Boolean).join(" ")}
    >
      <div className="k-integration-admin__header">
        <KText as="h1" variant="heading3">
          {title}
        </KText>
        <div className="k-integration-admin__actions">
          {copy.preview != null && (
            <KBadge variant="warning">{copy.preview}</KBadge>
          )}
          <KButton onClick={onCreate}>{copy.create}</KButton>
        </div>
      </div>
      <div className="k-integration-admin__filters">
        <KTabStrip
          label={copy.views}
          items={[
            { id: "all", label: copy.allView },
            { id: "published", label: copy.publishedView },
          ]}
          selectedId={view}
          onSelect={selectView}
        />
        <div className="k-integration-admin__category">
          <KSelect
            label={copy.category}
            value={category}
            options={[
              { value: "all", label: copy.allCategories },
              ...categories.map((value) => ({ value, label: value })),
            ]}
            onValueChange={selectCategory}
          />
        </div>
      </div>
      <div className="k-integration-admin__list" aria-label={copy.list}>
        {visible.map((item) => (
          <button
            key={item.id}
            type="button"
            aria-haspopup="dialog"
            onClick={() => onEdit(item)}
          >
            <span className="k-integration-card__icon" aria-hidden="true">
              {item.icon}
            </span>
            <span>
              <strong>{item.name}</strong>
              <small>{item.category}</small>
              <small>{item.description}</small>
            </span>
            <KBadge variant={variants[item.catalogState]}>
              {copy[item.catalogState]}
            </KBadge>
          </button>
        ))}
        {!visible.length && (
          <KText
            as="p"
            variant="bodySmall"
            className="k-integration-admin__empty"
          >
            {copy.empty}
          </KText>
        )}
      </div>
    </section>
  );
}

function matchesView(
  state: KIntegrationCatalogState,
  view: KIntegrationCatalogView,
) {
  return view === "all" || (view === "published" && state === "published");
}

function compareText(left: string, right: string) {
  return left.localeCompare(right, undefined, { sensitivity: "base" });
}
