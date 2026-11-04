import { useState } from "react";
import {
  KAvatar,
  KText,
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
const euro = (n: number) =>
  new Intl.NumberFormat("de-DE", { style: "currency", currency: "EUR" }).format(
    n,
  );
const initialPayments = [
  {
    name: "Beatrice Romano",
    service: "Einzeltraining",
    day: "Heute · Di, 3. Nov",
    time: "08:20",
    amount: 85,
    state: "Zu bestätigen",
  },
  {
    name: "Riccardo Costa",
    service: "Mobilitäts-Session",
    day: "Heute · Di, 3. Nov",
    time: "11:20",
    amount: 65,
    state: "Zu bestätigen",
  },
  {
    name: "Elisa Ferrari",
    service: "Outdoor-Training",
    day: "Gestern · Mo, 2. Nov",
    time: "14:20",
    amount: 75,
    state: "Zu bestätigen",
  },
  {
    name: "Sara Villa",
    service: "Erstgespräch & erste Session",
    day: "Gestern · Mo, 2. Nov",
    time: "15:05",
    amount: 62.43,
    state: "Bezahlt",
  },
  {
    name: "Anna Riva",
    service: "Mobilitäts-Session",
    day: "Gestern · Mo, 2. Nov",
    time: "16:05",
    amount: 36.69,
    state: "Erstattet",
  },
  {
    name: "Leonardo Marino",
    service: "Erstgespräch",
    day: "Fr, 30. Okt",
    time: "10:00",
    amount: 36.69,
    state: "Bezahlt",
  },
  {
    name: "Francesco Rossi",
    service: "Outdoor-Training",
    day: "Fr, 30. Okt",
    time: "13:20",
    amount: 85,
    state: "Bezahlt",
  },
  {
    name: "Giulia Bianchi",
    service: "Mobilitäts-Session",
    day: "Do, 29. Okt",
    time: "09:45",
    amount: 36.69,
    state: "Abgelaufen",
  },
];
export function Payments() {
  const [payments, setPayments] = useState(initialPayments);
  const [filter, setFilter] = useState("Alle");
  const [checks, setChecks] = useState(false);
  const [providerOpen, setProviderOpen] = useState(false);
  const [selected, setSelected] = useState<
    (typeof initialPayments)[number] | null
  >(null);
  const todo = payments.filter((p) => p.state === "Zu bestätigen");
  const history = payments.filter(
    (p) =>
      p.state !== "Zu bestätigen" &&
      (filter === "Alle" ||
        p.state === filter ||
        (filter === "Andere" && p.state === "Abgelaufen")),
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
            <KButton variant="secondary" onClick={() => setProviderOpen(true)}>
              Öffnen <KIcon name="external-link" size={16} />
            </KButton>
          </div>
          <KButton variant="ghost" onClick={() => setChecks(!checks)}>
            Einrichtung abgeschlossen · 3 von 3{" "}
            <KIcon name={checks ? "chevron-down" : "chevron-right"} size={16} />
          </KButton>
          {checks && (
            <div className="sg-check-list">
              {[
                "Konto verbunden",
                "Angaben zum Business geprüft",
                "Auszahlungskonto hinterlegt",
              ].map((label) => (
                <span key={label}>
                  <KIcon name="circle-check" /> {label}
                </span>
              ))}
            </div>
          )}
        </div>
      </Group>
      <div className="sg-summary">
        <div>
          <strong>
            {euro(
              payments
                .filter((p) => p.state === "Bezahlt")
                .reduce((n, p) => n + p.amount, 0),
            )}
          </strong>
          <small>November</small>
        </div>
        <div>
          <strong>{todo.length}</strong>
          <small>zu bestätigen</small>
        </div>
        <div>
          <strong>1</strong>
          <small>erstattet</small>
        </div>
      </div>
      {todo.length > 0 && (
        <Group
          title="Zu bestätigen"
          footer="Bestätige, dass der Termin stattgefunden hat. Danach wird die Zahlung abgeschlossen."
        >
          {todo.map((p) => (
            <div className="sg-transaction" key={p.name}>
              <KAvatar alt={p.name} />
              <div>
                <strong>{p.name}</strong>
                <small>
                  {p.service} · {p.time} · {euro(p.amount)}
                </small>
              </div>
              <KButton
                onClick={() =>
                  setPayments((current) =>
                    current.map((item) =>
                      item.name === p.name
                        ? { ...item, state: "Bezahlt" }
                        : item,
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
      <KStack gap="control" align="stretch">
        <h2 className="sg-section-label">Buchungszahlungen</h2>
        <Choices
          items={["Alle", "Bezahlt", "Erstattet", "Andere"]}
          value={filter}
          onChange={setFilter}
        />
        {[...new Set(history.map((p) => p.day))].map((day) => (
          <Group key={day} title={day}>
            {history
              .filter((p) => p.day === day)
              .map((p) => (
                <KButton
                  key={p.name}
                  fullWidth
                  variant="ghost"
                  className="sg-row sg-payment-row"
                  onClick={() => setSelected(p)}
                >
                  <span className="sg-row-layout">
                    <KAvatar alt={p.name} />
                    <span className="sg-copy">
                      <strong>{p.name}</strong>
                      <small>
                        {p.service} · {p.time}
                      </small>
                    </span>
                    <span className="sg-amount">
                      <strong>{euro(p.amount)}</strong>
                      <small
                        className={`sg-status ${p.state === "Bezahlt" ? "sg-success" : ""}`}
                      >
                        {p.state}
                      </small>
                    </span>
                  </span>
                </KButton>
              ))}
          </Group>
        ))}
      </KStack>
      <KAdaptiveDialog
        open={providerOpen}
        onOpenChange={setProviderOpen}
        title="Stripe"
        closeLabel="Schließen"
      >
        <p>
          In der Anwendung öffnet diese Aktion dein Stripe-Dashboard. Diese
          Story verwendet ausschließlich Beispieldaten.
        </p>
      </KAdaptiveDialog>
      <KAdaptiveDialog
        open={!!selected}
        onOpenChange={(open) => {
          if (!open) setSelected(null);
        }}
        title="Zahlung"
        closeLabel="Schließen"
      >
        {selected && (
          <KStack gap="section" align="stretch">
            <KStack gap="control" align="center" className="sg-receipt-hero">
              <KText variant="caption">Buchungsbetrag</KText>
              <KText variant="heading2">{euro(selected.amount)}</KText>
              <span
                className={`sg-status ${selected.state === "Bezahlt" ? "sg-success" : ""}`}
              >
                {selected.state}
              </span>
            </KStack>
            <KStack gap="control" align="center">
              <KAvatar alt={selected.name} />
              <KText>{selected.name}</KText>
            </KStack>
            <Group title="Termin">
              {[
                ["Datum", selected.day],
                ["Uhrzeit", `${selected.time} Uhr`],
              ].map(([label, value]) => (
                <div className="sg-data-row" key={label}>
                  <KText>{label}</KText>
                  <KText style={{ textAlign: "end" }}>{value}</KText>
                </div>
              ))}
            </Group>
            <Group title="Leistungen">
              {[["Leistung", selected.service]].map(([label, value]) => (
                <div className="sg-data-row" key={label}>
                  <KText>{label}</KText>
                  <KText style={{ textAlign: "end" }}>{value}</KText>
                </div>
              ))}
            </Group>
            <Group title="Abrechnung">
              <div className="sg-data-row">
                <KText>Gesamtbetrag</KText>
                <KText>{euro(selected.amount)}</KText>
              </div>
            </Group>
          </KStack>
        )}
      </KAdaptiveDialog>
    </KStack>
  );
}
