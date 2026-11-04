import { useState } from "react";
import {
  KAdaptiveDialog,
  KAvatar,
  KButton,
  KIcon,
  KStack,
} from "@k-design-system/ui";
import { Group } from "./settings-grouped-parts.js";
const initial = [
  {
    id: "demo-payment-1",
    name: "Beatrice Romano",
    service: "Einzeltraining",
    time: "08:20",
    day: "Heute · Di, 3. Nov",
    amount: 85,
    state: "Zu bestätigen",
  },
  {
    id: "demo-payment-2",
    name: "Riccardo Costa",
    service: "Mobilitäts-Session",
    time: "11:20",
    day: "Heute · Di, 3. Nov",
    amount: 65,
    state: "Zu bestätigen",
  },
  {
    id: "demo-payment-3",
    name: "Elisa Ferrari",
    service: "Einzeltraining",
    time: "11:50",
    day: "Heute · Di, 3. Nov",
    amount: 85,
    state: "Bezahlt",
  },
  {
    id: "demo-payment-4",
    name: "Luca Moretti",
    service: "Personal Training",
    time: "14:10",
    day: "Gestern · Mo, 2. Nov",
    amount: 95,
    state: "Erstattet",
  },
  {
    id: "demo-payment-5",
    name: "Anna Weber",
    service: "Mobilitäts-Session",
    time: "16:00",
    day: "Gestern · Mo, 2. Nov",
    amount: 65,
    state: "Abgelaufen",
  },
];
const eur = (n: number) =>
  new Intl.NumberFormat("de-DE", { style: "currency", currency: "EUR" }).format(
    n,
  );
export function OverhaulPayments({ empty }: { empty: boolean }) {
  const [payments, setPayments] = useState(empty ? [] : initial);
  const [filter, setFilter] = useState("Alle");
  const [checks, setChecks] = useState(false);
  const [selected, setSelected] = useState<(typeof initial)[number] | null>(
    null,
  );
  const [provider, setProvider] = useState(false);
  const [message, setMessage] = useState("");
  const todo = payments.filter((p) => p.state === "Zu bestätigen");
  const list = payments.filter(
    (p) =>
      p.state !== "Zu bestätigen" &&
      (filter === "Alle" ||
        p.state === filter ||
        (filter === "Abgelaufen & abgebrochen" && p.state === "Abgelaufen")),
  );
  return (
    <KStack gap="section" align="stretch">
      <span className="sg-status sg-warning">Testmodus · Beispieldaten</span>
      <Group title="">
        <div className="sg-inset">
          <div className="sg-payment-status">
            <span className="sg-provider-icon">S</span>
            <div>
              <strong>Stripe</strong>
              <small className="sg-success">✓ Verbunden</small>
              <small>Auszahlungen aktiv</small>
            </div>
            <KButton variant="secondary" onClick={() => setProvider(true)}>
              Öffnen
              <KIcon name="external-link" size={16} />
            </KButton>
          </div>
          <KButton variant="ghost" onClick={() => setChecks(!checks)}>
            Einrichtung abgeschlossen · 3 von 3
            <KIcon name={checks ? "chevron-down" : "chevron-right"} size={16} />
          </KButton>
          {checks && (
            <ul className="so-checklist">
              {[
                "Konto verbunden",
                "Angaben zum Business geprüft",
                "Auszahlungskonto hinterlegt",
              ].map((v) => (
                <li key={v}>
                  <KIcon name="circle-check" size={20} />
                  {v}
                </li>
              ))}
            </ul>
          )}
        </div>
      </Group>
      <div className="so-payment-summary">
        <div>
          <b>
            {eur(
              payments
                .filter((p) => p.state === "Bezahlt")
                .reduce((s, p) => s + p.amount, 0),
            )}
          </b>
          <small>November</small>
        </div>
        <div>
          <b>{todo.length}</b>
          <small>zu bestätigen</small>
        </div>
        <div>
          <b>{payments.filter((p) => p.state === "Erstattet").length}</b>
          <small>erstattet</small>
        </div>
      </div>
      {!!todo.length && (
        <Group
          title="Zu bestätigen"
          footer="Bestätige, dass der Termin stattgefunden hat. In dieser Galerie wird nur der Beispielstatus geändert."
        >
          {todo.map((p) => (
            <div className="so-payment-todo" key={p.id}>
              <KAvatar alt={p.name} />
              <span>
                <b>{p.name}</b>
                <small>
                  {p.service} · {p.time} · {eur(p.amount)}
                </small>
              </span>
              <KButton
                onClick={() =>
                  setPayments((v) =>
                    v.map((x) =>
                      x.id === p.id ? { ...x, state: "Bezahlt" } : x,
                    ),
                  )
                }
              >
                Bestätigen
              </KButton>
            </div>
          ))}
        </Group>
      )}
      <section>
        <h2 className="so-section-title">Buchungszahlungen</h2>
        <div className="so-filters">
          {["Alle", "Bezahlt", "Erstattet", "Abgelaufen & abgebrochen"].map(
            (v) => (
              <KButton
                variant={filter === v ? "primary" : "secondary"}
                aria-pressed={filter === v}
                key={v}
                onClick={() => setFilter(v)}
              >
                {v}
              </KButton>
            ),
          )}
        </div>
        <KStack gap="action" align="stretch">
          {[...new Set(list.map((p) => p.day))].map((day) => (
            <Group key={day} title={day}>
              {list
                .filter((p) => p.day === day)
                .map((p) => (
                  <div className="so-payment-row" key={p.id}>
                    <span className="so-payment-grid" aria-hidden="true">
                      <KAvatar alt={p.name} />
                      <span className="so-payment-copy">
                        <b>{p.name}</b>
                        <small>
                          {p.service} · {p.time}
                        </small>
                      </span>
                      <span className="so-payment-right">
                        <b>{eur(p.amount)}</b>
                        <span
                          className={`sg-status ${p.state === "Bezahlt" ? "sg-success" : ""}`}
                        >
                          {p.state}
                        </span>
                      </span>
                    </span>
                    <KButton
                      fullWidth
                      variant="ghost"
                      className="so-payment-hit"
                      aria-label={`${p.name}, ${p.service}, ${p.time}, ${eur(p.amount)}, ${p.state}`}
                      onClick={() => setSelected(p)}
                    >
                      {""}
                    </KButton>
                  </div>
                ))}
            </Group>
          ))}
          {!list.length && (
            <Group title="">
              <p className="sg-inset so-muted">
                {empty
                  ? "Noch keine Buchungszahlungen. Sobald jemand online bezahlt, siehst du es hier."
                  : "Keine Zahlungen mit diesem Status."}
              </p>
            </Group>
          )}
        </KStack>
      </section>
      <KAdaptiveDialog
        open={!!selected}
        title="Zahlung"
        closeLabel="Schließen"
        onOpenChange={(v) => {
          if (!v) {
            setSelected(null);
            setMessage("");
          }
        }}
      >
        {selected && (
          <>
            <Group title="">
              {[
                ["Kund:in", selected.name],
                ["Leistung", selected.service],
                ["Termin", `${selected.day}, ${selected.time}`],
                ["Betrag", eur(selected.amount)],
                ["Status", selected.state],
                ...(selected.state === "Erstattet"
                  ? [["Erstattet", eur(selected.amount)]]
                  : []),
              ].map(([k, v]) => (
                <div key={k} className="so-detail-row">
                  <span>{k}</span>
                  <strong>{v}</strong>
                </div>
              ))}
              <div className="so-detail-row">
                <span>
                  Buchungs-ID<small>{selected.id}</small>
                </span>
                <KButton
                  variant="ghost"
                  aria-label="Buchungs-ID kopieren"
                  onClick={() =>
                    void navigator.clipboard.writeText(selected.id).then(
                      () => setMessage("Buchungs-ID kopiert."),
                      () =>
                        setMessage(
                          "Kopieren nicht verfügbar; die ID steht darüber.",
                        ),
                    )
                  }
                >
                  <KIcon name="copy" size={20} />
                </KButton>
              </div>
            </Group>
            <p className="so-muted">Plattformgebühr: keine · Beispieldaten</p>
            {message && <p role="status">{message}</p>}
          </>
        )}
      </KAdaptiveDialog>
      <KAdaptiveDialog
        open={provider}
        title="Stripe-Dashboard"
        closeLabel="Schließen"
        onOpenChange={setProvider}
      >
        <p>
          Die Anwendung öffnet hier dein Stripe-Konto. Diese Galerie verbindet
          sich nicht mit einem Zahlungsanbieter.
        </p>
      </KAdaptiveDialog>
    </KStack>
  );
}
