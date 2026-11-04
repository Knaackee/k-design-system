import { KCatalogEditorCard } from "@k-design-system/ui";
import {
  KButton,
  KIcon,
  KField,
  KInput,
  KTextarea,
  KSelect,
  KSwitch,
  KStack,
  KInline,
} from "@k-design-system/ui";
import { Section, Row, Choice } from "./catalog-editor-parts.js";
import { number, type EditorState } from "./catalog-editor-state.js";
export function CatalogEditorFields({ state }: { state: EditorState }) {
  const {
    product,
    draft,
    errors,
    change,
    setPanel,
    categories,
    stock,
    reserved,
    warningValid,
  } = state;
  return (
    <>
      <Section title="Grunddaten">
        <KCatalogEditorCard>
          <KStack gap="action" align="stretch">
            <KField
              label={<span className="ce-field-label">Name</span>}
              errorText={
                errors && !draft.name.trim()
                  ? "Bitte gib einen Namen ein."
                  : undefined
              }
            >
              <KInput
                value={draft.name}
                maxLength={120}
                onChange={(e) => change("name", e.target.value)}
              />
            </KField>
            <KField label={<span className="ce-field-label">Kategorie</span>}>
              <KSelect
                value={draft.category}
                options={[
                  ...categories.map((c) => ({ value: c, label: c })),
                  { value: "new", label: "+ Neue Kategorie …" },
                ]}
                onValueChange={(v) =>
                  v === "new" ? setPanel("category") : change("category", v)
                }
              />
            </KField>
            <KField
              label={
                <span className="ce-field-label">Beschreibung (optional)</span>
              }
              helperText={`${draft.description.length}/4000 · erscheint auf deiner Buchungsseite`}
            >
              <KTextarea
                rows={3}
                maxLength={4000}
                value={draft.description}
                onChange={(e) => change("description", e.target.value)}
              />
            </KField>
          </KStack>
        </KCatalogEditorCard>
      </Section>
      <Section title={product ? "Preis" : "Preis & Dauer"}>
        <KCatalogEditorCard>
          <KStack gap="action" align="stretch">
            <Choice
              label="Preisart"
              value={draft.priceKind}
              onChange={(v) => change("priceKind", v)}
              items={[
                ["fixed", "Festpreis"],
                ["from", "Ab-Preis"],
                ["request", "Auf Anfrage"],
              ]}
            />
            {draft.priceKind === "request" && (
              <p className="ce-help">
                Kund:innen senden eine Anfrage, du nennst den Preis danach.
              </p>
            )}
            <div className={product ? "" : "ce-two"}>
              {draft.priceKind !== "request" && (
                <KField
                  label={
                    <span className="ce-field-label">
                      {draft.priceKind === "from" ? "Preis ab" : "Preis"}
                    </span>
                  }
                  errorText={
                    errors &&
                    (!Number.isFinite(number(draft.price)) ||
                      number(draft.price) < 0 ||
                      !draft.price.trim())
                      ? "Bitte gib einen gültigen Preis ein."
                      : undefined
                  }
                >
                  <KInput
                    value={draft.price}
                    inputMode="decimal"
                    trailingAction={<span>€</span>}
                    onChange={(e) => change("price", e.target.value)}
                  />
                </KField>
              )}
              {!product && (
                <KField
                  label={<span className="ce-field-label">Dauer</span>}
                  errorText={
                    errors && !(Number(draft.duration) > 0)
                      ? "Bitte gib eine Dauer ein."
                      : undefined
                  }
                >
                  <KInput
                    value={draft.duration}
                    inputMode="numeric"
                    trailingAction={<span>Min</span>}
                    onChange={(e) => change("duration", e.target.value)}
                  />
                </KField>
              )}
            </div>
            {!product && (
              <KInline gap="control" wrap>
                {[15, 30, 45, 60, 90].map((n) => (
                  <KButton
                    className="ce-chip"
                    key={n}
                    variant={
                      draft.duration === String(n) ? "primary" : "secondary"
                    }
                    aria-pressed={draft.duration === String(n)}
                    onClick={() => change("duration", String(n))}
                  >
                    {n} Min
                  </KButton>
                ))}
              </KInline>
            )}
          </KStack>
        </KCatalogEditorCard>
      </Section>
      {product && (
        <Section title="Bestand">
          <KCatalogEditorCard inset={false}>
            <Row
              title="Bestand führen"
              help="Verkäufe und Reservierungen werden mitgezählt."
            >
              <KSwitch
                label="Bestand führen"
                showLabel={false}
                checked={draft.track}
                onCheckedChange={(v) => change("track", v)}
              />
            </Row>
            {draft.track && (
              <>
                <Row
                  title={`${stock - reserved} verfügbar`}
                  help={`${stock} auf Lager · ${reserved} reserviert`}
                >
                  <KButton variant="ghost" onClick={() => setPanel("stock")}>
                    Ändern
                    <KIcon name="chevron-right" size={16} />
                  </KButton>
                </Row>
                <Row
                  title="Bei 0 ausblenden"
                  help="Kund:innen sehen das Produkt nicht, wenn nichts verfügbar ist."
                >
                  <KSwitch
                    label="Bei 0 ausblenden"
                    showLabel={false}
                    checked={draft.hide}
                    onCheckedChange={(v) => change("hide", v)}
                  />
                </Row>
                <Row
                  title="Warnen ab"
                  help="Hinweis „Nur noch wenige“ in deiner Übersicht."
                >
                  <div className="ce-threshold">
                    <KInput
                      aria-label="Warnen ab"
                      aria-invalid={errors && !warningValid}
                      value={draft.warn}
                      type="number"
                      min={0}
                      onChange={(e) => change("warn", e.target.value)}
                      trailingAction={<span>Stk.</span>}
                    />
                  </div>
                </Row>
              </>
            )}
            {errors && !warningValid && (
              <p className="ce-error" role="alert">
                Bitte gib eine ganze, nicht negative Warnmenge ein.
              </p>
            )}
          </KCatalogEditorCard>
        </Section>
      )}
      <Section title="Sichtbarkeit">
        <KCatalogEditorCard inset={false}>
          <Row
            title="Buchbar"
            help={`Kund:innen können ${product ? "das Produkt" : "diese Leistung"} auf deiner Seite wählen.`}
          >
            <KSwitch
              label="Buchbar"
              showLabel={false}
              checked={draft.active}
              onCheckedChange={(v) => change("active", v)}
            />
          </Row>
          <Row title="Hervorheben" help="Erscheint oben in deinem Angebot.">
            <KSwitch
              label="Hervorheben"
              showLabel={false}
              checked={draft.featured}
              onCheckedChange={(v) => change("featured", v)}
            />
          </Row>
        </KCatalogEditorCard>
      </Section>
    </>
  );
}
