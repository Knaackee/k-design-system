import { useState } from "react";
import {
  KAdaptiveDialog,
  KButton,
  KField,
  KIcon,
  KInput,
  KSelect,
  KStack,
  KBadge,
} from "@k-design-system/ui";
import { CatalogEditor } from "./catalog-editor-fixture.js";
import {
  colors,
  type OfferCategory,
  type OfferItem,
  type OfferPanel,
  type OfferKind,
} from "./offer-overview-data.js";

export interface OfferDialogProps {
  panel: NonNullable<OfferPanel>;
  categories: OfferCategory[];
  items: OfferItem[];
  handover: number;
  close: () => void;
  setPanel: (panel: OfferPanel) => void;
  saveCategory: (category: OfferCategory) => void;
  deleteCategory: (id: string, target: string) => void;
  saveItem: (item: OfferItem) => void;
  moveItem: (id: string, target: string) => void;
  saveHandover: (value: number) => void;
}
export function OfferDialogs(props: OfferDialogProps) {
  const { panel, categories, close, setPanel } = props;
  const category = panel.type === "category" ? panel.category : undefined;
  const original = panel.type === "edit" ? panel.item : undefined;
  const [name, setName] = useState(category?.name ?? original?.name ?? "");
  const [description, setDescription] = useState(category?.description ?? "");
  const [color, setColor] = useState(category?.color ?? colors[0]!);
  const [target, setTarget] = useState(
    original?.category ??
      ("category" in panel && typeof panel.category === "string"
        ? panel.category
        : categories.find(
            (c) => panel.type !== "delete" || c.id !== panel.category.id,
          )?.id) ??
      "",
  );
  const [minutes, setMinutes] = useState(props.handover);
  const categoryItemCount =
    panel.type === "delete"
      ? props.items.filter((item) => item.category === panel.category.id).length
      : 0;
  const title =
    panel.type === "new"
      ? "Neu"
      : panel.type === "category"
        ? category
          ? "Kategorie bearbeiten"
          : "Neue Kategorie"
        : panel.type === "delete"
          ? `„${panel.category.name}“ löschen?`
          : panel.type === "move"
            ? "Verschieben nach"
            : panel.type === "handover"
              ? "Übergabezeit"
              : panel.type === "history"
                ? "Änderungsverlauf"
                : `${panel.kind === "product" ? "Produkt" : "Leistung"} ${original ? "bearbeiten" : "hinzufügen"}`;
  const action = (
    label: string,
    icon: "clock" | "package" | "folder",
    help: string,
    kind: OfferKind | "category",
    color: string,
  ) => (
    <KButton
      key={kind}
      fullWidth
      variant="ghost"
      className="of-dialog-row"
      onClick={() =>
        setPanel(
          kind === "category"
            ? { type: "category" }
            : {
                type: "edit",
                kind,
                category: panel.type === "new" ? panel.category : undefined,
              },
        )
      }
    >
      <span className="of-dialog-row-layout">
        <span className="of-action-icon" style={{ background: color }}>
          <KIcon name={icon} size={20} />
        </span>
        <span>
          <b>{label}</b>
          <small>{help}</small>
        </span>
        <KIcon name="chevron-right" size={20} />
      </span>
    </KButton>
  );
  if (panel.type === "edit")
    return (
      <KAdaptiveDialog
        open
        onOpenChange={(open) => !open && close()}
        title={title}
        headerless
        showClose={false}
        contentInset={false}
        compactPresentation="fullscreen"
        className="of-editor-overlay"
        bodyClassName="of-editor-body"
      >
        <CatalogEditor
          kind={panel.kind}
          initialCategories={categories.map((c) => c.name)}
          initialStock={original?.stock ?? 0}
          initialReserved={0}
          initialDraft={{
            ...original?.editorDraft,
            name: original?.name ?? "",
            category:
              categories.find(
                (c) => c.id === (original?.category ?? panel.category),
              )?.name ??
              categories[0]?.name ??
              "",
            price: original ? original.price.toFixed(2).replace(".", ",") : "",
            duration: String(original?.duration ?? 30),
            active: !original?.hidden,
            featured: !!original?.featured,
            priceKind:
              original?.priceKind === "request"
                ? "request"
                : original?.priceKind === "from"
                  ? "from"
                  : "fixed",
            ...(original?.editorDraft?.groups
              ? { groups: original.editorDraft.groups }
              : original?.options
                ? {}
                : { groups: [] }),
          }}
          onClose={close}
          onSave={(draft, stock) =>
            props.saveItem({
              ...original,
              editorDraft: structuredClone(draft),
              id: original?.id ?? `offer-${Date.now()}`,
              kind: panel.kind,
              name: draft.name,
              category:
                categories.find((c) => c.name === draft.category)?.id ??
                categories[0]!.id,
              price: Number(draft.price.replace(",", ".")),
              duration: Number(draft.duration),
              stock,
              hidden: !draft.active,
              featured: draft.featured,
              options: draft.groups.length > 0,
              priceKind:
                draft.priceKind === "request"
                  ? "request"
                  : draft.priceKind === "from"
                    ? "from"
                    : undefined,
              draft: true,
            })
          }
        />
      </KAdaptiveDialog>
    );
  return (
    <KAdaptiveDialog
      open
      onOpenChange={(open) => !open && close()}
      title={title}
      closeLabel="Schließen"
      className="sg-review of-dialog"
      description={
        panel.type === "new" && panel.category
          ? `in ${categories.find((c) => c.id === panel.category)?.name}`
          : undefined
      }
    >
      {panel.type === "new" && (
        <div className="of-card">
          {action(
            "Leistung",
            "clock",
            "Buchbar mit Preis und Dauer",
            "service",
            "#7c3aed",
          )}
          {action(
            "Produkt",
            "package",
            "Ware oder Extra mit Bestand",
            "product",
            "#ea580c",
          )}
          {!panel.category &&
            action(
              "Kategorie",
              "folder",
              "Gruppe für Leistungen und Produkte",
              "category",
              "#52525b",
            )}
        </div>
      )}
      {panel.type === "category" && (
        <KStack gap="action" align="stretch">
          <KField label="Name">
            <KInput
              value={name}
              onChange={(e) => setName(e.target.value)}
              autoFocus
            />
          </KField>
          <KField
            label="Beschreibung (optional)"
            helperText="Erscheint auf deiner Buchungsseite über der Kategorie."
          >
            <KInput
              value={description}
              onChange={(e) => setDescription(e.target.value)}
            />
          </KField>
          <KField label="Farbe">
            <div className="of-colors">
              {colors.map((c, i) => (
                <KButton
                  key={c}
                  className="of-color"
                  variant="ghost"
                  aria-label={`Farbe ${i + 1}`}
                  aria-pressed={c === color}
                  onClick={() => setColor(c)}
                  style={{ background: c }}
                >
                  <KIcon
                    name="check"
                    size={20}
                    style={{ opacity: c === color ? 1 : 0 }}
                  />
                </KButton>
              ))}
            </div>
          </KField>
          <KButton
            fullWidth
            disabled={!name.trim()}
            onClick={() =>
              props.saveCategory({
                id: category?.id ?? `cat-${Date.now()}`,
                name: name.trim(),
                description,
                color,
              })
            }
          >
            {category ? "Übernehmen" : "Anlegen"}
          </KButton>
        </KStack>
      )}
      {panel.type === "delete" && (
        <KStack gap="action" align="stretch">
          <p className="of-dialog-help">
            {categoryItemCount
              ? `${categoryItemCount} Einträge liegen in dieser Kategorie. Wohin sollen sie?`
              : "Die Kategorie ist leer."}
          </p>
          {categoryItemCount > 0 && (
            <KSelect
              label="Zielkategorie"
              value={target}
              onValueChange={setTarget}
              options={categories
                .filter((c) => c.id !== panel.category.id)
                .map((c) => ({ value: c.id, label: c.name }))}
            />
          )}
          <KButton
            className="of-danger-button"
            disabled={categoryItemCount > 0 && !target}
            onClick={() => props.deleteCategory(panel.category.id, target)}
          >
            {categoryItemCount ? "Verschieben und löschen" : "Löschen"}
          </KButton>
          <KButton variant="secondary" onClick={close}>
            Abbrechen
          </KButton>
        </KStack>
      )}
      {panel.type === "move" && (
        <div className="of-card">
          {categories.map((c) => (
            <KButton
              key={c.id}
              fullWidth
              variant="ghost"
              className="of-dialog-row"
              onClick={() => props.moveItem(panel.item.id, c.id)}
            >
              <span className="of-dialog-row-layout">
                <span className="of-dot" style={{ background: c.color }} />
                <span>{c.name}</span>
                {c.id === panel.item.category && (
                  <KBadge variant="secondary" className="of-badge">
                    aktuell
                  </KBadge>
                )}
              </span>
            </KButton>
          ))}
        </div>
      )}
      {panel.type === "handover" && (
        <KStack gap="action" align="stretch">
          <p className="of-dialog-help">
            Wird einmal pro Termin eingeplant, wenn Produkte dabei sind.
          </p>
          <div className="of-stepper">
            <KButton
              variant="secondary"
              aria-label="Weniger"
              disabled={minutes === 0}
              onClick={() => setMinutes(Math.max(0, minutes - 5))}
            >
              <KIcon name="minus" />
            </KButton>
            <b>
              {minutes} <small>Min</small>
            </b>
            <KButton
              variant="secondary"
              aria-label="Mehr"
              onClick={() => setMinutes(minutes + 5)}
            >
              <KIcon name="plus" />
            </KButton>
          </div>
          <KButton onClick={() => props.saveHandover(minutes)}>
            Übernehmen
          </KButton>
        </KStack>
      )}
      {panel.type === "history" && (
        <KStack gap="control" align="stretch">
          <p className="of-dialog-help">
            Änderungen dieser Storybook-Sitzung sind lokale Entwürfe. Es werden
            keine Daten veröffentlicht.
          </p>
          <div className="of-card of-empty">
            Neue Angebote und Änderungen bleiben bis zur Veröffentlichung im
            Entwurf.
          </div>
        </KStack>
      )}
    </KAdaptiveDialog>
  );
}
