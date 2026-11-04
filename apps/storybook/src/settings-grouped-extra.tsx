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

import { Payments } from "./settings-grouped-payments.js";
import { Access, Assistant } from "./settings-grouped-admin.js";
// Claude artwork: Simple Icons (CC0), matching the live Web fixture.
const claudeMark =
  "m4.7144 15.9555 4.7174-2.6471.079-.2307-.079-.1275h-.2307l-.7893-.0486-2.6956-.0729-2.3375-.0971-2.2646-.1214-.5707-.1215-.5343-.7042.0546-.3522.4797-.3218.686.0608 1.5179.1032 2.2767.1578 1.6514.0972 2.4468.255h.3886l.0546-.1579-.1336-.0971-.1032-.0972L6.973 9.8356l-2.55-1.6879-1.3356-.9714-.7225-.4918-.3643-.4614-.1578-1.0078.6557-.7225.8803.0607.2246.0607.8925.686 1.9064 1.4754 2.4893 1.8336.3643.3035.1457-.1032.0182-.0728-.164-.2733-1.3539-2.4467-1.445-2.4893-.6435-1.032-.17-.6194c-.0607-.255-.1032-.4674-.1032-.7285L6.287.1335 6.6997 0l.9957.1336.419.3642.6192 1.4147 1.0018 2.2282 1.5543 3.0296.4553.8985.2429.8318.091.255h.1579v-.1457l.1275-1.706.2368-2.0947.2307-2.6957.0789-.7589.3764-.9107.7468-.4918.5828.2793.4797.686-.0668.4433-.2853 1.8517-.5586 2.9021-.3643 1.9429h.2125l.2429-.2429.9835-1.3053 1.6514-2.0643.7286-.8196.85-.9046.5464-.4311h1.0321l.759 1.1293-.34 1.1657-1.0625 1.3478-.8804 1.1414-1.2628 1.7-.7893 1.36.0729.1093.1882-.0183 2.8535-.607 1.5421-.2794 1.8396-.3157.8318.3886.091.3946-.3278.8075-1.967.4857-2.3072.4614-3.4364.8136-.0425.0304.0486.0607 1.5482.1457.6618.0364h1.621l3.0175.2247.7892.522.4736.6376-.079.4857-1.2142.6193-1.6393-.3886-3.825-.9107-1.3113-.3279h-.1822v.1093l1.0929 1.0686 2.0035 1.8092 2.5075 2.3314.1275.5768-.3218.4554-.34-.0486-2.2039-1.6575-.85-.7468-1.9246-1.621h-.1275v.17l.4432.6496 2.3436 3.5214.1214 1.0807-.17.3521-.6071.2125-.6679-.1214-1.3721-1.9246L14.38 17.959l-1.1414-1.9428-.1397.079-.674 7.2552-.3156.3703-.7286.2793-.6071-.4614-.3218-.7468.3218-1.4753.3886-1.9246.3157-1.53.2853-1.9004.17-.6314-.0121-.0425-.1397.0182-1.4328 1.9672-2.1796 2.9446-1.7243 1.8456-.4128.164-.7164-.3704.0667-.6618.4008-.5889 2.386-3.0357 1.4389-1.882.929-1.0868-.0062-.1579h-.0546l-6.3385 4.1164-1.1293.1457-.4857-.4554.0608-.7467.2307-.2429 1.9064-1.3114Z";
function Integrations() {
  const [client, setClient] = useState("");
  const [step, setStep] = useState(1);
  const [name, setName] = useState("");
  const [expiry, setExpiry] = useState("90 Tage");
  const [tokens, setTokens] = useState(["Laptop"]);
  const [copied, setCopied] = useState(false);
  const config = `# Vorschau – kein gültiger Schlüssel\nServer: https://onzeit.example/mcp\nAuthorization: Bearer demo-not-a-real-token`;
  return (
    <KStack gap="section" align="stretch">
      <p className="sg-muted">
        Verbinde KI-Assistenten wie Claude Code oder Codex mit deinem
        Onzeit-Konto.
      </p>
      <Group title="Neuen Assistenten verbinden">
        <div className="sg-inset">
          <div className="sg-step-track">
            {[1, 2, 3].map((n) => (
              <span key={n} data-active={step >= n} />
            ))}
          </div>
          {step === 1 ? (
            <>
              <p>Welchen Assistenten willst du verbinden?</p>
              <div className="sg-clients">
                {["Claude Code", "Codex", "Andere"].map((c, i) => (
                  <KButton
                    key={c}
                    variant="secondary"
                    className="sg-client"
                    onClick={() => {
                      setClient(c);
                      setName(`${c} · Laptop`);
                      setStep(2);
                    }}
                  >
                    <span>
                      <i data-client={i}>
                        {i === 0 ? (
                          <svg
                            aria-hidden="true"
                            viewBox="0 0 24 24"
                            width="24"
                            height="24"
                          >
                            <path d={claudeMark} fill="currentColor" />
                          </svg>
                        ) : (
                          <KIcon
                            name={i === 1 ? "terminal" : "ellipsis"}
                            size={24}
                          />
                        )}
                      </i>
                      {c}
                    </span>
                  </KButton>
                ))}
              </div>
            </>
          ) : step === 2 ? (
            <KStack gap="action" align="stretch">
              <KField label="Name des Zugangs">
                <KInput
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                />
              </KField>
              <KSelect
                label="Gültig für"
                value={expiry}
                onValueChange={setExpiry}
                options={["30 Tage", "90 Tage", "1 Jahr"].map((value) => ({
                  value,
                  label: value,
                }))}
              />
              <div className="sg-actions">
                <KButton variant="secondary" onClick={() => setStep(1)}>
                  Zurück
                </KButton>
                <KButton
                  disabled={!name.trim()}
                  onClick={() => {
                    setTokens([...tokens, name]);
                    setStep(3);
                  }}
                >
                  Zugang erstellen
                </KButton>
              </div>
            </KStack>
          ) : (
            <KStack gap="action" align="stretch">
              <p className="sg-status sg-warning">
                Dieser Schlüssel wird nur jetzt angezeigt. Hier handelt es sich
                um einen Demo-Schlüssel.
              </p>
              <strong>Konfiguration für {client}</strong>
              <pre className="sg-code">{config}</pre>
              <KButton
                variant="secondary"
                onClick={() =>
                  void navigator.clipboard
                    .writeText(config)
                    .then(() => setCopied(true))
                }
              >
                {copied ? "Kopiert" : "Konfiguration kopieren"}
              </KButton>
              <KButton
                onClick={() => {
                  setStep(1);
                  setCopied(false);
                }}
              >
                Fertig
              </KButton>
            </KStack>
          )}
        </div>
      </Group>
      <Group title="Deine Zugänge">
        {tokens.map((token, i) => (
          <div className="sg-data-row" key={`${token}-${i}`}>
            <span>
              {token}
              <small>Demo-Zugang · {expiry}</small>
            </span>
            <KButton
              className="sg-danger"
              variant="secondary"
              onClick={() => setTokens(tokens.filter((_, n) => n !== i))}
            >
              Widerrufen
            </KButton>
          </div>
        ))}
        {!tokens.length && <p className="sg-inset">Noch keine Zugänge.</p>}
      </Group>
    </KStack>
  );
}
function About() {
  const [status, setStatus] = useState("Auf dem neuesten Stand");
  const [dialog, setDialog] = useState<string | null>(null);
  return (
    <KStack gap="section" align="stretch">
      <Group title="">
        <div className="sg-inset sg-version">
          <strong>Onzeit</strong>
          <p>Version 0.1.0+1 · Galerie</p>
          <span className="sg-status sg-success">
            <KIcon name="check" size={16} />
            {status}
          </span>
        </div>
        <Row
          title="Nach Updates suchen"
          icon="refresh-cw"
          onClick={() => setStatus("Keine neue Version · Demo")}
        />
      </Group>
      {[
        ["Hilfe", ["Hilfe & Anleitungen", "Feedback senden"]],
        [
          "Rechtliches",
          ["Impressum", "Datenschutz", "AGB", "Open-Source-Lizenzen"],
        ],
      ].map(([title, items]) => (
        <Group key={title as string} title={title as string}>
          {(items as string[]).map((label) => (
            <Row key={label} title={label} onClick={() => setDialog(label)} />
          ))}
        </Group>
      ))}
      <KAdaptiveDialog
        open={!!dialog}
        title={dialog}
        closeLabel="Schließen"
        onOpenChange={(open) => {
          if (!open) setDialog(null);
        }}
      >
        <p>
          Hier wird in der Anwendung „{dialog}“ geöffnet. Diese Galerie enthält
          keine verbindlichen Rechtstexte.
        </p>
      </KAdaptiveDialog>
    </KStack>
  );
}
function Server() {
  const [copied, setCopied] = useState(false);
  return (
    <KStack gap="section" align="stretch">
      <KInline gap="control">
        <KText variant="heading2">Server</KText>
        <span className="sg-status sg-admin-badge">Admin</span>
      </KInline>
      <p className="sg-muted sg-admin-intro">
        Gilt für alle Nutzer:innen dieses Servers. Wird in der
        Server-Konfiguration festgelegt.
      </p>
      <Group title="">
        <div className="sg-data-row">
          <span>
            Öffentliche Adresse<small>https://onzeit.example</small>
          </span>
          <KButton
            variant="secondary"
            aria-label="Adresse kopieren"
            onClick={() =>
              void navigator.clipboard
                .writeText("https://onzeit.example")
                .then(() => setCopied(true))
            }
          >
            <KIcon name="copy" />
          </KButton>
        </div>
        <div className="sg-data-row">
          <span>Status</span>
          <span className="sg-status sg-success">Erreichbar · Demo</span>
        </div>
      </Group>
      {copied && <p role="status">Adresse kopiert</p>}
    </KStack>
  );
}
export function ExtraSettings({ page }: { page: string }) {
  switch (page) {
    case "payments":
      return <Payments />;
    case "integrations":
      return <Integrations />;
    case "about":
      return <About />;
    case "access":
      return <Access />;
    case "assistant":
      return <Assistant />;
    case "server":
      return <Server />;
    default:
      return null;
  }
}
