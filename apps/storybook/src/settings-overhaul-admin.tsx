import { useState } from "react";
import {
  KButton,
  KCheckbox,
  KField,
  KIcon,
  KInput,
  KSelect,
  KStack,
  KTextarea,
} from "@k-design-system/ui";
import { Group } from "./settings-grouped-parts.js";

const inviteFixtures = [
  {
    id: "lea",
    mail: "lea@example.com",
    job: "Friseurin",
    city: "Leipzig, Deutschland",
    priority: 5,
    date: "Heute, 09:12",
    state: "Neu",
  },
  {
    id: "mira",
    mail: "mira@example.com",
    job: "Nail Artist",
    city: "Hamburg, Deutschland",
    priority: 4,
    date: "Heute, 08:46",
    state: "Neu",
  },
  {
    id: "tom",
    mail: "tom@example.com",
    job: "Personal Training",
    city: "Berlin, Deutschland",
    priority: 5,
    date: "Gestern, 17:20",
    state: "Eingeladen",
  },
  {
    id: "sophie",
    mail: "sophie@example.com",
    job: "Massage",
    city: "Wien, Österreich",
    priority: 3,
    date: "2. Nov, 11:10",
    state: "Eingelöst",
  },
];
export function OverhaulAccess({ empty }: { empty: boolean }) {
  const [mode, setMode] = useState("Nur mit Einladung");
  const [requests, setRequests] = useState(empty ? [] : inviteFixtures);
  const [filter, setFilter] = useState("Neu");
  const [sort, setSort] = useState(true);
  const [selected, setSelected] = useState<string[]>([]);
  const [notice, setNotice] = useState("");
  const update = (ids: string[], state: string) => {
    setRequests((r) =>
      r.map((v) => (ids.includes(v.id) ? { ...v, state } : v)),
    );
    setSelected([]);
    setNotice(
      "Nur der Beispielstatus wurde geändert; es wird keine E-Mail versendet.",
    );
  };
  const filtered = requests
    .filter((r) => r.state === filter)
    .sort((a, b) => (sort ? b.priority - a.priority : 0));
  return (
    <KStack gap="section" align="stretch">
      <section>
        <h2 className="so-section-title">Neue Konten</h2>
        <div className="so-segments">
          {["Offen", "Nur mit Einladung", "Geschlossen"].map((v) => (
            <KButton
              key={v}
              fullWidth
              variant={mode === v ? "secondary" : "ghost"}
              aria-pressed={mode === v}
              onClick={() => setMode(v)}
            >
              {v}
            </KButton>
          ))}
        </div>
        <p className="so-muted">
          {mode === "Offen"
            ? "Jede:r kann sich registrieren."
            : mode === "Geschlossen"
              ? "Keine neuen Konten. Bestehende Konten können sich weiter anmelden."
              : "Neue Konten brauchen eine gültige Einladung. Bestehende Konten können sich weiter anmelden."}
        </p>
      </section>
      <section>
        <div className="so-admin-heading">
          <h2 className="so-section-title">Einladungsanfragen</h2>
          <KButton variant="ghost" onClick={() => setSort(!sort)}>
            Sortieren: {sort ? "Priorität" : "Neueste"}
          </KButton>
        </div>
        <div className="so-filters">
          {["Neu", "Eingeladen", "Eingelöst", "Abgelehnt"].map((v) => (
            <KButton
              key={v}
              variant={v === filter ? "primary" : "secondary"}
              aria-pressed={v === filter}
              onClick={() => {
                setFilter(v);
                setSelected([]);
              }}
            >
              {v} · {requests.filter((r) => r.state === v).length}
            </KButton>
          ))}
        </div>
        <Group title="">
          {filtered.map((r) => (
            <div key={r.id} className="so-request">
              <div className="so-request-select">
                {filter === "Neu" ? (
                  <KCheckbox
                    label=""
                    aria-label={`Auswählen: ${r.mail}`}
                    value={selected.includes(r.id)}
                    className="so-request-checkbox"
                    onValueChange={(v) =>
                      setSelected((s) =>
                        v ? [...s, r.id] : s.filter((id) => id !== r.id),
                      )
                    }
                  />
                ) : (
                  <KIcon
                    name={
                      filter === "Eingelöst"
                        ? "user"
                        : filter === "Abgelehnt"
                          ? "x"
                          : "send"
                    }
                    size={18}
                  />
                )}
              </div>
              <div className="so-request-copy">
                <strong>{r.mail}</strong>
                <small>
                  {r.job} · {r.city}
                </small>
                <div className="so-request-meta">
                  <span
                    className="sg-priority"
                    aria-label={`Priorität ${r.priority} von 5`}
                  >
                    {[1, 2, 3, 4, 5].map((n) => (
                      <i key={n} data-active={n <= r.priority} />
                    ))}
                  </span>
                  <small>{r.date}</small>
                </div>
              </div>
              {filter === "Neu" ? (
                <div className="so-request-actions">
                  <KButton
                    variant="ghost"
                    className="sg-danger"
                    aria-label={`${r.mail} ablehnen`}
                    onClick={() => update([r.id], "Abgelehnt")}
                  >
                    <KIcon name="x" size={18} />
                  </KButton>
                  <KButton
                    variant="ghost"
                    aria-label={`${r.mail} einladen`}
                    onClick={() => update([r.id], "Eingeladen")}
                  >
                    <KIcon name="send" size={18} />
                  </KButton>
                </div>
              ) : filter === "Eingeladen" ? (
                <KButton
                  variant="secondary"
                  className="so-request-actions"
                  onClick={() =>
                    setNotice(
                      "Erneut senden simuliert; keine E-Mail versendet.",
                    )
                  }
                >
                  Erneut senden
                </KButton>
              ) : null}
            </div>
          ))}
          {!filtered.length && (
            <p className="sg-inset so-muted">
              {empty
                ? "Noch keine Anfragen. Sobald sich jemand auf der Warteliste einträgt, erscheint die Anfrage hier."
                : "Keine Anfragen in diesem Status."}
            </p>
          )}
        </Group>
        <p className="so-muted">
          Priorität ergibt sich aus den Angaben nach der Anmeldung (Beruf,
          Region, Arbeitsweise, Team, Social-Profil) und aus angenommenen
          Empfehlungen.
        </p>
      </section>
      {!!selected.length && (
        <div className="so-savebar">
          <strong>{selected.length} ausgewählt</strong>
          <KButton onClick={() => update(selected, "Eingeladen")}>
            Ausgewählte einladen
          </KButton>
        </div>
      )}
      {notice && (
        <p role="status" className="so-muted">
          {notice}
        </p>
      )}
    </KStack>
  );
}

const initial = {
  provider: "OpenRouter",
  model: "Demo-Modell",
  prompt:
    "Du bist der persönliche Assistent des angemeldeten Onzeit-Nutzers. Antworte präzise und verwende nur bereitgestellte Werkzeuge und Daten.",
};
export function OverhaulAssistant({ empty }: { empty: boolean }) {
  const [draft, setDraft] = useState(initial);
  const [saved, setSaved] = useState(initial);
  const [key, setKey] = useState<string | null>(empty ? "" : null);
  const [hasKey, setHasKey] = useState(!empty);
  const [answer, setAnswer] = useState(false);
  const dirty = JSON.stringify(draft) !== JSON.stringify(saved) || !!key;
  return (
    <KStack gap="section" align="stretch">
      <p className="so-muted">
        Gilt für alle Nutzer:innen dieses Servers. Designvorschau ohne
        Serververbindung – bitte keine echten Schlüssel eingeben.
      </p>
      <Group title="Modell und Verbindung">
        <KStack gap="action" className="sg-inset" align="stretch">
          <KField label="Anbieter">
            <KSelect
              value={draft.provider}
              onValueChange={(provider) =>
                setDraft((v) => ({ ...v, provider }))
              }
              options={["OpenRouter", "Anthropic", "OpenAI"].map((value) => ({
                value,
                label: value,
              }))}
            />
          </KField>
          <KField label="Modell">
            <KSelect
              value={draft.model}
              onValueChange={(model) => setDraft((v) => ({ ...v, model }))}
              options={[
                "Demo-Modell",
                "Schnelles Beispielmodell",
                "Leistungsstarkes Beispielmodell",
              ].map((value) => ({ value, label: value }))}
            />
          </KField>
          <KField label="API-Schlüssel">
            {key === null ? (
              <div className="sg-field-status">
                <span className="sg-status sg-success">
                  <KIcon name="check" size={14} />
                  Hinterlegt · Demo
                </span>
                <span className="so-muted">••••••••</span>
                <KButton variant="ghost" onClick={() => setKey("")}>
                  Ersetzen
                </KButton>
              </div>
            ) : (
              <KStack gap="control" align="stretch">
                {!hasKey && (
                  <span className="sg-status sg-warning">
                    Nicht eingerichtet
                  </span>
                )}
                <KInput
                  type="password"
                  autoComplete="off"
                  value={key}
                  placeholder="Nur einen Testwert einfügen"
                  onChange={(e) => setKey(e.target.value)}
                />
              </KStack>
            )}
          </KField>
        </KStack>
      </Group>
      <section>
        <div className="so-admin-heading">
          <h2 className="so-section-title">Systemanweisung</h2>
          <span className="so-muted">{draft.prompt.length} Zeichen</span>
        </div>
        <KTextarea
          aria-label="Systemanweisung"
          className="so-prompt"
          value={draft.prompt}
          onChange={(e) => setDraft((v) => ({ ...v, prompt: e.target.value }))}
        />
        <div className="so-test-row">
          <KButton variant="secondary" onClick={() => setAnswer(true)}>
            <KIcon name="play" size={15} />
            Testen
          </KButton>
          <span className="so-muted">
            Zeigt eine Beispielantwort mit den aktuellen Demo-Einstellungen.
          </span>
        </div>
        {answer && (
          <div className="sg-answer sg-inset">
            <small>Beispielfrage: „Was steht heute an?“</small>
            <p>
              Heute hast du 4 bestätigte Termine. Der nächste ist um 11:50 bei
              Elisa Ferrari (Mobilitäts-Session), 18 Minuten Fahrt.
            </p>
          </div>
        )}
      </section>
      {dirty && (
        <div className="so-savebar">
          <strong>Ungespeicherte Änderungen</strong>
          <KButton
            variant="secondary"
            onClick={() => {
              setDraft(saved);
              setKey(hasKey ? null : "");
            }}
          >
            Verwerfen
          </KButton>
          <KButton
            onClick={() => {
              setSaved(draft);
              if (key) setHasKey(true);
              setKey(key || hasKey ? null : "");
            }}
          >
            Speichern
          </KButton>
        </div>
      )}
    </KStack>
  );
}
