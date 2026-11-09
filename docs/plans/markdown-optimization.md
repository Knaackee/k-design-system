# Markdown: Bestandsaufnahme und Optimierungsplan

Stand: 2026-11-09

Status: Phasenplan zur Umsetzung vorbereitet; diese Änderung enthält nur Planung.

Grundlage: Repository-Audit und ergänzender Nutzerauftrag „Markdown-Rendering als
Designsystem-Komponente (Web + Flutter)“. Der Auftrag wird an die vorhandene
Architektur angepasst, nicht als Vorgabe für einen Austausch der Infrastruktur
übernommen. Human-Abnahme erfolgt durch den Nutzer in Storybook und Widgetbook.

## Ziel

Markdown-Komponenten in Web/React und Flutter funktional und visuell angleichen.
Storybook und Widgetbook müssen dieselben Komponenten, Fähigkeiten und Szenarien
zeigen. Properties und Events sollen semantisch gleichwertig sein; idiomatische
Benennung darf plattformspezifisch bleiben. Aussehen wird über Design-Tokens,
Inhalte und Verhalten werden durch die konsumierende Anwendung gesteuert.

## Grundlage und Grenzen der Prüfung

Geprüft wurden Implementierungen, öffentliche Schnittstellen, Galerieeinträge und
vorhandene Tests. Die Findings sind eine Quelltextprüfung, keine erneute visuelle
Paritätsabnahme. Tests wurden für diese Bestandsaufnahme nicht ausgeführt.
Pixelparität und plattformübergreifende CRDT-Interoperabilität sind damit nicht
nachgewiesen. Ausgangsstand der Prüfung: `main`, Commit `9f9e942`.

## Vorhandene Funktionen

| Bereich | Bestand |
| --- | --- |
| `KMarkdownEditor` | Auf beiden Plattformen: Markdown-Quelltext bearbeiten und Vorschau anzeigen |
| Formatierung | Fett, kursiv, durchgestrichen, Inline-Code, Codeblöcke, Links, Listen, Aufgabenlisten und Zitate |
| Bedienung | Formatbar, Floating-Toolbar, Suche/Ersetzen, Undo/Redo |
| Konfiguration | Inhalt, Read-only, Texte, Formatierungsaktionen und Sichtbarkeit der Bedienelemente |
| Events | Inhaltsänderung mit Transaktion, Auswahländerung, Moduswechsel, Fokus und Blur |
| Bilder | Consumer können Bilddarstellung beziehungsweise Auflösung übernehmen |
| Diktieren | Optionale Oberfläche; Aufnahme und Transkription bleiben beim Consumer |
| Zusammenarbeit | Remote-Auswahlen und Anbindung an gemeinsame Dokumentzustände |
| Chat | Markdown-Darstellung innerhalb von Chatnachrichten |

## Konkrete Findings

### 1. Unterschiedliche CRDT-Anbindung

Web liefert eine konkrete Yjs-Anbindung einschließlich binärem Transport.
Flutter bietet einen transportneutralen `KEditorCollaborationAdapter`, den der
Consumer implementieren muss. Beide APIs sind integrationsfähig, belegen aber
noch keine gemeinsame Web-/Flutter-Kollaboration.

### 2. Unterschiedliche Link-Bedienung

Web verwendet beim Einfügen eines Links noch `window.prompt("Link URL", …)` mit
festem Text. Flutter bietet `onLinkRequested`. Bei Vorschau-Links bietet Flutter
`onLinkPressed`, während Web gewöhnliche Links ohne entsprechenden Editor-Callback
rendert. Der native Browserdialog passt nicht zum Designsystem-Vertrag.

### 3. Unterschiedliche zusätzliche Editor-Möglichkeiten

Web bietet Slots für einen externen Rich-Editor samt Toolbar und Overlay sowie
eine Referenz auf den Source-Editor. Flutter bietet unter anderem explizite
Inhaltsbreite, Mindesthöhe und Mindestgröße der Formatbar-Items. Die
Diktier-Schnittstellen sind ebenfalls unterschiedlich aufgebaut.

Diese Unterschiede müssen in einer Capability-Matrix bewertet werden. Nicht jede
plattformtypische Property benötigt denselben Namen, aber gleichartige Aufgaben
müssen auf beiden Plattformen lösbar oder ausdrücklich als Ausnahme dokumentiert
sein.

### 4. Unterschiedliche Chat-Markdown-Funktionen

Web aktiviert Kopieraktionen für Code und Tabellen. Flutter `KChatMarkdown`
enthält diese Aktionen nicht. Flutter verwendet dort ausdrücklich eine kompakte
Textgröße und aktiviert Textauswahl abhängig von der Fensterbreite. Diese
Entscheidungen müssen gegen die gemeinsame Typography-, Density- und
Interaktionsvorgabe geprüft werden.

### 5. Keine einheitliche öffentliche Markdown-Anzeigekomponente

Web besitzt intern `KMarkdownPreview`, exportiert sie aber nicht über den
Editor-Einstieg. Flutter hat eine private Editor-Vorschau und die öffentliche,
chatspezifische `KChatMarkdown`. Ein gemeinsamer, unabhängig vom Editor nutzbarer
Darstellungsvertrag ist noch nicht definiert.

### 6. Unterschiedliche Galerieabdeckung

Beide Galerien enthalten Desktop-, Mobile- und Diktier-Demos. Storybook enthält
zusätzlich eine Collaboration-Demo; im Widgetbook-Editorbereich ist kein
Gegenstück registriert. Benennungen sind nicht durchgehend identisch. Die
Flutter-Standard- und Mobile-Markdown-Demos aktivieren außerdem Diktieren bereits
im normalen Editor-Fixture.

### 7. Verifikation beweist noch keine vollständige Parität

Es gibt Tests für Vorschau, Formatierung, Undo/Redo, Suche und Zusammenarbeit.
Web-Vorschautests behandeln auch Tabellen, Bilder, Code, relative Bilder und das
Unterdrücken von HTML beziehungsweise ausführbaren URLs. Diese Einzeltests
ersetzen keine gemeinsamen Dokument-Fixtures, Interaktionstests und visuellen
Vergleiche beider Plattformen.

## Zielarchitektur und verbindliche Leitlinien

- `KMarkdownRenderer`: öffentlicher Rendering-Kern pro Plattform mit semantisch
  gleichem Vertrag. Eingaben umfassen Inhalt, Darstellungsprofil, Streaming-Zustand,
  erlaubte Elemente, Bildauflösung sowie Link- und Kopieraktionen. Konkrete
  Signaturen werden in Phase 1 festgehalten.
- `KMarkdownPreview`: eigenständige Dokumentansicht auf diesem Kern, mit optionaler
  Lesebreite und anpassbaren Leer-/Ladezuständen. Die Editor-Vorschau verwendet
  denselben Kern. Chat bindet ihn in die bestehenden Nachrichtenkomponenten ein.
- Unterschiedliche Renderer-Adapter sind erforderlich; keine getrennten,
  auseinanderlaufenden Markdown-Styles für Chat und Vorschau. Dokument und Chat
  dürfen semantische Darstellungsprofile haben.
- Bestehende Density-, TypeScale- und InputMode-Einstellungen bleiben maßgeblich.
  Keine parallele Density-Achse `comfortable/compact` einführen.
- Vorhandene Token-Quelle und Generatoren behalten. Markdown-spezifische Tokens
  nur für belegte semantische Anpassungspunkte, möglichst als Referenzen auf
  bestehende Tokens. Kein automatischer Wechsel zu Style Dictionary oder
  `dtcg_theme`, keine neue Tailwind-Typography-Abhängigkeit allein für dieses Ziel.
- Bestehendes Streamdown im Web und `flutter_markdown_plus` in Flutter zunächst
  weiterverwenden. Fehlende Fähigkeiten durch begrenzte Adapter ergänzen, nicht
  durch einen ungeprüften Bibliothekswechsel.
- Bestehende K-Primitives verwenden, sofern sie dem Inhalt und der Semantik
  entsprechen. Layout-, Farb-, Radius- und Typografiewerte tokenisieren.
- Consumer behalten Daten, Navigation, Aufnahme/Transkription und Transport.
  Keine versteckten Netzwerk-, Mikrofon- oder Navigationsaktionen einführen.
- Keine Funktionen still auf den kleinsten gemeinsamen Umfang reduzieren.
  Unvermeidbare Grenzen dokumentieren und mit dem Nutzer abstimmen.

## Phasenplan

Die Phasen bauen sequenziell aufeinander auf. Ab Phase 2 wird jedes sichtbare
Ergebnis in beiden Galerien bereitgestellt und vom Nutzer abgenommen. Ein
technisch bestandener Test ersetzt diese Abnahme nicht. Die Galerien dürfen
nicht dauerhaft unterschiedliche Funktionsstände behalten.

### Phase 1: Vertrag, Baseline und gemeinsame Fixtures

**Ergebnis:** Ein implementierbarer Vertrag und reproduzierbare Vergleichsfälle.

- Alle sieben Findings in einer Capability-/Property-/Event-Matrix erfassen;
  jede Zeile erhält eine geplante Lösung oder dokumentierte Plattformgrenze.
- Signaturen für Renderer, Preview, Link-Anfrage/-Aktivierung, Bildauflösung,
  Copy, Diktieren und Collaboration festlegen. Native Namenskonventionen sind
  erlaubt, unterschiedliche Fähigkeiten nicht ungeprüft.
- Bestehende Integrationen und öffentliche Exporte berücksichtigen; additive
  APIs beziehungsweise dokumentierte Migration statt stiller Breaking Changes.
- Vorhandene Token- und Primitive-Abdeckung prüfen; konkrete neue semantische
  Tokens und ihre Defaults festlegen, ohne globale Defaults anderer Komponenten
  beiläufig zu verändern.
- Gemeinsame Quelldateien unter `fixtures/markdown/` planen: `basic.md`,
  `tables.md`, `code.md`, `alerts.md`, `images.md`, `long-document.md`,
  `chat-reply.md`, `streaming-partial.md`, `edge-cases.md`. Beide Galerien laden
  dieselben Inhalte; eine deterministische Asset-Projektion ist bei Bedarf
  zulässig, manuell gepflegte Kopien nicht.
- Ausgangsdarstellung bei gleichen Einstellungen festhalten. Bestehende
  Vergleichs-/Golden-Infrastruktur ermitteln und wiederverwenden.

**Pfade:** `docs/plans/markdown-optimization.md`, bestehende Komponentenverträge
und Token-Quellen nach deren Ermittlung, `fixtures/markdown/`, Galerie-Fixtures.

**Prüfung:** Matrix gegen öffentliche APIs abgleichen; Fixture-Inhalte und IDs
auf beiden Plattformen nachweisen. Grundlegende öffentliche API-/Token-Entscheidungen
vor ihrer Implementierung festhalten und gemäß Repository-Vertrag bestätigen.

### Phase 2: Gemeinsamer Renderer und hochwertige Grunddarstellung

**Abhängigkeit:** Phase 1.
**Ergebnis:** `KMarkdownRenderer` in beiden Galerien, für Dokument- und Chatprofil.

- Überschriften h1–h6, Absätze, Hervorhebungen, Links, Listen, read-only
  Aufgabenlisten, Bilder, Trennlinien, Zitate und GFM-Alerts abdecken.
- Ruhige Typografie und abgestimmte vertikale Abstände statt technischer
  Standarddarstellung. Zitate und Alerts semantisch unterscheiden und passende
  vorhandene Callout-/Text-/Link-Primitives einsetzen.
- Tabellen: keine Zellenkästen oder vertikalen Linien, dezente horizontale
  Trenner, zurückhaltender Kopf, tokenisierte Zellabstände. Explizite
  Markdown-Ausrichtung respektieren; keine automatische Umdeutung von Zahlen.
- Inline-Code und Codeblöcke mit Monospace-Tokens, Syntax-Highlighting,
  anpassbaren Copy-Aktionen und sicherem Fallback für unbekannte Sprachen.
- Breite Tabellen/Codeblöcke lokal scrollen lassen; lange Wörter und URLs dürfen
  nicht die gesamte Seite verbreitern. Bilder mit Consumer-Resolver und
  Lade-/Fehlerzuständen, ohne den Markdown-Quelltext umzuschreiben.
- Gleiche HTML-Regel: Raw HTML nicht ausführen/rendern; Behandlung mittels
  gemeinsamer Fixtures eindeutig festlegen. Protokollprüfung für Links/Bilder,
  auch bei späterem Consumer-Override, ausdrücklich dokumentieren.

**Pfade:** `packages/web/ui/src/editors/`, `packages/web/ui/src/editors.css`,
Flutter-Editor-/Rendering-Code in `packages/flutter/k_design_ui/lib/src/`,
öffentliche Exporte, belegte Token-Quellen, beide Galerien.

**Tests:** `packages/web/ui/markdown-preview.test.mjs` erweitern; neue fokussierte
Renderer-Tests `packages/web/ui/markdown-renderer.test.mjs` und
`packages/flutter/k_design_ui/test/markdown_renderer_test.dart` vorsehen.
Prüffälle: alle Elementtypen, relative Bilder, unsichere URLs/HTML, leere Zellen,
unbekannte Codesprache, lange URLs, Emojis/Umlaute, RTL und lokaler Overflow.

**Human-Abnahme:** gleiche Fixtures in Light/Dark, mobil/Desktop, Dokument/Chat;
Typografie, Tabellen, Code und Abstände nebeneinander prüfen.

### Phase 3: Preview und Chat integrieren, Streaming härten

**Abhängigkeit:** abgenommene Grunddarstellung aus Phase 2.
**Ergebnis:** Alle vorgesehenen Anzeigewege nutzen den gemeinsamen Kern.

- Öffentliche `KMarkdownPreview` bereitstellen; Editor-Vorschau und bestehende
  Chatnachrichten darauf beziehungsweise auf den Renderer umstellen.
- Lesebreite, Leer-/Ladezustände, erlaubte Elemente und anpassbare Aktionen
  demonstrieren. Nutzernachrichten können einen reduzierten Elementumfang erhalten.
- Kopieraktionen für Code/Tabellen und Link-Events auf beiden Plattformen
  gleichwertig verfügbar machen. Textauswahl und Scrollen nach Eingabemodus
  prüfen, nicht ausschließlich anhand der Fensterbreite bestimmen.
- Deterministische Streaming-Sequenzen verwenden: offene Hervorhebungen,
  unvollständige Links, Codeblöcke und Tabellen. Flutter braucht hierfür eine
  explizit getestete Strategie; `streaming: true` allein genügt nicht.
- Bestehenden Inhalt und Scrollposition möglichst stabil halten. Wachsende
  Inhalte dürfen Layout verändern; keine unrealistische Garantie völlig
  unveränderlicher Geometrie geben. Keine Veröffentlichung jedes Tokens als
  störende Screenreader-Ansage.

**Pfade:** Renderer-/Preview-Dateien, `packages/web/ui/src/chat/conversation.tsx`,
`packages/flutter/k_design_ui/lib/src/chat/k_chat_markdown.dart`, Chat- und
Editor-Fixtures beider Galerien.

**Tests:** Renderer-Tests aus Phase 2 um Streaming-Zwischenstände ergänzen;
bestehende Chat-Tests um Copy/Link-Callbacks, Auswahl und Scrollen erweitern.
Fertiger Streaming-Inhalt muss dieselbe Darstellung wie statischer Inhalt ergeben.

**Human-Abnahme:** Dokumentvorschau, User-/Agent-Nachrichten und sichtbare
Streaming-Demo mit denselben Zwischenständen auf beiden Plattformen.

### Phase 4: Editor-, Event- und Collaboration-Lücken schließen

**Abhängigkeit:** gemeinsamer Renderer und Integration aus Phase 3.
**Ergebnis:** Die bestehende Bearbeitung ist funktional angeglichen.

- `window.prompt` durch tokenisierte K-Komposition mit lokalisierbaren Texten
  und Consumer-Hook ersetzen; Link-Erstellung und Link-Aktivierung trennen.
- Unterschiede bei Inhaltsbreite, Toolbar, Fokus, Auswahl, Editor-Zugriff und
  optionaler Diktier-Oberfläche anhand der Matrix schließen. Keine neue
  Bearbeitungsart hinzufügen, nur bestehende Rich-Host-Integration bewahren.
- Controlled Updates, Read-only, Undo/Redo, Suche/Ersetzen und Formatierung
  ohne verlorene Auswahl, doppelte Events oder Remote-Echo-Schleifen härten.
- CRDT-Vertrag ausdrücklich prüfen: Web-Yjs-Transport ist nicht dasselbe wie
  Flutter-Snapshot-Anbindung. Adapter-Beispiel und gemeinsame Interoperabilitätsprobe
  für gleichzeitige Änderungen, Reconnect, Presence und Undo erstellen. Falls
  die vorhandene Flutter-Basis dazu keine kompatible Engine bereitstellt,
  Befund und konkrete Adapter-/Abhängigkeitsentscheidung vor deren Einführung
  vorlegen; nicht durch einen bloßen Snapshot-Test als erledigt ausweisen.
- Collaboration-Demo im Widgetbook ergänzen; Diktieren als eigenständiges
  Szenario und optionales Feature auf beiden Seiten zeigen.

**Pfade:** vorhandene Editor-, Dictation- und Collaboration-Dateien, öffentliche
Exports und Editor-Fixtures beider Plattformen.

**Tests:** `packages/flutter/k_design_ui/test/editors_test.dart` und vorhandene
Web-Editor-/Collaboration-Tests erweitern; fehlende fokussierte Tests ergänzen.
Prüffälle: lokaler/Remote-Ursprung, einmalige Events, Link-Abbruch, Undo nach
Remote-Update, Diktier-Abbruch, Read-only, Wechsel Quelle/Vorschau und Reconnect.

**Human-Abnahme:** Bearbeitung und Kollaborationsszenarien in beiden Galerien;
Interoperabilitätsstatus zusätzlich anhand technischer Ergebnisse belegen.

### Phase 5: Plattformübergreifende Härtung und Dokumentation

**Abhängigkeit:** Phasen 2–4.
**Ergebnis:** Nachvollziehbar geprüfter, dokumentierter Kernumfang.

- Gemeinsame Story-/Fixture-IDs und vollständige Abdeckung kontrollieren.
- Light/Dark, alle bestehenden Density-/TypeScale-Modi, Touch/Maus/Tastatur,
  schmale Displays sowie Desktop-Breiten vergleichen. Flutter zusätzlich nativ
  prüfen; Widgetbook im Browser allein belegt Windows-/Android-/iOS-Verhalten nicht.
- Kontrast mindestens WCAG AA, Fokus, Semantik, Tastatur- und Screenreader-Bedienung
  prüfen. Plattformbedingte Rasterisierungsunterschiede offen ausweisen; sie dürfen
  keine unterschiedlichen Layouts oder fehlenden Funktionen rechtfertigen.
- Lange Dokumente und Streaming auf Rebuild-/Renderkosten und Scroll-Flüssigkeit
  prüfen; keine komplette Dokumentneuerstellung pro kleiner UI-Zustandsänderung.
- Bestehende visuelle Regressionstests ergänzen; Baselines nicht ohne bewusste
  visuelle Abnahme ersetzen. Web-/Flutter-Screenshots gleicher Fixtures vergleichen.
- Markdown-Dokumentation mit öffentlicher API, Token-Mapping, Element-Mapping,
  Einsatzorten, Migration, Consumer-Beispielen und bekannten Grenzen erstellen.
- Gezielte Tests und abschließend `pnpm verify` vor einem Commit durchführen.

**Pfade:** Tests, bestehende Visual-Test-Infrastruktur, Galerien und
`docs/markdown.md` (neu); README mit kurzem Verweis, falls passend.

**Human-Abnahme:** gemeinsame Abschlussprüfung in Storybook und Widgetbook.
Offene Abweichungen und nicht getestete Geräte ausdrücklich auflisten.

### Phase 6: Optionale Dokument-Erweiterungen

**Abhängigkeit:** abgenommener Kernumfang; gesonderte Priorisierung durch den Nutzer.

- Inhaltsverzeichnis mit stabilen Heading-IDs und Ankern.
- Optionale Split-Ansicht Quelle/Vorschau als Komposition des bestehenden Editors,
  ohne zweites Dokumentmodell und ohne zusätzlichen editierbaren Rich-Modus.
- Separate identische Stories und Tests für Ankernavigation, doppelte Überschriften,
  schmale Ansichten und synchronen Dokumentzustand auf beiden Plattformen.

Diese Erweiterungen sind erhaltene Wünsche aus dem Auftrag, keine Voraussetzung
für die Reparatur und Abnahme des Kernumfangs. Sie werden nicht stillschweigend
als bereits umgesetzt oder als Teil der ersten Lieferung dargestellt.

## Übergreifende Umsetzungskontrolle

### Vertrag

- Properties, Events, Default-Verhalten und Fähigkeiten beider Plattformen
  tabellarisch gegenüberstellen.
- Unterschiede in echte Funktionslücken und notwendige Plattformunterschiede
  einordnen.
- Öffentliche API-Entscheidungen vor Implementierung bestätigen: eigenständige
  Markdown-Anzeige, Link-Callbacks, Diktier-Vertrag und CRDT-Verantwortung.
- Keine zusätzliche Rich-Text-Bearbeitungsart oder neue Token-Achse allein aus
  der Bestandsaufnahme ableiten.

### Bestehende Komponenten

- Native Link-Eingabe durch bestehende K-Komponenten und anpassbare Texte ersetzen.
- Link-Aktivierung auf beiden Plattformen durch den Consumer steuerbar machen.
- Chat-Kopieraktionen, Textauswahl und Typography-Verhalten angleichen.
- Editor-Konfiguration und Diktier-Events entsprechend dem bestätigten Vertrag
  ergänzen; bestehende Integrationen berücksichtigen.
- Falls bestätigt, eine gemeinsame öffentliche Markdown-Anzeige bereitstellen,
  ohne Vorschau- und Chat-Rendering unnötig zu duplizieren.
- Bei CRDT klar zwischen UI-Adapter, Dokumentmodell und Transport unterscheiden;
  Interoperabilität nur nach einem tatsächlichen gemeinsamen Test zusagen.

### Galerien

- Gleiche Fixture-IDs und Beispielinhalte verwenden.
- Desktop, Mobile, Read-only, Vorschau, Bilder/Links, Diktieren und Zusammenarbeit
  auf beiden Plattformen demonstrieren.
- Ein gemeinsames Markdown-Testdokument verwenden: Überschriften, lange Texte,
  verschachtelte Listen, Aufgabenlisten, Zitate, Code, Tabellen und Bilder.
- Consumer-Callbacks und kontrollierte Zustandsänderungen sichtbar demonstrieren.

### Verifikation

- Gleiche Viewports, Themes, Density und Schriftgrößeneinstellungen vergleichen.
- Toolbar-Overflow, Maus-/Touch-Scrollen, Fokus, Tastaturbedienung und mobile
  Bedienflächen prüfen.
- Bearbeitung, Formatierung, Undo/Redo, Suche/Ersetzen, Moduswechsel, Links,
  Bildauflösung und Event-Auslösung testen.
- Lange Tabellen und Codeblöcke auf kleinen Displays prüfen.
- Gemeinsame Dokumentänderungen einschließlich Remote-Auswahlen und Undo-Verhalten
  prüfen, sofern CRDT-Parität Teil des bestätigten Slices ist.
- Gezielte Tests während der Umsetzung; `pnpm verify` vor einem Commit gemäß
  Repository-Regeln. Visuelle Human-Abnahme separat einholen.

## Änderungsgrenzen und Abhängigkeiten

Erwartete Pfade: Editor- und Chat-Komponenten in `packages/web/ui` und
`packages/flutter/k_design_ui`, dazugehörige Tests, Galerie-Fixtures in
`apps/storybook` und `apps/widgetbook` sowie Dokumentation.

Token-Quellen nur ändern, wenn eine konkrete Lücke nachgewiesen und der Umfang
abgestimmt ist; generierte Dateien nicht manuell bearbeiten. Vor UI-Änderungen
den aktuellen Designsystem-Workflow-Skill und Kompositionsvertrag lesen.
Bestehende K-Primitives verwenden. Kein automatischer Bibliothekswechsel und
keine Ausweitung auf andere Komponenten.

## Abnahmekriterien

- Jede vereinbarte Markdown-Fähigkeit ist auf beiden Plattformen verfügbar oder
  eine begründete Ausnahme ist dokumentiert.
- Texte, Bildauflösung und relevante Aktionen bleiben Consumer-gesteuert.
- Properties und Events sind semantisch gleichwertig und getestet.
- Beide Galerien demonstrieren dieselben vereinbarten Szenarien.
- Darstellung und Bedienung sind bei gleichen Einstellungen visuell geprüft.
- CRDT-Readiness wird nicht mit bewiesener CRDT-Interoperabilität gleichgesetzt.

## Quellen im Repository

- `packages/web/ui/src/editors/markdown-editor.tsx`
- `packages/web/ui/src/editors/markdown-preview.tsx`
- `packages/web/ui/src/editors/index.ts`
- `packages/web/ui/src/editors/types.ts`
- `packages/web/ui/src/editors/collaboration.ts`
- `packages/web/ui/src/chat/conversation.tsx`
- `packages/web/ui/markdown-preview.test.mjs`
- `packages/flutter/k_design_ui/lib/src/editors/k_markdown_editor.dart`
- `packages/flutter/k_design_ui/lib/src/editors/k_editor_types.dart`
- `packages/flutter/k_design_ui/lib/src/chat/k_chat_markdown.dart`
- `packages/flutter/k_design_ui/test/editors_test.dart`
- `apps/storybook/src/editors.stories.tsx`
- `apps/storybook/src/editor-fixture.tsx`
- `apps/widgetbook/lib/main.dart`
- `apps/widgetbook/lib/editor_fixtures.dart`
