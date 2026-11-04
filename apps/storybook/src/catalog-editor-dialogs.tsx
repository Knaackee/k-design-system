import {
  KButton,
  KIcon,
  KField,
  KInput,
  KSelect,
  KStack,
  KAdaptiveDialog,
  KCheckbox,
} from "@k-design-system/ui";
import { AvatarEditorFixture } from "./avatar-editor-fixture.js";
import { Row, Choice } from "./catalog-editor-parts.js";
import { catalog, type EditorState } from "./catalog-editor-state.js";
export function CatalogEditorDialogs({ state }: { state: EditorState }) {
  const {
    product,
    draft,
    setDraft,
    saved,
    panel,
    setPanel,
    open,
    setOpen,
    setStatus,
    stock,
    setStock,
    reserved,
    movement,
    setMovement,
    amount,
    setAmount,
    reason,
    setReason,
    history,
    setHistory,
    search,
    setSearch,
    filter,
    setFilter,
    newCategory,
    setNewCategory,
    setCategories,
    change,
    toggleRec,
    after,
    canBook,
    price,
  } = state;
  return (
    <>
      <KAdaptiveDialog
        open={panel === "stock"}
        onOpenChange={(v) => !v && setPanel(null)}
        title="Bestand ändern"
        closeLabel="Schließen"
        className="sg-review ce-overlay"
        actions={
          <KButton
            disabled={!canBook}
            onClick={() => {
              setStock(after);
              setHistory((h) => [
                `${after - stock >= 0 ? "+ " : ""}${after - stock} · ${reason}`,
                ...h,
              ]);
              setStatus("Bestand in dieser Demo gebucht");
              setPanel(null);
            }}
          >
            Jetzt buchen
          </KButton>
        }
      >
        <KStack gap="action" align="stretch">
          <div className="ce-stock">
            {[
              ["Auf Lager", stock],
              ["Reserviert", reserved],
              ["Verfügbar", stock - reserved],
            ].map(([l, n]) => (
              <div key={l}>
                <small>{l}</small>
                <strong>{n}</strong>
              </div>
            ))}
          </div>
          <p className="ce-notice">
            <KIcon name="info" size={16} />
            Bestandsänderungen gelten sofort – unabhängig vom Speichern des
            Entwurfs. Hier nur als Demo.
          </p>
          <Choice
            label="Bestandsbewegung"
            value={movement}
            onChange={setMovement}
            items={[
              ["in", "Zugang"],
              ["out", "Abgang"],
              ["set", "Neu zählen"],
            ]}
          />
          <div className="ce-step">
            <KButton
              variant="secondary"
              aria-label="Menge verringern"
              onClick={() => setAmount(String(Math.max(0, Number(amount) - 1)))}
            >
              −
            </KButton>
            <KInput
              aria-label="Menge"
              type="number"
              min={0}
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
            />
            <KButton
              variant="secondary"
              aria-label="Menge erhöhen"
              onClick={() => setAmount(String(Number(amount) + 1))}
            >
              +
            </KButton>
          </div>
          <p className="ce-calculation">
            {stock} →{" "}
            <strong>{Number.isFinite(after) ? after : "–"} auf Lager</strong>
          </p>
          {!canBook && (
            <p className="ce-danger">
              Der Bestand darf nicht unter die reservierte Menge fallen. Bitte
              eine gültige ganze Menge eingeben.
            </p>
          )}
          <KSelect
            label="Grund"
            value={reason}
            onValueChange={setReason}
            options={["Lieferung", "Verkauf", "Korrektur", "Beschädigt"].map(
              (v) => ({ value: v, label: v }),
            )}
          />
          <h3>Letzte Bewegungen</h3>
          {history.slice(0, 4).map((h, i) => (
            <div className="ce-history" key={i}>
              {h}
            </div>
          ))}
        </KStack>
      </KAdaptiveDialog>
      <KAdaptiveDialog
        open={panel === "recommendations"}
        onOpenChange={(v) => !v && setPanel(null)}
        title="Dazu empfehlen"
        closeLabel="Schließen"
        className="sg-review ce-overlay"
        actions={<KButton onClick={() => setPanel(null)}>Fertig</KButton>}
      >
        <KStack gap="action" align="stretch">
          <KInput
            aria-label="Angebote suchen"
            placeholder="Angebote suchen"
            leading={<KIcon name="search" size={20} />}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
          <Choice
            label="Angebotsart"
            value={filter}
            onChange={setFilter}
            items={[
              ["all", "Alle"],
              ["service", "Leistungen"],
              ["product", "Produkte"],
            ]}
          />
          {catalog
            .filter(
              (c) =>
                (filter === "all" || c.kind === filter) &&
                c.name.toLocaleLowerCase().includes(search.toLocaleLowerCase()),
            )
            .map((c) => (
              <Row key={c.id} title={c.name} help={c.price}>
                <KCheckbox
                  label={`${c.name} empfehlen`}
                  value={draft.recommendations.includes(c.id)}
                  onValueChange={() => toggleRec(c.id)}
                />
              </Row>
            ))}
          {!catalog.some(
            (c) =>
              (filter === "all" || c.kind === filter) &&
              c.name.toLocaleLowerCase().includes(search.toLocaleLowerCase()),
          ) && (
            <KButton
              variant="ghost"
              onClick={() => {
                setSearch("");
                setFilter("all");
              }}
            >
              Keine Treffer – Suche zurücksetzen
            </KButton>
          )}
        </KStack>
      </KAdaptiveDialog>
      <KAdaptiveDialog
        open={panel === "archive" || panel === "discard"}
        onOpenChange={(v) => !v && setPanel(null)}
        title={
          panel === "archive" ? "Angebot archivieren?" : "Änderungen verwerfen?"
        }
        className="sg-review ce-overlay"
        closeLabel="Schließen"
        actions={
          <>
            <KButton variant="secondary" onClick={() => setPanel(null)}>
              Zurück
            </KButton>
            <KButton
              onClick={() => {
                if (panel === "discard") setDraft(structuredClone(saved));
                else {
                  change("active", false);
                  setStatus("In dieser Demo archiviert");
                }
                setPanel(null);
                if (panel === "discard") setOpen(false);
              }}
            >
              {panel === "archive" ? "Archivieren" : "Verwerfen"}
            </KButton>
          </>
        }
      >
        <p>
          {panel === "archive"
            ? "Das Angebot ist danach nicht mehr buchbar. Bestehende Termine bleiben erhalten."
            : "Deine Änderungen am Entwurf gehen verloren. Bereits gebuchte Bestandsänderungen bleiben erhalten."}
        </p>
      </KAdaptiveDialog>
      <KAdaptiveDialog
        open={panel === "category"}
        onOpenChange={(v) => !v && setPanel(null)}
        title="Neue Kategorie"
        className="sg-review ce-overlay"
        actions={
          <KButton
            disabled={!newCategory.trim()}
            onClick={() => {
              setCategories((c) => [...new Set([...c, newCategory.trim()])]);
              change("category", newCategory.trim());
              setNewCategory("");
              setPanel(null);
            }}
          >
            Anlegen
          </KButton>
        }
      >
        <KField label={<span className="ce-field-label">Name</span>}>
          <KInput
            value={newCategory}
            onChange={(e) => setNewCategory(e.target.value)}
          />
        </KField>
      </KAdaptiveDialog>
      <AvatarEditorFixture
        open={panel === "image"}
        onOpenChange={(v) => !v && setPanel(null)}
        onAvatarChange={(src) => change("image", src)}
      />
    </>
  );
}
