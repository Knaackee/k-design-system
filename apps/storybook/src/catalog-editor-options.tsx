import { KCatalogEditorCard } from "@k-design-system/ui";
import {
  KButton,
  KIcon,
  KField,
  KInput,
  KSelect,
  KSwitch,
  KStack,
  KInline,
} from "@k-design-system/ui";
import { Section } from "./catalog-editor-parts.js";
import {
  catalog,
  validGroup,
  type EditorState,
} from "./catalog-editor-state.js";
export function CatalogEditorOptions({ state }: { state: EditorState }) {
  const { product, draft, change, setPanel, groupChange, toggleRec, errors } =
    state;
  return (
    <>
      <Section title="Zusatzoptionen mit Aufpreis">
        <KStack gap="action" align="stretch">
          {draft.groups.map((g, gi) => (
            <KCatalogEditorCard inset={false} key={gi}>
              {errors && !validGroup(g) && (
                <p className="ce-error" role="alert">
                  Bitte prüfe Gruppenname, Optionen und Auswahlregel.
                  Pflichtoptionen müssen aktiv sein.
                </p>
              )}
              <div className="ce-group-head">
                <KInput
                  aria-label="Gruppenname"
                  value={g.name}
                  onChange={(e) =>
                    groupChange(gi, (g) => ({
                      ...g,
                      name: e.target.value,
                    }))
                  }
                />
                <KButton
                  variant="ghost"
                  aria-label="Gruppe löschen"
                  onClick={() =>
                    change(
                      "groups",
                      draft.groups.filter((_, i) => i !== gi),
                    )
                  }
                >
                  <KIcon name="trash" size={16} />
                </KButton>
              </div>
              <div className="ce-group-rule">
                <KSelect
                  label="Auswahlregel"
                  value={g.rule}
                  options={[
                    {
                      value: "optional",
                      label: "Optional · höchstens 1",
                    },
                    {
                      value: "multiple",
                      label: "Optional · mehrere",
                    },
                    { value: "required", label: "Pflicht · genau 1" },
                    { value: "custom", label: "Eigene Regel …" },
                  ]}
                  onValueChange={(v) =>
                    groupChange(gi, (g) => ({ ...g, rule: v }))
                  }
                />
                {g.rule === "custom" && (
                  <div className="ce-two">
                    <KField
                      label={<span className="ce-field-label">Mindestens</span>}
                    >
                      <KInput
                        type="number"
                        min={0}
                        value={g.min}
                        onChange={(e) =>
                          groupChange(gi, (g) => ({
                            ...g,
                            min: e.target.value,
                          }))
                        }
                      />
                    </KField>
                    <KField
                      label={<span className="ce-field-label">Höchstens</span>}
                    >
                      <KInput
                        type="number"
                        min={g.min}
                        placeholder="Unbegrenzt"
                        value={g.max}
                        onChange={(e) =>
                          groupChange(gi, (g) => ({
                            ...g,
                            max: e.target.value,
                          }))
                        }
                      />
                    </KField>
                  </div>
                )}
              </div>
              {g.options.map((o, oi) => (
                <div className="ce-option" key={oi}>
                  <KIcon name="grip-vertical" size={16} />
                  <KInput
                    aria-label="Option"
                    value={o.name}
                    onChange={(e) =>
                      groupChange(gi, (g) => ({
                        ...g,
                        options: g.options.map((o, i) =>
                          i === oi ? { ...o, name: e.target.value } : o,
                        ),
                      }))
                    }
                  />
                  <KInput
                    aria-label="Aufpreis"
                    inputMode="decimal"
                    value={o.price}
                    trailingAction={<span>€</span>}
                    onChange={(e) =>
                      groupChange(gi, (g) => ({
                        ...g,
                        options: g.options.map((o, i) =>
                          i === oi ? { ...o, price: e.target.value } : o,
                        ),
                      }))
                    }
                  />
                  <KSwitch
                    label={`${o.name} aktiv`}
                    showLabel={false}
                    checked={o.active}
                    onCheckedChange={(v) =>
                      groupChange(gi, (g) => ({
                        ...g,
                        options: g.options.map((o, i) =>
                          i === oi ? { ...o, active: v } : o,
                        ),
                      }))
                    }
                  />
                  <KButton
                    variant="ghost"
                    aria-label="Option löschen"
                    onClick={() =>
                      groupChange(gi, (g) => ({
                        ...g,
                        options: g.options.filter((_, i) => i !== oi),
                      }))
                    }
                  >
                    <KIcon name="x" size={16} />
                  </KButton>
                </div>
              ))}
              <KButton
                fullWidth
                variant="ghost"
                onClick={() =>
                  groupChange(gi, (g) => ({
                    ...g,
                    options: [
                      ...g.options,
                      { name: "", price: "0", active: true },
                    ],
                  }))
                }
              >
                <KIcon name="plus" size={16} />
                Option hinzufügen
              </KButton>
            </KCatalogEditorCard>
          ))}
          <KButton
            className="ce-add-group"
            fullWidth
            variant="ghost"
            onClick={() =>
              change("groups", [
                ...draft.groups,
                {
                  name: "Neue Gruppe",
                  rule: "optional",
                  min: "0",
                  max: "1",
                  options: [],
                },
              ])
            }
          >
            <KIcon name="plus" size={16} />
            Gruppe hinzufügen
          </KButton>
        </KStack>
      </Section>
      <Section
        title="Dazu empfehlen"
        action={
          <KButton variant="ghost" onClick={() => setPanel("recommendations")}>
            Bearbeiten
          </KButton>
        }
        help="Wird nach der Auswahl vorgeschlagen, nicht automatisch hinzugefügt."
      >
        <KCatalogEditorCard>
          <KInline gap="control" wrap>
            {draft.recommendations.map((id) => {
              const c = catalog.find((c) => c.id === id)!;
              return (
                <KButton
                  key={id}
                  variant="secondary"
                  className="ce-chip"
                  onClick={() => toggleRec(id)}
                  aria-label={`${c.name} entfernen`}
                >
                  {c.name} <span className="ce-muted">{c.price}</span>
                  <KIcon name="x" size={12} />
                </KButton>
              );
            })}
            {!draft.recommendations.length && (
              <KButton
                variant="ghost"
                onClick={() => setPanel("recommendations")}
              >
                Noch nichts ausgewählt
              </KButton>
            )}
          </KInline>
        </KCatalogEditorCard>
      </Section>
      <Section
        title=""
        help="Nicht mehr buchbar. Bestehende Termine bleiben erhalten."
      >
        <KCatalogEditorCard inset={false}>
          <KButton
            className="ce-danger ce-archive"
            fullWidth
            variant="ghost"
            onClick={() => setPanel("archive")}
          >
            <KIcon name="archive" size={20} />
            {product ? "Produkt" : "Leistung"} archivieren
          </KButton>
        </KCatalogEditorCard>
      </Section>
    </>
  );
}
