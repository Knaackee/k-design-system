import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState, type ReactNode } from "react";
import {
  KButton,
  KIcon,
  KPresentationCard,
  KPresentationReference,
  KPresentationCollection,
  KPresentationComparison,
  KPresentationMetrics,
  KPresentationTimeline,
} from "@k-design-system/ui";
import {
  KPresentationGallery,
  KPresentationVideo,
  KPresentationAudio,
  KPresentationFile,
} from "@k-design-system/ui";
import "./chat-presentations-fixture.css";

const coast =
  "https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=900&auto=format&fit=crop&q=85";
const mountain =
  "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=900&auto=format&fit=crop&q=85";
const forest =
  "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=900&auto=format&fit=crop&q=85";
const images = [
  {
    src: coast,
    alt: "See zwischen grünen Bergen",
    caption: "Ein ruhiger Ort am Wasser",
  },
  {
    src: mountain,
    alt: "Berggipfel im Abendlicht",
    caption: "Die Berge im letzten Licht",
  },
  {
    src: forest,
    alt: "Sonnenlicht zwischen Waldbäumen",
    caption: "Unterwegs im Wald",
  },
];
function Section({
  id,
  title,
  children,
}: {
  id: string;
  title: string;
  children: ReactNode;
}) {
  return (
    <section className="presentation-review__section" id={id}>
      <div className="presentation-review__label">
        <span>{id}</span>
        <h2>{title}</h2>
      </div>
      {children}
    </section>
  );
}
function Review({
  initialMode = "catalog",
}: {
  initialMode?: "catalog" | "chat";
}) {
  const [mode, setMode] = useState(initialMode);
  const [selected, setSelected] = useState<number | null>(null);
  const [notice, setNotice] = useState("");
  const open = (name: string) => setNotice(`Vorschau ausgewählt: ${name}`);
  return (
    <div className="presentation-review">
      <header className="presentation-review__header">
        <div>
          <span className="presentation-review__eyebrow">
            CHAT · PRÄSENTATIONEN
          </span>
          <h1>Mehr als eine Antwort.</h1>
          <p>Bilder, Fundstücke und Details. Direkt im Gespräch.</p>
        </div>
        <div className="presentation-review__modes">
          <KButton
            variant={mode === "catalog" ? "secondary" : "ghost"}
            onClick={() => setMode("catalog")}
          >
            Katalog
          </KButton>
          <KButton
            variant={mode === "chat" ? "secondary" : "ghost"}
            onClick={() => setMode("chat")}
          >
            Im Chat
          </KButton>
        </div>
      </header>
      <div className="presentation-review__notice" role="status">
        {notice ||
          "Interaktive Beispiele · Aktionen öffnen noch keine Tasks-Daten."}
      </div>
      {mode === "chat" ? (
        <div className="presentation-review__conversation">
          <div className="presentation-review__user">
            Hast du eine Idee für ein Wochenende in den Bergen? Und zeig mir
            bitte die offenen Aufgaben dazu.
          </div>
          <div className="presentation-review__speaker">
            <KIcon name="sparkles" />
            <strong>Dein Begleiter</strong>
          </div>
          <p>
            Wie wäre es mit zwei Tagen am See? Hier sind drei Orte, an denen du
            gut abschalten kannst.
          </p>
          <KPresentationCollection label="Deine kleine Auszeit">
            {images.map((img, i) => (
              <KPresentationCard
                key={img.src}
                variant="cover"
                image={img}
                eyebrow="Wochenende draußen"
                title={
                  ["Am Wasser ankommen", "Hoch hinaus", "Einfach losgehen"][i]
                }
                action={{
                  label: "Ort ansehen",
                  onClick: () => open(img.caption),
                }}
              />
            ))}
          </KPresentationCollection>
          <p>Für die Vorbereitung sind diese beiden Aufgaben noch offen:</p>
          <KPresentationCollection label="Deine Aufgaben" layout="list">
            <KPresentationReference
              title="Unterkunft für das Wochenende buchen"
              metadata="Reiseplanung · Offen"
              icon="circle"
              onOpen={() => open("Issue: Unterkunft buchen")}
            />
            <KPresentationReference
              title="Packliste zusammenstellen"
              metadata="Reiseplanung · In Arbeit"
              icon="file-text"
              onOpen={() => open("Issue: Packliste")}
            />
          </KPresentationCollection>
          <p>Die Notizen habe ich dir hier zusammengefasst.</p>
          <KPresentationFile
            openLabel="Öffnen"
            downloadLabel="Herunterladen"
            name="Wochenende.md"
            meta="Markdown · 2,4 KB"
            onOpen={() => open("Wochenende.md")}
            onDownload={() => downloadNote()}
          />
        </div>
      ) : (
        <div className="presentation-review__grid">
          <Section id="01" title="Bild, Titel & Text">
            <KPresentationCard
              image={images[0]}
              eyebrow="Inspiration · 4 Minuten"
              title="Ein Wochenende am See"
              description="Weniger planen, mehr draußen sein. Drei kleine Ideen für deine nächste Auszeit."
              action={{
                label: "Entdecken",
                onClick: () => open("Wochenende am See"),
              }}
            />
          </Section>
          <Section id="02" title="Bild im Mittelpunkt">
            <KPresentationCard
              variant="cover"
              image={images[1]}
              eyebrow="Für deine nächste Auszeit"
              title="Eine neue Perspektive"
              description="Manchmal reicht ein anderer Blickwinkel."
              action={{
                label: "Ansehen",
                onClick: () => open("Eine neue Perspektive"),
              }}
            />
          </Section>
          <Section id="03" title="Direkt zum richtigen Ort">
            <KPresentationCollection label="Passende Ergebnisse" layout="list">
              <KPresentationReference
                title="Chat-Präsentationen abstimmen"
                metadata="Issue · In Arbeit · Designsystem"
                icon="circle"
                onOpen={() => open("Issue: Chat-Präsentationen")}
              />
              <KPresentationReference
                title="Unser nächster Release"
                metadata="Projekt · 8 offene Aufgaben"
                icon="folder"
                onOpen={() => open("Projekt: Release")}
              />
              <KPresentationReference
                title="Ideen für das Wochenende"
                metadata="Notiz · Heute bearbeitet"
                image={coast}
                onOpen={() => open("Notiz: Wochenende")}
              />
            </KPresentationCollection>
          </Section>
          <Section id="04" title="Mehrere Empfehlungen">
            <KPresentationCollection label="Das könnte dir gefallen">
              {images.map((img, i) => (
                <KPresentationCard
                  key={img.src}
                  image={img}
                  title={
                    ["Zeit am See", "Über den Wolken", "Grün statt Grau"][i]
                  }
                  description="Ein guter Ort für eine kleine Pause."
                  action={{
                    label: "Mehr erfahren",
                    onClick: () => open(img.caption),
                  }}
                />
              ))}
            </KPresentationCollection>
          </Section>
          <Section id="05" title="Zwei Seiten, ein Ergebnis">
            <KPresentationComparison
              label="Freundschaftsspiel · Beendet"
              left={{
                name: "Nord",
                image: "https://flagcdn.com/de.svg",
                detail: "Heim",
              }}
              right={{
                name: "Süd",
                image: "https://flagcdn.com/at.svg",
                detail: "Gast",
              }}
              value="2 : 1"
              detail="Endstand"
            />
          </Section>
          <Section id="06" title="Das Wichtigste auf einen Blick">
            <KPresentationMetrics
              label="Berlin · Heute"
              value="18°"
              description="Leicht bewölkt. Gutes Wetter für einen Spaziergang."
              icon="cloud"
              metrics={[
                { label: "Gefühlt", value: "19°" },
                { label: "Regen", value: "10 %" },
                { label: "Wind", value: "12 km/h" },
              ]}
            />
          </Section>
          <Section id="07" title="Ein klarer Verlauf">
            <KPresentationTimeline
              label="Deine Verbindung · ICE 706"
              stops={[
                {
                  id: "a",
                  time: "09:04",
                  title: "Berlin Hauptbahnhof",
                  description: "Gleis 8 · Abfahrt",
                  current: true,
                },
                {
                  id: "b",
                  time: "10:42",
                  title: "Leipzig Hauptbahnhof",
                  description: "Direkt weiterfahren",
                },
                {
                  id: "c",
                  time: "13:02",
                  title: "München Hauptbahnhof",
                  description: "Gleis 19 · Ankunft",
                },
              ]}
            />
          </Section>
          <Section id="08" title="Bilder entdecken">
            <KPresentationGallery
              closeLabel="Schließen"
              previousLabel="Vorheriges Bild"
              nextLabel="Nächstes Bild"
              title="Drei Momente draußen"
              images={images}
              selectedIndex={selected}
              onSelectedIndexChange={setSelected}
            />
          </Section>
          <Section id="09" title="Video direkt im Gespräch">
            <KPresentationVideo
              title="Ein Moment in Bewegung"
              src="https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4"
              poster={forest}
              caption="Videobeispiel · Wiedergabe erst auf Klick"
            />
          </Section>
          <Section id="10" title="Zuhören, ohne den Chat zu verlassen">
            <KPresentationAudio
              title="Ein kurzer Klang"
              meta="Audiobeispiel · Foley"
              src="/foley/chime.wav"
            />
          </Section>
          <Section id="11" title="Dateien zum Mitnehmen">
            <KPresentationFile
              openLabel="Öffnen"
              downloadLabel="Herunterladen"
              name="Wochenende.md"
              meta="Markdown · 2,4 KB"
              onOpen={() => open("Wochenende.md")}
              onDownload={() => downloadNote()}
            />
            <KPresentationFile
              openLabel="Öffnen"
              downloadLabel="Herunterladen"
              name="Reiseunterlagen.pdf"
              meta="PDF · 1,8 MB"
              onOpen={() => open("Reiseunterlagen.pdf")}
            />
          </Section>
        </div>
      )}
    </div>
  );
}
function downloadNote() {
  const url = URL.createObjectURL(
    new Blob(
      ["# Wochenende\n\nZeit am See, ein Spaziergang und eine gute Pause.\n"],
      { type: "text/markdown" },
    ),
  );
  const link = document.createElement("a");
  link.href = url;
  link.download = "Wochenende.md";
  link.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}
const meta = {
  title: "Patterns/Chat Presentations",
  parameters: { layout: "fullscreen", fixtureId: "chat-presentations-review" },
  render: () => <Review />,
} satisfies Meta;
export default meta;
type Story = StoryObj<typeof meta>;
export const ReviewGallery: Story = { name: "Review" };
export const InChat: Story = { render: () => <Review initialMode="chat" /> };
