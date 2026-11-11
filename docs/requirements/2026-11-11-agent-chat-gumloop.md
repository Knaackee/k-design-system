# Agenten-Chat nach dem Vorbild von Gumloop – Spezifikation für das K Design System

Für: Design-System-Agents (Web und Flutter).
Ziel: Der Agenten-Chat soll ruhig, textorientiert und rahmenarm wirken. Was
der Agent tut, ist zusammengeklappt lesbar und lässt sich aufklappen.
Abstände sind Tokens und funktionieren in allen drei Dichten (kompakt,
standard, großzügig), in allen Stilen (apple, material, linear) und mit
Touch- und Zeiger-Eingabe.

Vorbild: Gumloop (Web), 15 Screens aus Mobbin (Liste am Ende).

---

## 0. Spielregeln

1. **Keine Pixelwerte in Komponenten.** Jeder Abstand, jede Höhe und jeder
   Radius kommt aus einem Token. Neue Werte werden als `component.chat.*`
   in `tokens/semantic.tokens.json` angelegt, mit Werten je Dichte in
   `tokens/modes/density.{dense,standard,spacious}.tokens.json`, und dann
   per `tooling/generate-tokens.mjs` erzeugt. Web und Flutter lesen
   dieselben Tokens.
2. **Standard = Gumloop.** Die Dichte „standard“ trifft die gemessenen
   Gumloop-Werte. „Kompakt“ und „großzügig“ skalieren nach den
   bestehenden Dichte-Stufen (`controlGap` 4/8/12, `cardPadding` 12/16/24,
   `layoutSectionGap` 16/32/48, `size.control` 32/36/44).
3. **4-px-Raster.** Alle Werte sind Vielfache von 4, außer Haarlinien
   (1 px) und den in der Tabelle ausdrücklich genannten Ausnahmen.
4. **Touch schlägt Dichte.** Bei Touch-Eingabe (`input-mode.touch`) sind
   alle Trefferflächen mindestens 44 pt bzw. 48 dp
   (`size.controlTouch`), auch in „kompakt“. Die Dichte ändert dann nur
   die Abstände, nicht die Trefferflächen.
5. **Lesebreite unabhängig von der Dichte.** Die Gesprächsspalte bleibt in
   allen Dichten gleich breit. Die Dichte ändert die vertikalen
   Abstände und die Innenabstände, nicht die Zeilenlänge.
6. **Textgröße.** Alle Höhen wachsen mit der Schrift (bis 200 %). Feste
   Höhen gibt es nur als Mindesthöhe (`min-height`), nie als feste Höhe.

### Messgrundlage

Gemessen an Mobbin-Vorschauen (768 px breit), hochgerechnet auf 1440 px
(Faktor 1,875). Genauigkeit etwa ±2 px. Alle Werte sind auf das 4-px-Raster
gerundet. In Klammern steht jeweils der gemessene Wert.

---

## 1. Abstands-Tokens (neu: `component.chat.*`)

| Token                       | Bedeutung                                                                                                      | kompakt         | standard | großzügig | Gumloop gemessen      |
| --------------------------- | -------------------------------------------------------------------------------------------------------------- | --------------- | -------- | --------- | --------------------- |
| `chat.column.maxWidth`      | max. Breite der Gesprächsspalte                                                                                | 720             | 720      | 720       | ≈ 712                 |
| `chat.column.gutter`        | Seitenrand der Spalte im Fenster                                                                               | 16              | 24       | 32        | –                     |
| `chat.turn.gap`             | Abstand zwischen zwei Beiträgen (Nutzer ↔ Agent)                                                               | 16              | 24       | 32        | 24                    |
| `chat.block.gap`            | Abstand zwischen Blöcken eines Beitrags (Absatz, Code, Karte, Anhang)                                          | 8               | 12       | 16        | 11–13                 |
| `chat.meta.gap`             | Namenszeile → Schritte/Denken → erster Block                                                                   | 4               | 8        | 12        | 6                     |
| `chat.bubble.paddingInline` | Innenabstand Nutzer-Blase, waagerecht                                                                          | 8               | 12       | 16        | 11                    |
| `chat.bubble.paddingBlock`  | Innenabstand Nutzer-Blase, senkrecht (Ausnahme vom 4-px-Raster, damit einzeilige Blasen optisch mittig sitzen) | 6               | 10       | 12        | 10                    |
| `chat.bubble.maxWidth`      | max. Breite Nutzer-Blase (Anteil der Spalte)                                                                   | 80 %            | 75 %     | 70 %      | ≈ 70 %                |
| `chat.disclosure.minHeight` | Zeile für Schritte und Denken                                                                                  | 24              | 28       | 32        | 28                    |
| `chat.card.padding`         | Innenabstand von Rückfrage-, Formular- und Ergebnis-Karten (= `space.cardPadding`)                             | 12              | 16       | 24        | ≈ 20                  |
| `chat.card.headerHeight`    | Kopfzeile „Wartet auf deine Eingabe“ (= `size.control`)                                                        | 32              | 36       | 44        | 36                    |
| `chat.option.minHeight`     | Antwort-Option (= `size.control`, Touch ≥ 44/48)                                                               | 32              | 36       | 44        | 38                    |
| `chat.option.gap`           | Abstand zwischen Optionen                                                                                      | 4               | 8        | 8         | 6                     |
| `chat.option.paddingInline` | Innenabstand Option (= `space.controlInsetInline`)                                                             | 8               | 12       | 16        | 12                    |
| `chat.card.actionGap`       | letzte Option → Buttons (= `space.contentActionGap`)                                                           | 8               | 16       | 24        | 14                    |
| `chat.attachment.height`    | Datei-Chip                                                                                                     | 32              | 36       | 44        | 34                    |
| `chat.code.headerHeight`    | Kopfzeile Codeblock                                                                                            | 28              | 32       | 36        | 30                    |
| `chat.code.padding`         | Innenabstand Code                                                                                              | 8               | 12       | 16        | 12                    |
| `chat.composer.padding`     | Innenabstand Eingabe                                                                                           | 12              | 16       | 20        | 16                    |
| `chat.composer.overhang`    | Eingabe ragt seitlich über die Spalte hinaus                                                                   | 12              | 24       | 32        | ≈ 28                  |
| `chat.composer.minHeight`   | Mindesthöhe (2 Zeilen + Werkzeugzeile + Innenabstand)                                                          | 88              | 112      | 136       | 123                   |
| `chat.composer.bottomGap`   | Eingabe → Fensterrand bzw. Hilfezeile                                                                          | 12              | 16       | 24        | 24 (inkl. Hilfezeile) |
| `chat.composer.radius`      | Eckenradius Eingabe                                                                                            | `radius.2xl` 18 | 18       | 18        | ≈ 16–18               |
| `chat.panel.width`          | Detail-Panel rechts                                                                                            | 360             | 400      | 440       | ≈ 394                 |
| `chat.panel.rowHeight`      | Zeilen im Detail-Panel (= `size.control`)                                                                      | 32              | 36       | 44        | 36                    |
| `chat.home.sectionGap`      | Abschnitte der Startseite (= `space.layoutSectionGap`)                                                         | 16              | 32       | 48        | 32–40                 |
| `chat.home.rowHeight`       | Zeilen „Letzte Gespräche“ / „Trigger“                                                                          | 32              | 40       | 48        | 38–40                 |

Liegt der gemessene Wert neben dem Raster, ist er auf den nächsten
Rasterwert gerundet. Wo `= space.*` oder `= size.*` steht,
wird das bestehende Token verwendet (Alias), kein neues.

### Schrift (unabhängig von der Dichte, aus der Typo-Skala)

| Rolle                               | Token                                     | Gumloop gemessen |
| ----------------------------------- | ----------------------------------------- | ---------------- |
| Fließtext Nachrichten               | `font.body`                               | 14 / 20          |
| Namenszeile Agent, Schritte, Denken | `font.caption`, gedämpft, Gewicht 500     | 13               |
| Kartentitel (Frage)                 | `font.label`, Gewicht 600                 | 14               |
| Hilfetext                           | `font.caption`, gedämpft                  | 13               |
| Dateityp im Chip („NUMBERS“)        | `font.caption2`, Großbuchstaben, gesperrt | 10–11            |
| Begrüßung Startseite                | `font.heading3`                           | 24 / 28          |
| Code                                | `font.mono`                               | 13 / 20          |

---

## 2. Grundlayout (`KAgentChatWorkspace`, `KChatConversation`)

- Spalte zentriert, `chat.column.maxWidth`, seitlich mindestens
  `chat.column.gutter`. Keine Karten um Nachrichten.
- **Agent-Beitrag:** keine Blase.
  - Namenszeile mit 16-px-Icon und Name, gedämpft, `font.caption` 500.
  - `chat.meta.gap` darunter Schritte/Denken.
  - Erneut `chat.meta.gap` darunter der Text, über die volle Spaltenbreite.
- **Nutzer-Beitrag:**
  - Rechtsbündige, neutrale Blase (`surface.raised`, keine Akzentfarbe).
  - Radius `radius.xl`.
  - Innenabstand `chat.bubble.padding*`, max. `chat.bubble.maxWidth`.
  - Avatar 20 px rechts oben neben der Blase, Abstand `controlGap`.
  - Ab 8 Zeilen gekürzt, mit „Ganze Nachricht anzeigen“.
- Zwischen Beiträgen `chat.turn.gap`, innerhalb eines Beitrags
  `chat.block.gap`. Absätze im Markdown haben `chat.block.gap` als
  Abstand, keinen eigenen.
- **Kopfleiste:** Höhe `component.topBar.height`, Titel zentriert, rechts
  „Teilen“ und der Button für das Detail-Panel. Auf dem Desktop kein
  Zurück-Pfeil.
- **Detail-Panel:**
  - Angedockt, `chat.panel.width`, schiebt das Gespräch zusammen.
  - Ist das Fenster zu schmal (< 1024), wird es zum Sheet.
  - Inhalt als Liste mit Beschriftung und Wert, Zeilen `chat.panel.rowHeight`.

## 3. Eingabe (`KChatComposer`)

- **Karte:**
  - Radius `chat.composer.radius`, weicher Schatten, Rand 1 px.
  - Innenabstand `chat.composer.padding`.
  - Ragt um `chat.composer.overhang` je Seite über die Spalte hinaus,
    sodass der Text der Nachrichten mit dem Text in der Eingabe fluchtet.
  - Unten `chat.composer.bottomGap` Abstand, ggf. Safe Area dazu.
- **Aufbau:**
  - Mehrzeiliges Textfeld, 2 Zeilen Mindesthöhe, wächst bis 8 Zeilen,
    dann scrollt es.
  - Darunter die Werkzeugzeile, Abstand `chat.block.gap`.
  - Alle Buttons in der Werkzeugzeile sind `size.control`, Abstand
    `controlGap`.
- **Werkzeugzeile:**
  - Links: „+“, Chip für Agent/Modell, Chip „N Verbindungen“. Beide Chips
    öffnen ein Menü mit Suche; Verbindungen werden dort per Schalter
    an- und ausgeschaltet.
  - Rechts: Diktieren und Senden (rund, Akzentfarbe).
- **Antwortet der Agent:**
  - Animierter Farbverlauf am Rand, Platzhalter „Antwortet …“, Senden
    wird zu Stopp.
  - Bei `motion.reduced`: statischer Akzentrand.
- **Anhänge:** Chips oben in der Karte, Abstand `chat.block.gap` zum
  Text, umbrechend.
- Die Hilfezeile darunter („Probleme? Fehler melden“) ist optional per
  Prop, `font.caption2`.

## 4. Textansichten (neu: `KAgentMarkdown`, `KCodeBlock`)

- **Markdown:**
  - Absätze, **fett**, Listen (Einzug `space.6`, Abstand zwischen
    Einträgen `controlGap`), Links.
  - `Inline-Code`: Fläche `surface.raised`, Radius `radius.sm`,
    Innenabstand 2 × 6.
  - Überschriften im Gespräch höchstens `font.label` 600.
- **Codeblock:**
  - Radius `radius.card`, Rand 1 px.
  - Kopfzeile `chat.code.headerHeight` mit der Sprache in Großbuchstaben
    links und Kopieren rechts (Kopieren wird 2 s lang zum ✓).
  - Inhalt mit Innenabstand `chat.code.padding`, scrollt waagerecht.
  - Ab 20 Zeilen zugeklappt mit „Mehr anzeigen“.
- **Tabellen:** waagerecht scrollbar, Zellen-Innenabstand
  `controlInsetInline` × `controlGap`.
- **Aktionen unter Agent-Antworten** (Kopieren, Neu erzeugen, Feedback):
  `size.control`, mit Zeiger beim Darüberfahren sichtbar, bei Touch
  immer. Abstand nach oben `chat.meta.gap`.

## 5. Rückfragen (`KAgentQuestion`, `KAgentSingleChoice`, `KAgentMultipleChoice`, `KAgentTextQuestion`, `KAgentApproval`)

- **Karte:**
  - Eigene Karte im Gesprächsfluss, Abstand `chat.block.gap` nach oben.
  - Rand 1 px, Radius `radius.card`, leichter Schatten.
  - Kopfzeile `chat.card.headerHeight`: Icon und „Wartet auf deine
    Eingabe“, gedämpft, mit Trennlinie darunter.
- **Inhalt** mit Innenabstand `chat.card.padding`:
  - Fragetitel, Pflicht-Sternchen in der Fehlerfarbe.
  - Hilfetext mit `chat.meta.gap` Abstand.
  - Danach `chat.block.gap` bis zur ersten Option.
- **Optionen:**
  - Zeilen über die volle Breite, `chat.option.minHeight`, Innenabstand
    `chat.option.paddingInline`, Abstand `chat.option.gap`.
  - Rand 1 px, Radius `radius.control`.
  - Auswahl-Kreis rechts, ausgewählt mit Akzentrand und gefülltem Kreis.
  - Die ganze Zeile ist klickbar. Langer Text bricht um, die Zeile wächst.
  - Immer eine Option „Andere“, die ein Textfeld aufklappt.
- **Aktionen:**
  - `chat.card.actionGap` unter der letzten Option, links ausgerichtet.
  - „Ablehnen“ (Ghost, ×) und „Senden“ (Primär, ✓), beide `size.control`.
  - Senden ist deaktiviert, bis die Eingabe gültig ist.
- **Nach dem Senden:** Die Karte klappt zu einer Zeile
  (`chat.disclosure.minHeight`) zusammen: „Beantwortet: …“. Die Antwort
  erscheint als Nutzer-Beitrag.
- In Seitenleiste und Startseite steht ein Abschnitt „Wartet auf dich“.

## 6. Formulare (`KAgentForm`)

- Gleiche Karte wie bei der Rückfrage. Felder untereinander mit Abstand
  `chat.block.gap`, Beschriftung und Feld mit `chat.meta.gap` Abstand.
  Ein einziges Senden.
- Felder haben `size.field`, Fehler direkt am Feld.
- **Panels mit Einstellungen (Agent-Einstellungen):**
  - Abschnitte mit Titel und Chevron, zuklappbar.
  - Abstand zwischen Abschnitten `layoutSectionGap`, Trennlinie dazwischen.
  - Rechts im Abschnitt eine Statusangabe („KI verwaltet: AN“) und
    „+ Hinzufügen“.
  - An/Aus immer als `KListItem(switchValue:)`.
  - „Speichern“ oben rechts, deaktiviert ohne Änderungen, dazu
    Rückgängig.

## 7. Dateianhänge (`KAgentAttachment`, `KAttachment`, `KPresentationFile`)

- **Datei-Chip:**
  - Höhe `chat.attachment.height`.
  - Kachel mit Icon im Seitenverhältnis 1:1, Höhe minus 8.
  - Daneben Name (`font.label`) und Typ (`font.caption2`, Großbuchstaben).
  - Innenabstand `controlInsetInline`, Rand 1 px, Radius `radius.control`.
- **Platzierung:**
  - Nutzer-Anhänge rechtsbündig unter der Blase, Abstand `chat.block.gap`.
  - Agent-Dateien im Agent-Beitrag.
  - In der Eingabe oben, mit × zum Entfernen und Fortschritt beim
    Hochladen.
- Im Detail-Panel stehen unter „Dateien“ alle Dateien des Gesprächs, mit
  leerem Zustand (Icon, „Noch keine Dateien“, ein Satz Erklärung).

## 8. Tool-Aufrufe und Schritte (`KAgentToolGroup`, `KAgentToolCall`, `KAgentTaskGroup`, `KAgentActivity`)

- **Zugeklappt:**
  - Eine Zeile mit `chat.disclosure.minHeight`: Chevron, gestapelte
    Tool-Icons (16 px, max. 5, Überlappung 4) und „8 Schritte“.
  - Gedämpft, keine Karte.
- **Aufgeklappt:**
  - Liste mit Zeilen `chat.disclosure.minHeight`, Abstand `controlGap`.
  - Je Zeile: Icon, Kurztext, Status (läuft = Spinner, fertig = ✓,
    Fehler = ✕), Dauer rechts.
  - Pro Schritt lassen sich Eingabe und Ausgabe weiter aufklappen, in
    einem `KCodeBlock`.
- **Laufende Aufgabe:** kompakte Karte mit `size.control` Mindesthöhe,
  Innenabstand `controlInsetInline`.
- **Ergebnis-Karte:** Innenabstand `chat.card.padding`, Titel plus
  Primär-Button über die volle Breite.
- Kein rohes JSON in der Standardansicht.

## 9. Denken (neu: `KAgentThinking`)

- **Live:**
  - Zeile `chat.disclosure.minHeight` mit pulsierendem Akzentpunkt (8 px)
    und „Denkt nach …“.
  - Bei `motion.reduced` ohne Pulsieren.
- **Danach:**
  - Zugeklappte Zeile mit Funkel-Icon: „Hat 4 s nachgedacht“.
  - Aufgeklappt erscheint der Denk-Text gedämpft, mit Einzug `space.6`.
- Reihenfolge im Agent-Beitrag: Namenszeile → Denken → Schritte → Text →
  Karten/Anhänge.

## 10. Status, Scrollen, Startseite

- Den Status gibt es immer als Text („Arbeitet“, „Wartet auf dich“,
  „Bereit“), nicht nur als Farbpunkt.
- Neue Inhalte scrollen nur mit, wenn man unten ist. Sonst erscheint ein
  Pill „Neueste Nachricht ↓“, mit `chat.block.gap` Abstand über der
  Eingabe.
- **Leeres Gespräch eines Agenten:**
  - Avatar (64), Name (`font.heading3`), Beschreibung und Icons der
    Fähigkeiten.
  - „Loslegen“ mit Vorschlagskarten (Innenabstand `chat.card.padding`,
    Abstand `controlGap`).
  - Die Eingabe bleibt unten.
- **Startseite:**
  - Begrüßung (`font.heading3`) mit `chat.block.gap` Abstand zur Eingabe,
    beides zentriert in der Spalte.
  - Abschnitte mit `chat.home.sectionGap`.
  - Listen ohne Karten, Zeilen `chat.home.rowHeight`, Trennlinie nur
    unter der Abschnittsüberschrift.
  - Rechts in der Zeile eine relative Zeit, „⋯“ beim Darüberfahren
    (Touch: immer).

---

## 11. Abnahme

1. **Tokens:** Alle neuen `component.chat.*` sind angelegt, mit Werten je
   Dichte, für Web (CSS) und Flutter erzeugt. `audit-visual-literals`
   meldet in den Chat-Komponenten 0 Pixelwerte.
2. **Fixture „Agent-Chat“** in Storybook und Widgetbook mit allen
   Zuständen:
   - leer;
   - Denken live und fertig;
   - Schritte zugeklappt und aufgeklappt;
   - Markdown mit Liste, Inline-Code und Codeblock;
   - Rückfrage offen, ausgewählt und beantwortet;
   - Formular mit Fehler;
   - Anhänge beim Hochladen und fertig;
   - Ergebnis-Karte;
   - Antwort läuft mit Stopp.
3. **Matrix:**
   - Dichte kompakt, standard und großzügig.
   - Stil apple, material und linear, jeweils hell und dunkel.
   - Phone 393, Tablet 820, Desktop 1440.
   - Textgröße 100 % und 200 %.
   - Eingabe per Zeiger und per Touch.
     Bedingung: kein Überlauf, keine Überlappung, jede Trefferfläche bei
     Touch ≥ 44/48.
4. **Geometrie-Parität:** Für jede Dichte liegen die Abstände aus
   Abschnitt 1 in Web und Flutter auf 1 px gleich (neue Einträge in
   `tooling/geometry-parity.mjs`). Insbesondere: `turn.gap`, `block.gap`,
   `option.minHeight`, Innenabstand der Eingabe und Breite der Spalte.
5. **Vergleich mit Gumloop:** Screenshot der Dichte „standard“, Desktop,
   neben den Gumloop-Referenzen (unten). Abweichungen über 4 px nennen und
   begründen.
6. **`check-consumer-ui`:** neue Regel, die selbst gebaute Codeblöcke,
   Denk- und Schritt-Zeilen sowie feste Abstände in Chat-Ansichten meldet.

## Referenzen (Mobbin, Gumloop Web)

- Startseite mit Eingabe, Triggern und letzten Gesprächen: https://mobbin.com/screens/077b229c-378b-45fd-a9da-19db94513771
- Rückfrage und Chat-Details-Panel: https://mobbin.com/screens/a0c0e7b0-88bb-4a89-904a-d88ee892a8dd
- Rückfrage mit Auswahl und aktivem Senden: https://mobbin.com/screens/e36d2331-7848-4614-8620-a39ca4051ea9
- Agent-Einstellungen im Panel: https://mobbin.com/screens/65765a76-49d2-494e-9ce5-4c2a128d458c
- Neuer Agent mit Vorschlagskarten: https://mobbin.com/screens/043a592d-8a96-411b-a6ab-32bf3a8774ff
- Laufende Antwort mit Stopp und Farbverlauf: https://mobbin.com/screens/cc947af7-dfb4-46ca-8496-d2ea3e044fc5
- „Thinking …“: https://mobbin.com/screens/5323753d-b291-4173-9c07-be915ccb12eb
- Markdown mit Codeblock und Schritten: https://mobbin.com/screens/81035142-486c-445e-a2b3-92bdbe8c3b99
- Codeblock mit Kopieren: https://mobbin.com/screens/9e98b942-1cd8-47bf-a543-657595e2c60e
- Modellauswahl: https://mobbin.com/screens/8813952b-bb55-413a-b167-88e29bd26532
- Verbindungen mit Schaltern: https://mobbin.com/screens/7f0b12c6-7553-4794-82d2-81dab902e01a
- @-Erwähnung: https://mobbin.com/screens/889efc6a-fdd8-426c-8ffc-80deea2a83b8
- Denken und Aufgaben-Karte: https://mobbin.com/screens/4bac37a2-a798-42af-951f-ce08425ff5ad
- Schritte und Ergebnis-Karte: https://mobbin.com/screens/5cf4fc76-c6d7-43a9-9d6e-2beabdccbdc3
