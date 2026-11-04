import { useOfferDrag } from "./offer-overview-drag.js";
import { useOfferOverview } from "./offer-overview-state.js";
import {
  KButton,
  KIcon,
  KMenuButton,
  KSearchField,
  KBreadcrumb,
  KStack,
  type KMenuAction,
} from "@k-design-system/ui";
import {
  categories as initialCategories,
  items as initialItems,
  type OfferCategory,
  type OfferItem,
  type OfferFilter,
  type OfferPanel,
} from "./offer-overview-data.js";
import { OfferRow, OfferNavigation } from "./offer-overview-parts.js";
import { OfferDialogs } from "./offer-overview-dialogs.js";
import "./settings-grouped.css";
import "./offer-overview.css";
import "./offer-overview-responsive.css";

// Gallery-only composition: public K controls, application-owned demo data/state.
// Section/card/control gaps follow the reference through scoped semantic tokens.
export function OfferOverview({
  initialFilter = "all",
  empty = false,
}: {
  initialFilter?: OfferFilter;
  empty?: boolean;
}) {
  const {
    categories,
    setCategories,
    items,
    setItems,
    filter,
    setFilter,
    query,
    setQuery,
    closed,
    setClosed,
    hint,
    setHint,
    changes,
    setChanges,
    handover,
    setHandover,
    panel,
    setPanel,
    message,
    setMessage,
    notify,
    changed,
    count,
    visible,
    groups,
    updateItem,
    moveItem,
    itemActions,
    categoryActions,
    add,
  } = useOfferOverview(initialFilter, empty);
  const drag = useOfferDrag(setItems, setCategories, () =>
    changed("Reihenfolge ge�ndert"),
  );
  return (
    <div className="sg-review of-review">
      <div className="of-shell">
        <OfferNavigation notify={notify} />
        <main className="of-main">
          <div className="of-content">
            <div className="of-breadcrumb">
              <KBreadcrumb
                items={[
                  {
                    id: "home",
                    label: "Home",
                    icon: "house",
                    onSelect: () =>
                      notify("Home: Navigationsziel in der Anwendung"),
                  },
                  {
                    id: "management",
                    label: "Verwaltung",
                    onSelect: () =>
                      notify("Verwaltung: Navigationsziel in der Anwendung"),
                  },
                  { id: "offers", label: "Angebot" },
                ]}
              />
            </div>
            <div className="of-back">
              <KButton
                variant="ghost"
                onClick={() =>
                  notify("Verwaltung: Navigationsziel in der Anwendung")
                }
              >
                <KIcon name="chevron-left" size={20} />
                Verwaltung
              </KButton>
            </div>
            <header className="of-heading">
              <div>
                <h1>Angebot</h1>
                <p>
                  {count("service")} Leistungen · {count("product")} Produkte ·{" "}
                  {categories.length} Kategorien
                </p>
              </div>
              <KButton onClick={() => add()}>
                <KIcon name="plus" size={20} />
                Neu
              </KButton>
            </header>
            <div className="of-search">
              <KSearchField
                aria-label="Angebot durchsuchen"
                placeholder="Angebot durchsuchen"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                clearable
                onClear={() => setQuery("")}
              />
            </div>
            <div
              className="of-filters"
              role="group"
              aria-label="Angebotsfilter"
            >
              {(
                [
                  ["all", "Alle"],
                  ["service", `Leistungen · ${count("service")}`],
                  ["product", `Produkte · ${count("product")}`],
                  ["archive", `Archiviert · ${count(undefined, true)}`],
                ] as const
              ).map(([key, label]) => (
                <div className="of-filter-slot" key={key}>
                  <KButton
                    variant="ghost"
                    className="of-filter"
                    aria-pressed={filter === key}
                    onClick={() => setFilter(key)}
                  >
                    {label}
                  </KButton>
                </div>
              ))}
            </div>
            {hint && filter !== "archive" && (
              <div className="of-hint">
                <KIcon name="hand" size={22} />
                <div>
                  <b>Halten und ziehen zum Sortieren</b>
                  <span>Sortieren und Archivieren über die Aktionen.</span>
                </div>
                <KButton
                  variant="ghost"
                  className="of-small-button"
                  aria-label="Hinweis schließen"
                  onClick={() => setHint(false)}
                >
                  <KIcon name="x" size={20} />
                </KButton>
              </div>
            )}
            <div className="of-list" {...drag}>
              {groups.length === 0 ? (
                <div className="of-card of-empty">
                  {query ? (
                    <>
                      Nichts gefunden für „{query}“.{" "}
                      <KButton variant="ghost" onClick={() => setQuery("")}>
                        Suche zurücksetzen
                      </KButton>
                    </>
                  ) : (
                    "Nichts archiviert."
                  )}
                </div>
              ) : (
                groups.map((category) => {
                  const list = visible.filter(
                      (i) => i.category === category.id,
                    ),
                    collapsed = closed.includes(category.id) && !query;
                  return (
                    <section
                      className="of-category"
                      key={category.id}
                      data-offer-category={category.id}
                    >
                      <div className="of-category-header">
                        <KButton
                          variant="ghost"
                          fullWidth
                          className="of-category-toggle"
                          aria-expanded={!collapsed}
                          onClick={() =>
                            setClosed((ids) =>
                              ids.includes(category.id)
                                ? ids.filter((id) => id !== category.id)
                                : [...ids, category.id],
                            )
                          }
                        >
                          <span className="of-category-layout">
                            <span
                              className="of-dot"
                              style={{ background: category.color }}
                            />
                            <span className="of-category-copy">
                              <b>
                                {category.name}
                                <span>
                                  {
                                    items.filter(
                                      (i) =>
                                        i.category === category.id &&
                                        !i.archived,
                                    ).length
                                  }
                                </span>
                              </b>
                              {category.description && (
                                <small title={category.description}>
                                  {category.description}
                                </small>
                              )}
                            </span>
                          </span>
                        </KButton>
                        {filter !== "archive" && (
                          <KMenuButton
                            label={`Aktionen für ${category.name}`}
                            overflow
                            triggerClassName="of-small-button"
                            actions={categoryActions(category)}
                          />
                        )}
                        <KButton
                          className="of-small-button of-collapse"
                          variant="ghost"
                          aria-label={`${category.name} ${collapsed ? "aufklappen" : "zuklappen"}`}
                          onClick={() =>
                            setClosed((ids) =>
                              ids.includes(category.id)
                                ? ids.filter((id) => id !== category.id)
                                : [...ids, category.id],
                            )
                          }
                        >
                          <KIcon
                            name={collapsed ? "chevron-right" : "chevron-down"}
                            size={18}
                          />
                        </KButton>
                      </div>
                      {!collapsed && (
                        <div className="of-card">
                          {list.map((item) => (
                            <OfferRow
                              key={item.id}
                              item={item}
                              category={category}
                              onEdit={() =>
                                setPanel({
                                  type: "edit",
                                  kind: item.kind,
                                  item,
                                })
                              }
                              onRestore={() =>
                                updateItem({ ...item, archived: false })
                              }
                              actions={itemActions(item)}
                            />
                          ))}
                          {list.length === 0 && (
                            <div className="of-empty">
                              Noch nichts in dieser Kategorie.
                            </div>
                          )}
                          {filter !== "archive" && (
                            <KButton
                              fullWidth
                              variant="ghost"
                              className="of-add"
                              onClick={() => add(category.id)}
                            >
                              <span className="of-add-layout">
                                <span>
                                  <KIcon name="plus" size={17} />
                                </span>
                                {filter === "product"
                                  ? "Produkt hinzufügen"
                                  : filter === "service"
                                    ? "Leistung hinzufügen"
                                    : "Hinzufügen"}
                              </span>
                            </KButton>
                          )}
                        </div>
                      )}
                    </section>
                  );
                })
              )}
            </div>
            {filter === "all" && !query && (
              <>
                <KButton
                  fullWidth
                  variant="ghost"
                  className="of-add-category"
                  onClick={() => setPanel({ type: "category" })}
                >
                  <KIcon name="folder" size={18} />
                  Kategorie hinzufügen
                </KButton>
                <section className="of-settings">
                  <h2>Einstellungen</h2>
                  <div className="of-card">
                    <KButton
                      fullWidth
                      variant="ghost"
                      className="of-dialog-row"
                      onClick={() => setPanel({ type: "handover" })}
                    >
                      <span className="of-dialog-row-layout">
                        <span>
                          <b>Übergabezeit für Produkte</b>
                          <small>
                            Einmal pro Termin, unabhängig von der Anzahl der
                            Produkte.
                          </small>
                        </span>
                        <span className="of-value">{handover} Min</span>
                        <KIcon name="chevron-right" size={20} />
                      </span>
                    </KButton>
                  </div>
                </section>
              </>
            )}
          </div>
        </main>
        {changes > 0 && (
          <div className="of-publish">
            <span>
              {changes} <span className="of-wide-label">Änderungen </span>nicht
              veröffentlicht
            </span>
            <KButton
              variant="ghost"
              className="of-history"
              aria-label="Verlauf"
              onClick={() => setPanel({ type: "history" })}
            >
              <KIcon name="rotate-ccw" size={15} />
              <span className="of-wide-label">Verlauf</span>
            </KButton>
            <KButton
              onClick={() => {
                setChanges(0);
                notify(
                  "Demo: Änderungen veröffentlicht. Es wurden keine Serverdaten verändert.",
                );
              }}
            >
              Veröffentlichen
            </KButton>
          </div>
        )}
        {message && (
          <div className="of-message" role="status">
            <KIcon name="check" size={18} />
            <span>{message}</span>
            <KButton
              variant="ghost"
              className="of-small-button"
              aria-label="Meldung schließen"
              onClick={() => setMessage("")}
            >
              <KIcon name="x" size={16} />
            </KButton>
          </div>
        )}
        {panel && (
          <OfferDialogs
            key={JSON.stringify(panel)}
            panel={panel}
            categories={categories}
            items={items}
            handover={handover}
            close={() => setPanel(null)}
            setPanel={setPanel}
            saveCategory={(c) => {
              setCategories((list) =>
                list.some((x) => x.id === c.id)
                  ? list.map((x) => (x.id === c.id ? c : x))
                  : [...list, c],
              );
              changed("Kategorie im lokalen Entwurf gespeichert");
            }}
            deleteCategory={(id, target) => {
              setCategories((list) => list.filter((c) => c.id !== id));
              setItems((list) =>
                list.map((i) =>
                  i.category === id ? { ...i, category: target } : i,
                ),
              );
              changed("Kategorie entfernt, Einträge verschoben");
            }}
            saveItem={updateItem}
            moveItem={moveItem}
            saveHandover={(n) => {
              setHandover(n);
              changed("Übergabezeit im lokalen Entwurf gespeichert");
            }}
          />
        )}
      </div>
    </div>
  );
}
