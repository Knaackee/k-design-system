import { useEffect, useRef, useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { KButton } from "@k-design-system/ui";
import "./browser-workspace.css";
import { BrowserTaskCards } from "./browser-task-cards.js";

type Mode = "watching" | "human" | "offline" | "stopped" | "complete";
function BrowserWorkspace({
  initialMode = "watching",
  mobile = false,
}: {
  initialMode?: Mode;
  mobile?: boolean;
}) {
  const [mode, setMode] = useState<Mode>(initialMode);
  const [open, setOpen] = useState(false);
  const [continued, setContinued] = useState(false);
  const [zoom, setZoom] = useState(1);
  const [selected, setSelected] = useState<string>();
  const [query, setQuery] = useState("Tokyo");
  const viewport = useRef<HTMLDivElement>(null);
  const [width, setWidth] = useState(900);
  useEffect(() => {
    if (!viewport.current) return;
    const observer = new ResizeObserver(([entry]) =>
      setWidth(entry.contentRect.width),
    );
    observer.observe(viewport.current);
    return () => observer.disconnect();
  }, [open]);
  const human = mode === "human";
  const status = {
    watching: "Agent steuert",
    human: "Du steuerst · Agent pausiert",
    offline: "Verbindung unterbrochen",
    stopped: "Aufgabe gestoppt",
    complete: "Recherche abgeschlossen · Browseransicht",
  }[mode];
  return (
    <main className={`browser-demo ${mobile ? "browser-demo--phone" : ""}`}>
      {!open && (
        <BrowserTaskCards
          continued={continued}
          onOpen={(takeControl, complete) => {
            setMode(
              takeControl ? "human" : complete ? "complete" : initialMode,
            );
            setOpen(true);
          }}
        />
      )}
      {open && (
        <section
          className="browser-demo__viewer"
          aria-label="Gemeinsamer Browser"
        >
          <header className="browser-demo__bar">
            <div>
              <strong>Browser</strong>
              <small>stay.example · Hotels in Tokyo</small>
            </div>
            <KButton variant="ghost" onClick={() => setOpen(false)}>
              Schließen
            </KButton>
          </header>
          <div className="browser-demo__control">
            <span role="status">
              <i data-mode={mode} />
              {status}
            </span>
            {mode === "watching" && (
              <KButton onClick={() => setMode("human")}>Übernehmen</KButton>
            )}
            {human && (
              <KButton
                onClick={() => {
                  setMode("watching");
                  setContinued(true);
                  setOpen(false);
                }}
              >
                Fertig – Ada fortsetzen lassen
              </KButton>
            )}
            {mode === "offline" && (
              <KButton
                onClick={() => {
                  setMode("watching");
                  setContinued(true);
                  setOpen(false);
                }}
              >
                Neu verbinden
              </KButton>
            )}
            {mode === "stopped" && (
              <KButton
                onClick={() => {
                  setMode("watching");
                  setContinued(true);
                  setOpen(false);
                }}
              >
                Fortsetzen
              </KButton>
            )}
          </div>
          <div className="browser-demo__hint">
            {human
              ? "Du kannst jetzt Felder bearbeiten und ein Hotel auswählen."
              : mode === "complete"
                ? "Die Recherche ist abgeschlossen. Du siehst den letzten Browserstand."
                : "Ada vergleicht Preise und Bewertungen. Übernimm, um selbst zu klicken."}
          </div>
          <div
            ref={viewport}
            className="browser-demo__viewport"
            tabIndex={0}
            aria-label="Browserbild, bei Vergrößerung scrollbar"
          >
            {mode === "offline" ? (
              <div className="browser-demo__empty">
                <strong>Der Browser ist gerade nicht erreichbar.</strong>
                <p>
                  Die Steuerung ist gesperrt. Verbinde dich erneut, um den
                  aktuellen Stand zu sehen.
                </p>
              </div>
            ) : (
              <div
                className="browser-demo__page"
                style={{ width: 900, zoom: (width / 900) * zoom }}
              >
                <nav>
                  <strong>STAY /</strong>
                  <span>Unterkünfte　 Reiseziele　 Meine Reisen</span>
                  <span>EUR · DE</span>
                </nav>
                <div className="browser-demo__search">
                  <label>
                    Reiseziel
                    <input
                      aria-label="Reiseziel"
                      value={query}
                      disabled={!human}
                      onChange={(e) => setQuery(e.target.value)}
                    />
                  </label>
                  <span>20. – 27. Dez. 2026</span>
                  <span>2 Erwachsene · 1 Zimmer</span>
                </div>
                <h2>Dein Aufenthalt in {query || "Tokyo"}</h2>
                <p>4 Sterne · bis 200 € pro Nacht · 7 Nächte</p>
                {[
                  {
                    name: "Hotel Metropolitan",
                    area: "Chiyoda · Ruhige Lage, zentral angebunden",
                    rating: "9,0",
                    price: "138 €",
                    art: "city",
                  },
                  {
                    name: "Mercure Haneda",
                    area: "Haneda · Frühstück inklusive",
                    rating: "9,2",
                    price: "102 €",
                    art: "garden",
                  },
                  {
                    name: "Comfort Tokyo",
                    area: "Koto · Nahe der U-Bahn",
                    rating: "8,6",
                    price: "80 €",
                    art: "room",
                  },
                ].map((hotel) => (
                  <article key={hotel.name} className="browser-demo__hotel">
                    <div
                      className={`browser-demo__hotel-art browser-demo__hotel-art--${hotel.art}`}
                      aria-label="Abstraktes Hotelmotiv"
                    >
                      <span>STAY</span>
                    </div>
                    <div>
                      <small>★★★★</small>
                      <h3>{hotel.name}</h3>
                      <p>{hotel.area}</p>
                      <strong>
                        {hotel.rating} <small>Hervorragend</small>
                      </strong>
                    </div>
                    <div className="browser-demo__price">
                      <strong>{hotel.price}</strong>
                      <small>pro Nacht</small>
                      <KButton
                        variant={
                          selected === hotel.name ? "primary" : "secondary"
                        }
                        disabled={!human}
                        onClick={() => setSelected(hotel.name)}
                      >
                        {selected === hotel.name ? "Ausgewählt" : "Ansehen"}
                      </KButton>
                    </div>
                  </article>
                ))}
              </div>
            )}
          </div>
          <footer className="browser-demo__tools">
            <div>
              <KButton
                variant="ghost"
                disabled={zoom <= 1}
                onClick={() => setZoom((z) => Math.max(1, z - 0.25))}
              >
                −
              </KButton>
              <output aria-label="Zoom">{Math.round(zoom * 100)} %</output>
              <KButton
                variant="ghost"
                disabled={zoom >= 2}
                onClick={() => setZoom((z) => Math.min(2, z + 0.25))}
              >
                +
              </KButton>
              <KButton variant="ghost" onClick={() => setZoom(1)}>
                Ansicht zurücksetzen
              </KButton>
            </div>
            <KButton
              variant="ghost"
              disabled={mode === "stopped" || mode === "offline"}
              onClick={() => setMode("stopped")}
            >
              Aufgabe stoppen
            </KButton>
          </footer>
        </section>
      )}
    </main>
  );
}

const meta = {
  title: "Patterns/BrowserWorkspace",
  component: BrowserWorkspace,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof BrowserWorkspace>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Watching: Story = {};
export const HumanControl: Story = { args: { initialMode: "human" } };
export const Disconnected: Story = { args: { initialMode: "offline" } };
export const Mobile: Story = { args: { mobile: true } };
