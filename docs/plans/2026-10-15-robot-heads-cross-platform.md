---
title: "Robot Heads: native Flutter-Portierung und Web-Parität"
date: 2026-10-15
---

# Robot Heads: native Flutter-Portierung und Web-Parität

## Auftrag und Status

Recherche gesichert am 15. Oktober 2026; die folgende Web-first-Umsetzung wurde anschließend vom Nutzer freigegeben. Aktueller Umfang: KRobotHead für React/Web, Storybook-Playground und optionale Audioansteuerung inklusive lokaler Audiodatei-Demo. Der konkrete Consumer-Vertrag und die erlaubten Pfade stehen im Abschnitt „Web-first Umsetzung freigegeben“. Flutter ist noch nicht beauftragt; visuelle Human Acceptance bleibt offen.

Ziel bleibt eine wiederverwendbare Designsystem-Komponente für React/Web sowie später natives Flutter auf Windows, Android und iOS. Widgetbook im Browser ist ergänzende Vorschau, kein Nachweis nativer Performance. Die folgenden Recherchebefunde beschreiben den fixierten Originalstand; spätere Entscheidungen sind im Web-first-Abschnitt gesondert festgehalten.

## Quellen und reproduzierbare Grundlage

Geprüfter Upstream-Stand: `58ebf6439a8125a769f63b22ffd35bc18834b1b5`.

- [Repository](https://github.com/fayazara/robot-heads/tree/58ebf6439a8125a769f63b22ffd35bc18834b1b5)
- [Playground](https://robot-heads.fayaz.workers.dev/)
- [React-Anbindung](https://github.com/fayazara/robot-heads/blob/58ebf6439a8125a769f63b22ffd35bc18834b1b5/src/RobotHead.tsx)
- [Öffentliche Typen](https://github.com/fayazara/robot-heads/blob/58ebf6439a8125a769f63b22ffd35bc18834b1b5/src/types.ts)
- [Animationstakt und Pointer](https://github.com/fayazara/robot-heads/blob/58ebf6439a8125a769f63b22ffd35bc18834b1b5/src/ticker.ts)
- [Simulation](https://github.com/fayazara/robot-heads/blob/58ebf6439a8125a769f63b22ffd35bc18834b1b5/src/tv/sim.ts)
- [Gesichter und Statuslicht](https://github.com/fayazara/robot-heads/blob/58ebf6439a8125a769f63b22ffd35bc18834b1b5/src/tv/faces.ts)
- [Geometrie](https://github.com/fayazara/robot-heads/blob/58ebf6439a8125a769f63b22ffd35bc18834b1b5/src/tv/geometry.ts)
- [Beleuchtung](https://github.com/fayazara/robot-heads/blob/58ebf6439a8125a769f63b22ffd35bc18834b1b5/src/tv/light.ts)
- [Renderer](https://github.com/fayazara/robot-heads/blob/58ebf6439a8125a769f63b22ffd35bc18834b1b5/src/tv/render.ts)
- [Playground-Anbindung](https://github.com/fayazara/robot-heads/blob/58ebf6439a8125a769f63b22ffd35bc18834b1b5/site/src/App.tsx)
- [Flutter CustomPainter](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)
- [Flutter BlendMode](https://api.flutter.dev/flutter/dart-ui/BlendMode.html)
- [Flutter Performanceprüfung](https://docs.flutter.dev/perf/ui-performance)

Die Aussagen beruhen auf Quellcodeprüfung, nicht auf einem bereits gemessenen Flutter-Prototyp. Die MIT-Lizenz erlaubt Übernahme und Portierung; Copyright und Lizenztext müssen mit ausgeliefert werden. Die Playground-Schrift Open Runde ist separat OFL-lizenziert und muss für unsere eigene Typografie nicht übernommen werden.

## Architektur des Originals

Ein eigener kleiner 3D-Renderer zeichnet auf Canvas 2D, ohne WebGL und ohne zusätzliche Laufzeitabhängigkeiten außer React als Peer Dependency. Vier Formen: rectangle, square, circle, hexagon. Das einzige Modell ist derzeit tv.

- Berechnete 3D-Flächen für Gehäuse, Ohren und Antennenkragen; Rotation, orthografische Projektion, Tiefensortierung und Backface-Culling.
- Eigene Beleuchtung: Hauptlicht, Fülllicht, Himmelslicht, Softbox, Fensterreflexion, Fresnel-Effekt, kühles Randlicht und filmische Farbumrechnung.
- Vorberechnete Relieftexturen für Gehäuseränder, Dichtung, Schrauben, rückseitige Lüftungsschlitze und Glas. Körnung entsteht aus einem stabilen Hash.
- LED-Gesicht auf einer zentralen Fläche von 22 × 14 Zellen innerhalb einer formabhängig größeren Matrix. Scharfe Leuchtkerne und weiches Bloom durch vergrößerte kleine Rasterbilder.
- Eingelassenes Display mit bewegungsabhängiger Glasreflexion und räumlichem Versatz zum Rahmen.
- Eigene Feder- und Sprungsimulation statt fertiger Animationsclips.
- Gemeinsamer Animationstakt für alle Köpfe; statische Texturen werden nach Form und Größe geteilt. Canvas-Pixeldichte wird auf maximal 2 begrenzt.

## Vollständiges Interaktionsinventar des Originals

### Blickverfolgung

- Die letzte Pointerposition wird dokumentweit beobachtet, nicht nur beim Hover über dem Roboter.
- Innerhalb von 700 CSS-Pixeln um den Ruhe-Mittelpunkt wird ein Ziel angenommen; außerhalb entfällt es.
- Nur idle, listening, speaking und happy verfolgen den Pointer. Die übrigen Zustände behalten ihre eigene Haltung.
- Horizontaler und vertikaler Abstand steuern Kopfrotation, Neigung, seitliches Kippen und Augenposition unterschiedlich stark und begrenzt.
- Konkret: yaw = clamp(dx / 260, -1, 1) × 0.55; pitch = -clamp(dy / 260, -1, 1) × 0.32; roll = -yaw × 0.12 plus 0.12 bei listening. Augen: dx / 120 begrenzt auf ±2.4 und dy / 160 auf ±1.4 Zellen.
- Der Kopf folgt über Federn; Augenpositionen werden für das LED-Raster gerundet.
- Bei pointerleave des Dokuments oder Fenster-Fokusverlust wird das Ziel gelöscht. Danach übernimmt die zustandseigene Bewegung.
- Kein öffentliches Prop für einen externen Zielpunkt; keine ausdrücklich geregelte Touch-Ende-/Abbruchlogik.

### Aktivierung per Klick

- Bei interactive und laufender Animation löst Klick eine Reaktion aus: 110 ms Vorbereitung mit Einfedern, Streckung beim Abheben, parabelförmiger Sprung, vollständige Drehung mit zufälliger Richtung, leichtes Kippen, Landestauchung und Nachschwingen der Antenne.
- Der Sprung hat seine eigenen Parameter und ist der laufenden Zustandshaltung überlagert.
- Das Gesicht zeigt vorübergehend happy, für 1.6 Simulationssekunden. Der vom Consumer gesetzte Zustand bleibt erhalten; anschließend kehrt das Gesicht dorthin zurück.
- Weitere Klicks starten keinen parallelen Sprung, können aber die happy-Reaktion verlängern.
- Der Consumer-onClick wird auch aufgerufen, wenn die interne Reaktion deaktiviert ist.
- Trefferfläche ist die quadratische Ruhe-Layoutfläche. Sprünge, Schatten und Glühen können darüber hinauszeichnen, erweitern aber die Trefferfläche nicht. Clipping durch übergeordnete Container kann diese Effekte abschneiden.

### Zustände und Mikrointeraktionen

| Zustand   | Gesicht und Körper                                                                                                                                   | Antennenlicht                          |
| --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- |
| idle      | Umherblicken, Blinzeln, gelegentliches Hüpfen, teilweise Drehung                                                                                     | Warmweiß, sanfte Helligkeitsschwankung |
| thinking  | Blick schräg nach oben, schwere Lider, drei versetzt pulsierende und leicht hüpfende Punkte; wechselnde Kopfseite                                    | Bernsteinfarben pulsierend             |
| searching | Seitliches Suchen; Augen führen Kopfbewegung an; senkrechte Scanlinie wandert quer über das ganze Display mit Nachlauf                               | Cyanfarbene Lichtimpulse               |
| listening | Aufmerksame Augen, animierter Equalizer, schräger Kopf, gelegentliches Nicken                                                                        | Konstant grün                          |
| speaking  | Animierter Mund, Nicken und Wippen                                                                                                                   | Weiß, wechselnde Helligkeit            |
| working   | Schmale nach unten blickende Augen, wiederholter Fortschrittsbalken, geschäftiges Wippen und gelegentliche Sprünge mit Drehung                       | Blau blinkend                          |
| happy     | Dachförmige Augen, breites Lächeln, bewegtes Gesicht, Wippen und wiederholtes Hüpfen                                                                 | Rosa pulsierend                        |
| error     | Flackernde X-Augen, gezackter Mund, wiederholtes Kopfschütteln                                                                                       | Rot blinkend; Display-LEDs werden rot  |
| sleeping  | Geschlossene gedimmte Augen, aufsteigende/verblassende große und kleine Z-Zeichen, gesenkter Kopf, langsame Atembewegung und gelegentliches Absinken | Aus                                    |

Equalizer und Mund sind synthetisch zeitgesteuert, nicht audioreaktiv. Der Fortschrittsbalken läuft im Original alle 2.6 Simulationssekunden durch und stellt keinen echten Fortschritt dar. Reale Audiopegel oder Fortschrittswerte wären zusätzliche Funktionen, keine vorhandenen Upstream-Fähigkeiten.

### Übergänge und sekundäre Effekte

- Einschalten: Helle horizontale Linie öffnet sich zum ganzen Display; Effekt innerhalb der ersten 550 ms Simulationszeit, einschließlich Hochfahren des Antennenlichts.
- Gesicht wechselt mit 300 ms Crossfade; erste 130 ms enthalten Glitch mit versetzten LED-Zeilen und zusätzlichen hellen Zellen.
- Display- und Antennenfarben sowie Antennenhelligkeit blenden bei Statuswechseln über.
- Kopfhaltungen gehen federnd ineinander über, mit zustandsabhängiger Frequenz und Dämpfung.
- Unregelmäßiges Blinzeln, 170 ms pro Blinkbewegung; gelegentliches Doppelblinzeln. Sleeping zeigt geschlossene Augen.
- Antenne reagiert auf Beschleunigung, Abheben und Aufkommen, mit begrenztem Ausschlag und Nachschwingen in zwei Achsen.
- Boden-Schatten schrumpft und verblasst mit der Sprunghöhe.
- Reflexionen wandern mit der Orientierung; Glas und Rahmen behalten ihren Tiefenversatz. Rückseite mit Lüftungsschlitzen wird bei Drehungen sichtbar.
- Seed steuert unterschiedliche Blick-, Blink- und Sprungfolgen mehrerer Roboter. Ohne expliziten Seed leitet React ihn aus useId ab.

### Laufzeitsteuerung und bekannte Randfälle

- speed skaliert die gesamte Simulationszeit; speed ≤ 0 oder paused führt zur Stilldarstellung.
- Widerspruch im Original: Der paused-Typkommentar verspricht Einfrieren des aktuellen Frames. Die Implementierung zeichnet stattdessen restPose des Zustands mit einem festen Gesichtssample. Simulation wird nicht weitergetaktet.
- Reduced Motion verwendet ebenfalls die Ruhepose. Änderungen der Systemeinstellung werden nicht durch einen eigenen Listener verfolgt. Die Einstellung allein unterdrückt nicht den internen Klicktrigger.
- Bei verstecktem Browser-Tab stoppt der gemeinsame Takt. Einzelne außerhalb des Viewports liegende Köpfe werden nicht automatisch pausiert.
- Große Frame-Abstände werden vor speed-Skalierung auf 100 ms begrenzt; die Simulation unterteilt Schritte auf höchstens 1/120 Sekunde, verwendet jedoch keine durchgehend feste Schrittfolge.
- interactive=false unterbindet Zeigerverfolgung und Klickreaktion, nicht die autonome Zustandsanimation.
- antenna=false entfernt Stab und Licht, lässt den Knopf bestehen und passt die Größenberechnung an. floorShadow ist unabhängig abschaltbar.
- Der interaktive span besitzt role=img mit überschreibbarem Label, aber keine eingebaute Tastaturaktivierung. Das Canvas ist aria-hidden.
- Farben, Größe, Form und Zustand sind Props. Ein nachträglicher Seed-Wechsel initialisiert die bereits bestehende Simulation nicht neu; Reset-Verhalten muss für unseren Vertrag geklärt werden.

## Ergänzungen für unsere Bibliothek — Vorschläge

Diese Vorschläge sind noch keine genehmigte öffentliche API:

1. Eingabequelle wählen: automatische Pointersteuerung, externer Zielpunkt oder keine Blickverfolgung. Bei externer Steuerung eindeutige Priorität gegenüber automatischen Eingaben.
2. Klar definierter Koordinatenraum und Umrechnung relativ zum Ruhe-Mittelpunkt; Reichweite, Empfindlichkeit und maximale Ausschläge mit sinnvollen Defaults. Alternativ normalisierte Koordinaten prüfen, ohne beide Systeme unnötig zu vermischen.
3. Ein Consumer kann Maus-, Finger-, UI- oder Gesichtstracking-Koordinaten liefern. Keine Kamera, Gesichtserkennung oder Berechtigungsabfragen innerhalb der Komponente.
4. Zielverlust über null; explizit festlegen, ob nach Touch-Ende sofort freigegeben oder optional gehalten wird. Pointer-Cancel und Mehrfinger-Eingaben zuverlässig behandeln; Scrollgesten dürfen keine Aktivierungsreaktion auslösen.
5. Status, Geschwindigkeit und Pause kontrollierbar; Aktivierungs-Event unabhängig von interner Reaktion. Programmatischer Reaktionstrigger sowie Reaktionsbeginn/-ende als mögliche Controller-/Event-Funktionen prüfen.
6. Echte Pause (aktueller Frame) und Reduced-Motion-Ruhepose bewusst unterscheiden. Dieselbe Entscheidung in beiden Plattformen umsetzen; Abweichung vom Original dokumentieren.
7. Tastaturaktivierung, lokalisierbare Semantik und dynamische Reduced-Motion-Einstellung berücksichtigen.
8. Consumer-Texte, Events und Verhalten von visuellen Design-Tokens trennen. Vorhandene Tokens wiederverwenden; keine ungeprüften neuen Tokenachsen. Identische Upstream-Optik als Referenz bewahren.
9. Echte Audio- oder Fortschrittseingaben nur als gesonderten Umfang aufnehmen, nicht stillschweigend versprechen.

## Portierungsstrategie und Performance

Geometrie, Beleuchtungsformeln, LED-Muster, Zustandssimulation und Zeichenreihenfolge nach Dart übertragen. CustomPainter mit repaint-Listenable verwenden, ohne Widget-Rebuild und Layout pro Animationsframe. Canvas, Path, Bilder, Gradienten und passende BlendModes sind die vorgesehenen Bausteine; keine WebView als Ersatz für native Flutter-Parität.

Geometrie und statische Texturen zwischenspeichern, begrenzte Caches und Lebensdauerverwaltung vorsehen, Zahlenpuffer wiederverwenden. Teure Pixelberechnungen nicht im laufenden paint ausführen. Bildvorbereitung und Uploadkosten separat messen. Unsichtbare, pausierte oder im Hintergrund liegende Instanzen sollen keine unnötige Arbeit verursachen. Zusätzliche saveLayer-Aufrufe begrenzen und profilieren.

CustomPainter macht CPU-seitige Geometrie-, Sortier- und Lichtberechnungen nicht automatisch zu GPU-Arbeit. Eine Framerate ist erst nach Profiling belegbar. Ziel: flüssige 60 fps auf einem repräsentativen realen Gerät; 120 fps und große Instanzzahlen separat messen statt pauschal zusagen.

## Determinismus und Pixelparität

- JavaScript-32-Bit-Operationen des Seed-Generators und Hashes exakt nachbilden; nicht durch Dart Random ersetzen.
- Float32-Puffer, Rundung, Modulo bei negativen Werten, Farbumrechnung und Alpha-Behandlung ausdrücklich berücksichtigen.
- Gleiche Eingaben benötigen dieselbe Zeitbasis. Gleicher Seed allein reicht bei unterschiedlichen Frame-Schritten nicht aus. Für Tests dieselbe Schrittfolge einspeisen; gemeinsame feste Simulationsschritte für beide Plattformen als bewusste Änderung prüfen.
- Gleiche Größe, Pixeldichte, Farben, Hintergrund, Seed, Pose, Zeit und Eingabesequenz für Vergleichsbilder verwenden.
- Additives Bloom, source-atop-Maskierung, Texturfilterung, Gradienten und Kantenglättung können zwischen Browser-Canvas und Flutter-Renderern abweichen. Diese Abweichungen messen und gezielt beseitigen; keine absolute Pixelidentität vorab behaupten.
- Ein automatisierter Nachweis muss sowohl Zahlenwerte als auch gerenderte Bilder vergleichen. Bildbaselines nicht bloß zum Bestehen aktualisieren. Toleranzen vor der Abnahme festlegen und verbleibende Unterschiede sichtbar dokumentieren.

## Vorgeschlagene Umsetzungsschritte

1. Aktuellen main-Stand und geltende Repository-Regeln prüfen; fremde Änderungen erhalten. Upstream auf den oben genannten Commit fixieren.
2. Reproduzierbaren Referenz-Harness mit explizitem Seed, steuerbarer Zeit und aufgezeichneten Eingaben erstellen. Bestehende React-Komponente im Designsystem-Wrapper demonstrieren.
3. Einen rechteckigen Kopf vollständig nativ portieren: Material, LED-Gesicht, Antenne, Statusübergänge und Aktivierungsreaktion. Keine visuell vereinfachte Ersatzanimation.
4. Mathematik-, Bild- und Performancevergleich durchführen; Risiken früh klären, bevor sämtliche Formen übernommen werden.
5. Alle vier Formen und neun Zustände sowie freigegebene externe Steuerungsmöglichkeiten vervollständigen.
6. Matching Fixtures in Storybook und Widgetbook bereitstellen: Zustandsmatrix, Pointer/Finger/externes Ziel, Klick/Tap, Statuswechsel während Reaktion, Pause, Reduced Motion, mehrere Instanzen und kleine Größen.
7. Native Messungen auf Android und Windows; iOS auf geeigneter verfügbarer Hardware. Fehlende Plattformnachweise ausdrücklich offenlassen.
8. Dokumentation, Drittanbieterhinweise, Consumer-Beispiele und Exportverträge ergänzen; pnpm verify vor Commitvorschlag. Menschliche visuelle Endabnahme bleibt separat.

## Vergleichsmatrix und Nachweise

- Vier Formen × neun Zustände; kleine Avatargröße und große Einzelansicht; Light/Dark, Antenne und Schatten an/aus.
- Blickpunkt innerhalb/außerhalb Reichweite, extreme Koordinaten, Zielverlust, erlaubte und nicht verfolgende Zustände.
- Maus, Touch mit Down/Move/Up/Cancel, Tap versus Scroll, Tastatur sowie externes Ziel aus simuliertem Gesichtstracking.
- Klick, Mehrfachklick, Klick während Sprung, Statuswechsel während happy-Reaktion, Rückkehr zum Consumer-Status.
- Einschalten, Crossfade, Glitch, Blink-/Doppelblinkfolge, Antennennachlauf, Schatten und Reflexionen an festen Zeitpunkten.
- Pause/Resume, speed=0, Geschwindigkeitswechsel, dynamisches Reduced Motion, Hintergrund/Resume und Sichtbarkeitswechsel.
- Golden-Daten für Geometrie, Pose, LED-Raster, Lichtwerte und Seed-Folge; Screenshot-Diffs und synchronisierte Animationen.
- Profiling nach Warm-up sowie bei erstem Auftreten: UI-/Rasterzeiten, verpasste Frames, Speicher, Texturerzeugung, mehrere sichtbare und unsichtbare Instanzen. Messungen im Profile-/Release-Modus auf realen Geräten.

## Grenzen dieses Auftrags und nächste Entscheidung

Aktueller Auftrag: nur dieses Markdown-Dokument und den zugehörigen Planindex anlegen. Keine Komponenten, Dependencies, Tokens, Commits oder Pushes ändern.

Späterer erlaubter Implementierungsumfang muss die betroffenen Pfade konkretisieren: packages/web/ui, packages/flutter/k_design_ui, passende Storybook-/Widgetbook-Fixtures, gezielte Tests/Tooling und Komponentendokumentation. Tokenquellen oder Paketgrenzen nur mit explizitem Bedarf und Entscheidung ändern.

Offen vor Festlegung der öffentlichen API: Zielkoordinaten und Prioritäten, Touch-Endverhalten, echte Pause versus Ruhepose, programmatische Reaktionssteuerung, Reset/Seed-Wechsel und gemeinsame Zeitbasis. Die Recherche belegt technische Machbarkeit, noch keine gemessene native Performance oder bestätigte Pixelparität.

### Web-first Umsetzung freigegeben (2026-10-15)

Der Nutzer hat KRobotHead für Web und den Storybook-Playground freigegeben, einschließlich optionaler Audioansteuerung und lokaler Audiodatei-Demo. Flutter-Portierung bleibt ausdrücklich nachgelagert. main wurde vor Umsetzung per Fast-forward auf 1d71d49 aktualisiert. Die frühere Kontingent-Stoppgrenze wurde vom Nutzer vollständig aufgehoben.

Erlaubte Pfade: packages/web/ui (Komponente, interner Renderer, öffentliche Typen, Styles, Lizenz, Tests), apps/storybook/src (Playground und Audiodemo), zugehörige Komponentendokumentation. Keine Flutter-Komponente, kein Commit/Push in diesem Auftrag.

Audiovertrag: Consumer besitzt Wiedergabe, Berechtigungen, MediaStream/MediaElement und AudioContext. KRobotHead nimmt einen normalisierten Pegel und optionale Frequenzbänder oder einen frameweise abgefragten Reader an. createKRobotHeadAudioReader adaptiert einen bereits vorhandenen AnalyserNode. Ohne audio bleibt die synthetische Animation erhalten; null vom Reader bedeutet Stille. Keine eingebaute Kamera, Mikrofonaufnahme oder phonemische Lippensynchronisierung. Die Storybook-Demo verwendet eine lokale Blob-URL und lädt nichts an einen Server hoch.

Zielpunkte: undefined bedeutet Pointer/Finger, null deaktiviert Tracking, ein Objekt liefert normalisierte Koordinaten -1 bis 1 mit Priorität. Touch-Ende und Pointer-Abbruch lösen das Ziel. Pause friert den aktuellen Frame ein; Reduced Motion verwendet die Ruhepose und blockiert Reaktionen. Seed-Wechsel setzt die Simulation zurück. Ref-Methoden react/reset sowie Aktivierungs- und Reaktions-Events sind der Consumer-Vertrag dieser Web-Scheibe.

Verifikation: Web-Build/Typecheck, gezielte Renderer-/Audio-/Semantiktests, Styleaudit, Browserprüfung mit lokaler WAV-Datei und Responsive-Ansicht, abschließend pnpm verify. Visuelle Human Acceptance und native Flutter-Parität bleiben offen.
