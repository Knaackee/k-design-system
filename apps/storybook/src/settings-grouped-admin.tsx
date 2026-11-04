import { useState } from "react";
import {
  KAvatar,
  KText,
  KInline,
  KButton,
  KIcon,
  KStack,
  KField,
  KInput,
  KSelect,
  KCheckbox,
  KTextarea,
  KAdaptiveDialog,
} from "@k-design-system/ui";
import { Group, Row } from "./settings-grouped-parts.js";

import { Choices } from "./settings-grouped-choices.js";
const requests = [
  {
    name: "Lea Schmidt",
    mail: "lea@example.com",
    job: "Friseurin",
    city: "Leipzig",
    priority: 5,
  },
  {
    name: "Mira Weber",
    mail: "mira@example.com",
    job: "Nails",
    city: "Hamburg",
    priority: 4,
  },
  {
    name: "Tom Fischer",
    mail: "tom@example.com",
    job: "Personal Training",
    city: "München",
    priority: 5,
  },
  {
    name: "Sophie Berger",
    mail: "sophie@example.com",
    job: "Massage",
    city: "Wien",
    priority: 3,
  },
];
export function Access({ empty = false }: { empty?: boolean }) {
  const [mode, setMode] = useState("Nur mit Einladung");
  const [filter, setFilter] = useState("Neu");
  const [selected, setSelected] = useState<string[]>([]);
  const [states, setStates] = useState<Record<string, string>>({});
  const [sort, setSort] = useState(true);
  const [message, setMessage] = useState("");
  const items = (empty ? [] : requests)
    .filter((r) => (states[r.mail] ?? "Neu") === filter)
    .sort((a, b) => (sort ? b.priority - a.priority : 0));
  function update(mail: string, state: string) {
    setStates((v) => ({ ...v, [mail]: state }));
    setSelected((v) => v.filter((x) => x !== mail));
  }
  return (
    <KStack gap="section" align="stretch">
      <Group
        title="Neue Konten"
        footer={
          mode === "Offen"
            ? "Jede:r kann sich registrieren."
            : mode === "Geschlossen"
              ? "Keine neuen Konten. Bestehende Konten können sich weiter anmelden."
              : "Neue Konten brauchen eine gültige Einladung. Bestehende Konten können sich weiter anmelden."
        }
      >
        <Choices
          items={["Offen", "Nur mit Einladung", "Geschlossen"]}
          value={mode}
          onChange={setMode}
        />
      </Group>
      <KStack gap="control" align="stretch">
        <div className="sg-section-heading">
          <h2 className="sg-section-label">Einladungsanfragen</h2>
          <KButton variant="ghost" onClick={() => setSort(!sort)}>
            Sortieren: {sort ? "Priorität" : "Neueste"}
          </KButton>
        </div>
        <Choices
          items={["Neu", "Eingeladen", "Abgelehnt"]}
          value={filter}
          onChange={(v) => {
            setFilter(v);
            setSelected([]);
          }}
        />
        <Group title="">
          {items.map((r) => (
            <div className="sg-request" key={r.mail}>
              {filter === "Neu" && (
                <KCheckbox
                  label={`Auswählen: ${r.name}`}
                  className="sg-selection"
                  value={selected.includes(r.mail)}
                  onValueChange={(checked) =>
                    setSelected((v) =>
                      checked ? [...v, r.mail] : v.filter((x) => x !== r.mail),
                    )
                  }
                />
              )}
              <div className="sg-request-copy">
                <strong>{r.mail}</strong>
                <small>
                  {r.job} · {r.city}
                </small>
                <span
                  className="sg-priority"
                  aria-label={`Priorität ${r.priority} von 5`}
                >
                  {[1, 2, 3, 4, 5].map((n) => (
                    <i key={n} data-active={n <= r.priority} />
                  ))}
                </span>
                <small>heute, 09:12</small>
              </div>
              {filter === "Neu" ? (
                <div className="sg-actions">
                  <KButton
                    variant="secondary"
                    className="sg-danger"
                    aria-label={`${r.name} ablehnen`}
                    onClick={() => update(r.mail, "Abgelehnt")}
                  >
                    <KIcon name="x" size={18} />
                  </KButton>
                  <KButton
                    aria-label={`${r.name} einladen`}
                    onClick={() => update(r.mail, "Eingeladen")}
                  >
                    <KIcon name="send" size={18} />
                  </KButton>
                </div>
              ) : filter === "Eingeladen" ? (
                <KButton
                  variant="secondary"
                  onClick={() =>
                    setMessage("Einladung in der Vorschau erneut gesendet.")
                  }
                >
                  Erneut senden
                </KButton>
              ) : null}
            </div>
          ))}
          {!items.length && <p className="sg-inset">Keine Anfragen.</p>}
        </Group>
        {selected.length > 0 && (
          <div className="sg-savebar">
            <strong>{selected.length} ausgewählt</strong>
            <KButton
              onClick={() => {
                setStates((v) => ({
                  ...v,
                  ...Object.fromEntries(
                    selected.map((mail) => [mail, "Eingeladen"]),
                  ),
                }));
                setSelected([]);
              }}
            >
              Alle einladen
            </KButton>
          </div>
        )}
        <p className="sg-muted">
          Priorität ergibt sich aus den Angaben nach der Anmeldung und aus
          angenommenen Empfehlungen. Alle Aktionen sind lokal simuliert.
        </p>
        {message && <p role="status">{message}</p>}
      </KStack>
    </KStack>
  );
}
export function Assistant() {
  const initial = {
    provider: "OpenRouter",
    model: "Beispielmodell",
    prompt:
      "Du bist der persönliche Assistent des angemeldeten Onzeit-Nutzers. Antworte präzise und verwende nur bereitgestellte Werkzeuge und Daten.",
  };
  const [saved, setSaved] = useState(initial);
  const [draft, setDraft] = useState(initial);
  const [key, setKey] = useState<string | null>(null);
  const [answer, setAnswer] = useState(false);
  const dirty = JSON.stringify(draft) !== JSON.stringify(saved) || !!key;
  return (
    <KStack gap="section" align="stretch">
      <KInline gap="control">
        <KText variant="heading2">KI-Assistent</KText>
        <span className="sg-status sg-admin-badge">Admin</span>
      </KInline>
      <p className="sg-muted sg-admin-intro">
        Gilt für alle Nutzer:innen dieses Servers. Designvorschau ohne
        Serververbindung.
      </p>
      <Group title="Modell und Verbindung">
        <KStack className="sg-inset" gap="action" align="stretch">
          <KField label="Anbieter">
            <KSelect
              aria-label="Anbieter"
              value={draft.provider}
              options={["OpenRouter", "Anthropic", "OpenAI"].map((value) => ({
                value,
                label: value,
              }))}
              onValueChange={(provider) => setDraft({ ...draft, provider })}
            />
          </KField>
          <KField label="Modell">
            <KInput
              value={draft.model}
              onChange={(e) => setDraft({ ...draft, model: e.target.value })}
            />
          </KField>
          <KField label="API-Schlüssel">
            {key === null ? (
              <div className="sg-field-status">
                <span className="sg-status sg-success">Hinterlegt · Demo</span>
                <KButton variant="ghost" onClick={() => setKey("")}>
                  Ersetzen
                </KButton>
              </div>
            ) : (
              <KInput
                type="password"
                value={key}
                placeholder="Nur Testwert eingeben"
                onChange={(e) => setKey(e.target.value)}
              />
            )}
          </KField>
        </KStack>
      </Group>
      <KStack gap="control" align="stretch">
        <div className="sg-prompt-heading">
          <h2 className="sg-section-label">Systemanweisung</h2>
          <span className="sg-muted">{draft.prompt.length} Zeichen</span>
        </div>
        <KTextarea
          aria-label="Systemanweisung"
          value={draft.prompt}
          onChange={(e) => setDraft({ ...draft, prompt: e.target.value })}
        />
        <div className="sg-actions">
          <KButton variant="secondary" onClick={() => setAnswer(true)}>
            <KIcon name="play" />
            Testen
          </KButton>
          <span className="sg-muted">
            Schickt eine Beispielfrage mit den aktuellen Einstellungen.
          </span>
        </div>
      </KStack>
      {answer && (
        <div className="sg-inset sg-answer">
          <small>Beispielantwort auf „Was steht heute an?“</small>
          <p>
            Heute hast du 4 bestätigte Termine. Der nächste ist um 11:50 bei
            Elisa Ferrari, 18 Minuten Fahrt.
          </p>
        </div>
      )}
      {dirty && (
        <div className="sg-savebar">
          <strong>Ungespeicherte Änderungen</strong>
          <KButton
            variant="secondary"
            onClick={() => {
              setDraft(saved);
              setKey(null);
            }}
          >
            Verwerfen
          </KButton>
          <KButton
            onClick={() => {
              setSaved(draft);
              setKey(null);
            }}
          >
            Speichern
          </KButton>
        </div>
      )}
    </KStack>
  );
}
