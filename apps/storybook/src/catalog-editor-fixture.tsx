import {
  KButton,
  KIcon,
  KBadge,
  KCatalogEditorBody,
  KCatalogEditorPreview,
} from "@k-design-system/ui";
import { useCatalogEditor } from "./catalog-editor-state.js";
import type { Draft } from "./catalog-editor-state.js";
import { useEffect } from "react";
import { CatalogEditorFields } from "./catalog-editor-fields.js";
import { CatalogEditorOptions } from "./catalog-editor-options.js";
import { CatalogEditorDialogs } from "./catalog-editor-dialogs.js";
import "./settings-grouped.css";
import "./catalog-editor.css";

export function CatalogEditor({
  kind = "service",
  initialPanel = null,
  initialDraft,
  initialCategories,
  initialStock,
  initialReserved,
  onSave,
  onClose,
}: {
  kind?: "service" | "product";
  initialPanel?: "stock" | "recommendations" | null;
  initialDraft?: Partial<Draft>;
  initialCategories?: string[];
  initialStock?: number;
  initialReserved?: number;
  onSave?: (draft: Draft, stock: number) => void;
  onClose?: () => void;
}) {
  const state = useCatalogEditor(
    kind,
    initialPanel,
    initialDraft,
    initialCategories,
    initialStock,
    initialReserved,
  );
  useEffect(() => {
    if (!state.open) onClose?.();
  }, [state.open, onClose]);
  const {
    product,
    draft,
    setSaved,
    setPanel,
    open,
    setOpen,
    setErrors,
    status,
    setStatus,
    stock,
    reserved,
    dirty,
    close,
    valid,
    price,
  } = state;
  const preview = (
    <KCatalogEditorPreview
      name={draft.name || "Name"}
      subtitle={`${!product ? `${draft.duration} Min · ` : ""}${price}`}
      image={
        <KButton
          className="ce-image"
          variant="secondary"
          aria-label="Bild ändern"
          onClick={() => setPanel("image")}
        >
          {draft.image ? (
            <img src={draft.image} alt="" />
          ) : (
            <KIcon name="image" size={26} />
          )}
          <span className="ce-image-edit">
            <KIcon name="pencil" size={12} />
          </span>
        </KButton>
      }
      tags={
        <>
          {!draft.active && (
            <KBadge variant="destructive">Nicht buchbar</KBadge>
          )}
          {draft.featured && (
            <KBadge variant="secondary">★ Hervorgehoben</KBadge>
          )}
          {product && draft.track && (
            <KBadge
              variant={
                stock - reserved <= Number(draft.warn) ? "warning" : "success"
              }
            >
              {stock - reserved} verfügbar
            </KBadge>
          )}
          {draft.groups.length > 0 && (
            <KBadge variant="secondary" className="ce-options-badge">
              + {draft.groups.map((g) => g.name).join(", ")}
            </KBadge>
          )}
        </>
      }
    />
  );
  return (
    <div className="sg-review ce-stage">
      {!open ? (
        <KButton onClick={() => setOpen(true)}>
          {product ? "Produkt" : "Leistung"} bearbeiten
        </KButton>
      ) : (
        <article
          className="ce-editor"
          aria-label={`${product ? "Produkt" : "Leistung"} bearbeiten`}
        >
          <header className="ce-header">
            <KButton variant="ghost" aria-label="Schließen" onClick={close}>
              <KIcon name="x" size={20} />
            </KButton>
            <div>
              <h1>{product ? "Produkt" : "Leistung"} bearbeiten</h1>
              <p>
                <KIcon name={product ? "package" : "scissors"} size={14} />
                {product ? "Produkt" : "Leistung"} · Änderungen als Entwurf
              </p>
            </div>
          </header>
          <div className="ce-body">
            <KCatalogEditorBody preview={preview}>
              <CatalogEditorFields state={state} />
              <CatalogEditorOptions state={state} />
            </KCatalogEditorBody>
          </div>
          <footer className="ce-footer">
            <span role="status">
              {status ||
                (dirty
                  ? "Ungespeicherte Änderungen"
                  : "Alle Änderungen gespeichert")}
            </span>
            <KButton variant="secondary" onClick={close}>
              Abbrechen
            </KButton>
            <KButton
              onClick={() => {
                setErrors(true);
                if (valid) {
                  setSaved(structuredClone(draft));
                  setStatus("Entwurf in dieser Demo gespeichert");
                  onSave?.(draft, stock);
                } else setStatus("Bitte prüfe die Eingaben.");
              }}
            >
              Speichern
            </KButton>
          </footer>
        </article>
      )}
      <CatalogEditorDialogs state={state} />
    </div>
  );
}
