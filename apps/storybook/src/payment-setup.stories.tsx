import { useEffect, useRef, useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KLink,
  KPaymentSetup,
  KStack,
  KText,
  type KPaymentSetupState,
  type KPaymentSetupStep,
} from "@k-design-system/ui";
import "./payment-setup-fixture.css";

const copy: Record<
  KPaymentSetupState,
  {
    label: string;
    title: string;
    description: string;
    action?: string;
    note: string;
  }
> = {
  connected: {
    label: "Verbindung hergestellt",
    title: "Mach dein Zahlungskonto startklar",
    description:
      "Dein Stripe-Konto ist mit Onzeit verbunden. Ergänze jetzt die Angaben, damit Kunden bei der Buchung bezahlen können.",
    action: "Einrichtung starten",
    note: "Halte deine Geschäfts-, Identitäts- und Bankdaten bereit.",
  },
  "action-required": {
    label: "Einrichtung offen",
    title: "Es fehlen noch ein paar Angaben",
    description:
      "Stripe benötigt noch Informationen zu deinem Unternehmen oder deinem Auszahlungskonto. Deine bisherigen Angaben bleiben erhalten.",
    action: "Einrichtung fortsetzen",
    note: "Stripe kann für die sichere Anmeldung ein eigenes Fenster öffnen.",
  },
  pending: {
    label: "In Prüfung",
    title: "Deine Angaben werden geprüft",
    description:
      "Alles wurde übermittelt. Stripe prüft dein Zahlungskonto; du musst derzeit nichts ergänzen.",
    note: "Zahlungen sind nach der Freigabe möglich. Prüfe den Status später erneut.",
  },
  "needs-correction": {
    label: "Angaben prüfen",
    title: "Stripe braucht eine Korrektur",
    description:
      "Deine Einrichtung wurde übermittelt. Stripe konnte einige Identitätsangaben nicht bestätigen und benötigt deine Prüfung.",
    action: "Angaben prüfen",
    note: "Dein Konto bleibt verbunden. Du beginnst nicht wieder von vorn.",
  },
  ready: {
    label: "Zahlungsbereit",
    title: "Dein Zahlungskonto ist bereit",
    description:
      "Kunden können ihre Buchung jetzt online bezahlen. Zahlungen und Auszahlungen findest du in deiner Übersicht.",
    action: "Zahlungen ansehen",
    note: "Auszahlungen erst nach erbrachter Leistung. Banklaufzeiten werden separat berücksichtigt.",
  },
};

function stepsFor(state: KPaymentSetupState): KPaymentSetupStep[] {
  const reviewing = state === "pending" || state === "ready";
  return [
    {
      id: "connection",
      label: "Verbindung",
      description: "Hergestellt",
      state: "complete",
    },
    {
      id: "setup",
      label: "Einrichtung",
      description:
        state === "needs-correction"
          ? "Korrektur nötig"
          : reviewing
            ? "Übermittelt"
            : "Angaben ergänzen",
      state:
        state === "needs-correction"
          ? "attention"
          : reviewing
            ? "complete"
            : "current",
    },
    {
      id: "verification",
      label: "Prüfung",
      description:
        state === "ready"
          ? "Freigegeben"
          : state === "pending"
            ? "Bei Stripe"
            : "Noch ausstehend",
      state:
        state === "ready"
          ? "complete"
          : state === "pending"
            ? "current"
            : "waiting",
    },
  ];
}

function PaymentSetupFixture({
  state = "needs-correction",
  longContent = false,
}: {
  state?: KPaymentSetupState;
  longContent?: boolean;
}) {
  const [current, setCurrent] = useState(state);
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState("");
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  useEffect(() => {
    setCurrent(state);
    setBusy(false);
    setNotice("");
    clearTimeout(timer.current);
  }, [state]);
  useEffect(() => () => clearTimeout(timer.current), []);
  const value = copy[current];
  const simulate = (next: KPaymentSetupState) => {
    setBusy(true);
    timer.current = setTimeout(() => {
      setCurrent(next);
      setBusy(false);
    }, 650);
  };
  return (
    <KStack gap="section" align="stretch" className="k-payment-setup-fixture">
      <KStack gap="control" align="stretch">
        <KText variant="heading2" as="h1">
          Zahlungen
        </KText>
        <KText variant="body" className="k-payment-setup-fixture__muted">
          Online bezahlt. Nach der Leistung ausgezahlt.
        </KText>
      </KStack>
      <KPaymentSetup
        state={current}
        providerName="Stripe"
        connectionLabel="Mit Onzeit verbunden"
        environmentLabel="Testmodus"
        statusLabel={value.label}
        title={
          longContent
            ? "Stripe benötigt eine erneute Prüfung deiner übermittelten Unternehmens- und Identitätsangaben"
            : value.title
        }
        description={value.description}
        note={value.note}
        steps={stepsFor(current)}
        stepsLabel="Einrichtung deines Zahlungskontos"
        primaryAction={
          value.action
            ? {
                label: value.action,
                loading: busy,
                icon: "arrow-right",
                onAction: () => {
                  if (current === "ready") {
                    setNotice(
                      "In der Anwendung öffnet sich jetzt die Zahlungsübersicht.",
                    );
                    return;
                  }
                  simulate(
                    current === "connected" ? "action-required" : "pending",
                  );
                },
              }
            : undefined
        }
        secondaryAction={
          current !== "connected"
            ? {
                label: "Status aktualisieren",
                icon: "refresh-cw",
                loading: current === "pending" && busy,
                disabled: current !== "pending" && busy,
                onAction: () =>
                  current === "pending"
                    ? simulate("ready")
                    : setNotice("Der angezeigte Status ist aktuell."),
              }
            : undefined
        }
        help={{
          title: "Testmodus: So funktioniert die Prüfung",
          content: (
            <KStack gap="control" align="stretch">
              <KText variant="bodySmall">
                Hier fließt kein echtes Geld. Stripe verwendet besondere
                Testdaten; normale Angaben können im Test bewusst als nicht
                bestätigt erscheinen.
              </KText>
              <KText variant="bodySmall">
                Für eine erfolgreiche simulierte Prüfung nennt Stripe zum
                Beispiel das Geburtsdatum 01.01.1901. Verwende Testdaten bewusst
                und nur in der Sandbox.
              </KText>
              <KLink
                href="https://docs.stripe.com/connect/testing#test-dates-of-birth"
                target="_blank"
                rel="noreferrer"
              >
                Offizielle Stripe-Testdaten ansehen
              </KLink>
            </KStack>
          ),
        }}
      />
      <KText
        variant="caption"
        className="k-payment-setup-fixture__muted"
        role="status"
      >
        {notice ||
          "Interaktive Storybook-Vorschau. Keine Verbindung zu Stripe; Zustandswechsel sind simuliert."}
      </KText>
    </KStack>
  );
}

const meta = {
  title: "Patterns/PaymentSetup",
  component: PaymentSetupFixture,
  parameters: { layout: "fullscreen" },
  args: { state: "needs-correction", longContent: false },
  argTypes: {
    state: {
      control: "select",
      options: [
        "connected",
        "action-required",
        "pending",
        "needs-correction",
        "ready",
      ],
    },
  },
} satisfies Meta<typeof PaymentSetupFixture>;
export default meta;
type Story = StoryObj<typeof meta>;

export const NeedsCorrection: Story = {
  name: "payment-setup-needs-correction",
  parameters: { fixtureId: "payment-setup-needs-correction" },
};
export const Connected: Story = {
  name: "payment-setup-connected",
  args: { state: "connected" },
  parameters: { fixtureId: "payment-setup-connected" },
};
export const ActionRequired: Story = {
  name: "payment-setup-action-required",
  args: { state: "action-required" },
  parameters: { fixtureId: "payment-setup-action-required" },
};
export const Pending: Story = {
  name: "payment-setup-pending",
  args: { state: "pending" },
  parameters: { fixtureId: "payment-setup-pending" },
};
export const Ready: Story = {
  name: "payment-setup-ready",
  args: { state: "ready" },
  parameters: { fixtureId: "payment-setup-ready" },
};
export const LongContent: Story = {
  name: "payment-setup-long-content",
  args: { longContent: true },
  parameters: { fixtureId: "payment-setup-long-content" },
};
