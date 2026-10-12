import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KBrowserPermissionList,
  type KBrowserPermissionLabels,
  type KBrowserPermissionRule,
} from "@k-design-system/ui";
import "./browser-permissions.css";

const labels: KBrowserPermissionLabels = {
  waiting: "Freigabe erforderlich",
  manual: "Du schließt ab",
  blocked: "Blockiert",
  expired: "Anfrage abgelaufen",
  agent: "Persönlicher Agent",
  scope: "Nur diese Aktion auf diesem Pfad",
  details: "Details zur Aktion",
  origin: "Origin",
  path: "Pfad",
  action: "Aktion",
  allowed: "Erlaubt",
  once: "Einmal erlauben",
  allow: "Künftig erlauben",
  ask: "Immer fragen",
  block: "Blockieren",
  takeover: "Browser übernehmen",
  advanced: "Erweiterte Websitefreigabe",
  website: "Alle Formulare dieser Website erlauben…",
  confirmation: "Alle Formulare auf dieser Website erlauben?",
  confirm: "Websitefreigabe bestätigen",
  cancel: "Abbrechen",
  websiteScope:
    "Gilt für alle Formulare auf dieser Websiteadresse und nur für diesen persönlichen Agenten. Andere Hosts bleiben separat. Die Freigabe ist jederzeit widerrufbar.",
  manualLimit:
    "Käufe, Zahlungen und Nachrichten schließt du weiterhin selbst ab.",
  manualNote:
    "Übernimm den Browser, prüfe die Angaben und sende selbst ab. Dein Agent wartet.",
  stoppedNote:
    "Diese Anfrage lässt sich nicht freigeben. Zum Fortsetzen braucht dein Agent eine neue Anfrage.",
  rules: "Browserberechtigungen",
  rulesDescription: "Du bestimmst, was Nova auf einer Website ausführen darf.",
  searchNote:
    "Häufige Suchen sind bereits erlaubt. Suchergebnisse erlauben keine weiteren Websiteaktionen.",
  baseline: "Mitgelieferte Suchregel",
  custom: "Deine Regel",
  active: "Aktiv",
  revoked: "Widerrufen",
  ruleDecision: "Berechtigung",
  revoke: "Widerrufen",
  reset: "Basisregel wiederherstellen",
  empty: "Noch keine Browserberechtigungen",
  emptyDescription:
    "Braucht dein Agent eine Websiteaktion, entscheidest du. Gespeicherte Regeln erscheinen hier.",
};
function SiteIcon({ letter }: { letter: string }) {
  return (
    <svg viewBox="0 0 24 24" focusable="false">
      <text
        x="12"
        y="18"
        textAnchor="middle"
        fill="currentColor"
        fontSize="22"
        fontFamily="sans-serif"
        fontWeight="700"
      >
        {letter}
      </text>
    </svg>
  );
}
const initialRules: KBrowserPermissionRule[] = [
  {
    id: "google-search",
    host: "www.google.com",
    origin: "https://www.google.com",
    path: "/search",
    action: "Google-Suche ausführen",
    source: "baseline",
    decision: "allow",
    status: "active",
    favicon: <SiteIcon letter="G" />,
    details: (
      <p>
        Nur die Suchaktion. Keine Anmeldung, Nachrichten oder anderen Formulare.
      </p>
    ),
  },
  {
    id: "amazon-search",
    host: "www.amazon.de",
    origin: "https://www.amazon.de",
    path: "/s",
    action: "Amazon-Produkte suchen",
    source: "baseline",
    decision: "allow",
    status: "active",
    favicon: <SiteIcon letter="a" />,
    details: (
      <p>
        Nur Produktsuche auf diesem Host. Warenkorb und Bestellung sind nicht
        freigegeben.
      </p>
    ),
  },
  {
    id: "hotel-filter",
    host: "stay.example",
    origin: "https://stay.example",
    path: "/hotels/search",
    action: "Hotelsuche mit Reisedaten",
    source: "custom",
    decision: "ask",
    status: "active",
    favicon: <SiteIcon letter="s" />,
  },
  {
    id: "newsletter",
    host: "shop.example",
    origin: "https://shop.example",
    path: "/newsletter",
    action: "Newsletter abonnieren",
    source: "custom",
    decision: "block",
    status: "active",
  },
];
function PermissionDemo({
  mobile = false,
  empty = false,
}: {
  mobile?: boolean;
  empty?: boolean;
}) {
  const [outcome, setOutcome] = useState("");
  const [rules, setRules] = useState(empty ? [] : initialRules);
  return (
    <main
      className={`browser-permissions-demo ${mobile ? "browser-permissions-demo--mobile" : ""}`}
    >
      <div className="browser-permissions-demo__context">
        <span>Nova</span>
        <span>Einstellungen / Browser</span>
      </div>
      <KBrowserPermissionList
        agent="Nova"
        labels={labels}
        rules={rules}
        onDecisionChange={(id, decision) => {
          setRules((previous) =>
            previous.map((rule) =>
              rule.id === id ? { ...rule, decision } : rule,
            ),
          );
          setOutcome("Berechtigung geändert. Gilt nur für diese Regel.");
        }}
        onRevoke={(id) => {
          setRules((previous) =>
            previous.map((rule) =>
              rule.id === id ? { ...rule, status: "revoked" } : rule,
            ),
          );
          setOutcome("Freigabe widerrufen.");
        }}
        onReset={(id) => {
          setRules((previous) =>
            previous.map((rule) =>
              rule.id === id
                ? { ...rule, decision: "allow", status: "active" }
                : rule,
            ),
          );
          setOutcome("Mitgelieferte Suchregel wiederhergestellt.");
        }}
      />
      <p
        className="browser-permissions-demo__status"
        role="status"
        aria-live="polite"
      >
        {outcome || "Designvorschau · Aktionen ändern nur diese lokale Story."}
      </p>
    </main>
  );
}
const meta = {
  title: "Patterns/BrowserPermissions",
  component: PermissionDemo,
  parameters: { layout: "centered" },
  tags: ["autodocs"],
} satisfies Meta<typeof PermissionDemo>;
export default meta;
type Story = StoryObj<typeof meta>;
export const RuleManagement: Story = {
  parameters: { fixtureId: "browser-permissions-rule-management" },
};
export const Empty: Story = {
  args: { empty: true },
  parameters: { fixtureId: "browser-permissions-empty" },
};
export const MobileRules: Story = {
  args: { mobile: true },
  parameters: { fixtureId: "browser-permissions-mobile-rules" },
};
