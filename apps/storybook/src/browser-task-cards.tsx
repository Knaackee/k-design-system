import { useEffect, useRef, useState } from "react";
import {
  KButton,
  KBrowserTaskCard,
  KIcon,
  KMenuButton,
  type KMenuAction,
} from "@k-design-system/ui";
import "./browser-task-cards.css";

/** Static 16:9 preview; interaction lives in the separate viewer. */
function BrowserPreview({ login = false }: { login?: boolean }) {
  return (
    <svg
      className="browser-task__preview"
      viewBox="0 0 640 360"
      role="img"
      aria-label={
        login ? "Vorschau der Anmeldeseite" : "Vorschau der Hotelsuche in Tokyo"
      }
    >
      <rect width="640" height="360" fill="#f7f8f9" />
      <rect width="640" height="48" fill="#ffffff" />
      <g fontFamily="Arial, sans-serif" fill="#23343d">
        <text x="24" y="31" fontSize="18" fontWeight="700">
          STAY /
        </text>
        <text x="330" y="29" fontSize="11">
          Unterkünfte　 Reiseziele　 Mein Konto
        </text>
        {login ? (
          <>
            <rect
              x="170"
              y="77"
              width="300"
              height="252"
              rx="12"
              fill="#ffffff"
              stroke="#e0e5e7"
            />
            <text x="200" y="119" fontSize="21" fontWeight="700">
              Willkommen zurück
            </text>
            <text x="200" y="145" fontSize="12">
              Melde dich für deine Mitgliederpreise an.
            </text>
            <rect
              x="200"
              y="173"
              width="240"
              height="42"
              rx="6"
              fill="#f7f8f9"
              stroke="#d9e0e3"
            />
            <text x="213" y="199" fontSize="12">
              E-Mail-Adresse
            </text>
            <rect
              x="200"
              y="232"
              width="240"
              height="40"
              rx="6"
              fill="#23343d"
            />
            <text x="300" y="257" fontSize="13" fill="#ffffff">
              Weiter
            </text>
          </>
        ) : (
          <>
            <text x="24" y="84" fontSize="23" fontWeight="700">
              Hotels in Tokyo
            </text>
            <text x="24" y="109" fontSize="12">
              20.–27. Dezember · 2 Erwachsene · 4 Sterne
            </text>
            {[
              {
                y: 132,
                name: "Hotel Metropolitan",
                price: "138 €",
                area: "Chiyoda · 9,0 Hervorragend",
              },
              {
                y: 241,
                name: "Mercure Haneda",
                price: "102 €",
                area: "Haneda · Frühstück inklusive",
              },
            ].map((hotel) => (
              <g key={hotel.name}>
                <rect
                  x="24"
                  y={hotel.y}
                  width="592"
                  height="96"
                  rx="8"
                  fill="#ffffff"
                  stroke="#e0e5e7"
                />
                <rect
                  x="34"
                  y={hotel.y + 10}
                  width="110"
                  height="76"
                  rx="5"
                  fill="#d8d1c4"
                />
                <text x="164" y={hotel.y + 32} fontSize="17" fontWeight="700">
                  {hotel.name}
                </text>
                <text x="164" y={hotel.y + 56} fontSize="11">
                  {hotel.area}
                </text>
                <text x="538" y={hotel.y + 40} fontSize="20" fontWeight="700">
                  {hotel.price}
                </text>
                <text x="544" y={hotel.y + 60} fontSize="10">
                  pro Nacht
                </text>
              </g>
            ))}
          </>
        )}
      </g>
    </svg>
  );
}

function BrowserCardActions({
  needsHelp,
  complete,
  onOpen,
}: {
  needsHelp: boolean;
  complete: boolean;
  onOpen: (control: boolean) => void;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const [compact, setCompact] = useState(true);
  const [stopped, setStopped] = useState(false);
  const [notice, setNotice] = useState("");
  useEffect(() => {
    if (!ref.current) return;
    const observer = new ResizeObserver(([entry]) =>
      setCompact(entry.contentRect.width < 420),
    );
    observer.observe(ref.current);
    return () => observer.disconnect();
  }, []);
  const secondary: KMenuAction = {
    id: "secondary",
    label: needsHelp ? "Browser öffnen" : "Kontrolle übernehmen",
    icon: needsHelp ? "maximize" : "mouse-pointer",
    onSelect: () => onOpen(!needsHelp),
  };
  const actions: KMenuAction[] = [
    ...(!complete && !stopped && compact ? [secondary] : []),
    {
      id: "copy",
      label: "Seitenadresse kopieren",
      icon: "copy",
      onSelect: () => {
        void navigator.clipboard.writeText("https://stay.example/tokyo").then(
          () => setNotice("Beispieladresse kopiert"),
          () => setNotice("Kopieren nicht möglich"),
        );
      },
    },
    ...(!complete
      ? [
          {
            id: "stop",
            label: stopped ? "Aufgabe fortsetzen" : "Aufgabe stoppen",
            icon: "square" as const,
            destructive: !stopped,
            separatorBefore: true,
            onSelect: () => {
              setStopped(!stopped);
              setNotice(stopped ? "Aufgabe fortgesetzt" : "Aufgabe gestoppt");
            },
          },
        ]
      : []),
  ];
  return (
    <>
      <div
        ref={ref}
        className="browser-task__toolbar"
        role="group"
        aria-label="Browseraktionen"
      >
        <KButton
          variant={needsHelp && !stopped ? "primary" : "ghost"}
          onClick={() => onOpen(needsHelp && !stopped)}
        >
          <KIcon name={needsHelp && !stopped ? "mouse-pointer" : "maximize"} />
          {needsHelp && !stopped ? "Übernehmen" : "Browser öffnen"}
        </KButton>
        {!compact && !complete && !stopped && (
          <KButton variant="ghost" onClick={secondary.onSelect}>
            <KIcon name={secondary.icon!} />
            {secondary.label}
          </KButton>
        )}
        <span className="browser-task__overflow">
          <KMenuButton
            label="Weitere Browseraktionen"
            overflow
            align="end"
            actions={actions}
          />
        </span>
      </div>
      {notice && <small role="status">{notice}</small>}
    </>
  );
}

export function BrowserTaskCards({
  onOpen,
  continued,
}: {
  onOpen: (takeControl: boolean, complete?: boolean) => void;
  continued: boolean;
}) {
  const cards = [
    {
      title: "Ada steuert den Browser",
      description: "Ich vergleiche Hotels in Tokyo bis 200 € pro Nacht.",
    },
    {
      title: continued
        ? "Ada setzt die Suche fort"
        : "Ada braucht deine Anmeldung",
      description: continued
        ? "Ich prüfe jetzt die verfügbaren Mitgliederpreise."
        : "Melde dich bei Stay an, damit ich die Mitgliederpreise prüfen kann.",
      login: !continued,
    },
    {
      title: "Ada hat die Recherche abgeschlossen",
      description:
        "Drei Hotels passen zu deinen Wünschen. Es wurde nichts gebucht.",
      complete: true,
    },
  ];
  return (
    <section
      className="browser-tasks"
      aria-label="Browser-Karten: arbeitet, benötigt Hilfe, abgeschlossen"
    >
      {cards.map((card, index) => (
        <KBrowserTaskCard
          key={index}
          title={card.title}
          description={card.description}
          preview={<BrowserPreview login={card.login} />}
          actions={
            <BrowserCardActions
              needsHelp={!!card.login}
              complete={!!card.complete}
              onOpen={(control) => onOpen(control, card.complete)}
            />
          }
        />
      ))}
    </section>
  );
}
