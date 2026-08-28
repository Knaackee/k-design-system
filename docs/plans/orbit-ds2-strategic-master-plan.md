# Orbit Design System 2 — Umsetzungsplan

> Greenfield-Monorepo für ein markenfähiges Designsystem  
> Zielplattformen: React/Web und Flutter  
> Umsetzung: kleines Team oder Einzelentwickler mit AI-Unterstützung  
> Status: **Draft — zur Freigabe**  
> Stand: 26. August 2026

---

## 0. Zweck dieses Dokuments

Dieser Plan übersetzt die Produkt- und Architekturziele in kleine, überprüfbare
Arbeitspakete. Er ist so geschrieben, dass auch ein Junior-Entwickler einen
freigegebenen Slice ausführen kann, ohne Architekturentscheidungen selbst
erfinden zu müssen.

Vor der Implementierung gilt:

1. Dieser Draft wird fachlich freigegeben.
2. Die Entscheidungen aus Abschnitt 2 werden als ADRs angelegt.
3. Erst danach wechselt der erste Slice von `pending` auf `in-progress`.

Das bestehende Orbit-Repository bleibt während des Neuaufbaus unverändert als
Referenz und Rückfallmöglichkeit erhalten. Inhalte werden zunächst kopiert oder
neu implementiert, niemals ungeprüft verschoben oder gelöscht.

---

## 1. Zielbild und Grenzen

### 1.1 Ziele

1. Drei bestehende Flutter-Apps und neue React/Web-Oberflächen erhalten eine
   gemeinsame visuelle Sprache.
2. Markenwechsel innerhalb der unterstützten visuellen Achsen erfolgen nur über
   Design-Tokens, nicht über Forks oder Änderungen am Komponentencode.
3. Web und Flutter verwenden denselben plattformneutralen Token- und
   Komponentenvertrag.
4. Komponenten sehen im Rahmen definierter Toleranzen gleich aus und zeigen
   dieselben fachlichen Zustände und Interaktionen.
5. Plattformkonventionen und Accessibility dürfen bewusst abweichen; jede
   Abweichung wird im Komponentenvertrag dokumentiert.
6. Apps dürfen eigene Komponenten ausschließlich aus freigegebenen Tokens,
   Primitives und Recipes bauen.
7. Der gemeinsame Katalog wächst durch nachgewiesenen Bedarf, nicht durch
   spekulative Vollständigkeit.
8. Generierung, Verträge, Accessibility, visuelle Regression und Release-Eignung
   werden automatisiert geprüft.

### 1.2 Präzisierung des White-Label-Versprechens

Tokens steuern Farben, Typografie, Radien, Abstände, Kontrollgrößen, Schatten,
Bewegung und Icongrößen. Tokens ändern keine Informationsarchitektur,
Slot-Reihenfolge oder fachliche Interaktion. Strukturelle Unterschiede werden
über dokumentierte Component Variants oder Recipes modelliert. Eine Marke darf
keine eigenen Änderungen in gemeinsam ausgelieferten Komponenten benötigen.

### 1.3 Nicht-Ziele für V1

- Keine Pixelgleichheit zwischen Browser- und Flutter-Rendering.
- Keine identischen plattformspezifischen APIs um jeden Preis.
- Keine vollständige Migration der 266 Komponenten des alten Katalogs.
- Keine API-Parität für komplexe Data-Grids und Charts; dort gilt visuelle und
  semantische Parität.
- Keine weiteren Plattformen wie React Native oder native iOS-/Android-UIs.
- Kein Figma-first-Prozess. Figma kann später aus dem Codevertrag gespeist
  werden.

---

## 2. Architekturentscheidungen

Diese Entscheidungen gelten nach Freigabe dieses Plans. Jeder spätere Wechsel
benötigt ein ADR. Die ADR-Dateien werden in Slice S0 angelegt und sind danach
gegenüber diesem Plan autoritativ.

| ID | Entscheidung | Konsequenz |
| --- | --- | --- |
| A1 | Ein Monorepo enthält Tokenquellen, Verträge, Generator, Web, Flutter und Galerien. | Vertragsänderung und beide Plattformprojektionen landen atomar in einem Commit. |
| A2 | Der DTCG-Vertrag ist plattformneutral führend. Flutter definiert die strengsten Anforderungen an statische Auflösbarkeit, ist aber nicht die fachliche Quelle. | Web-Fähigkeiten werden nicht künstlich durch Flutter begrenzt. |
| A3 | Web verwendet React, Radix und ausgewählte shadcn/ui-Patterns hinter Orbit-APIs. | Consumer importieren nur Orbit-Packages. |
| A4 | Der Flutter-Unterbau wird erst nach dem S0-Spike festgelegt. `shadcn_ui` ist der bevorzugte Kandidat und wird immer gewrappt. | Eine unreife Fremdbibliothek wird nicht vor dem praktischen Beweis festgeschrieben. |
| A5 | Die visuellen Dimensionen sind `brand`, `colorMode` und `density`. Die Marke ist Build-/Theme-Konfiguration; zur Laufzeit hat eine Marke sechs Kombinationen. | White Label und Laufzeitmodi bleiben getrennt. |
| A6 | Textvergrößerung folgt Browser-Zoom und `MediaQuery.textScaler`. | Accessibility-Skalierung wird nicht durch eine proprietäre Achse ersetzt. |
| A7 | Komponenten verwenden Semantic Tokens. Component-Aliase sind erlaubt, wenn ein belegter komponentenspezifischer Anpassungspunkt existiert. | Kein vorsorglicher Wildwuchs, aber genügend White-Label-Flexibilität. |
| A8 | DTCG-JSON im Repository ist die einzige Tokenquelle. | Generierte CSS-, TypeScript- und Dart-Dateien werden nie von Hand geändert. |
| A9 | Eine gemeinsame Komponente benötigt Bedarf in mindestens zwei Consumern oder eine schriftlich freigegebene strategische Ausnahme. | Web-only-Fähigkeiten bleiben möglich. |
| A10 | Dark und Light werden als gleichwertige Modi entworfen und geprüft; Dark ist ästhetische Ausgangsbasis, Light keine rein rechnerische Ableitung. | Beide Modi erfüllen Kontrast und Hierarchie eigenständig. |
| A11 | Version 0.x verwendet einen synchronisierten Release-Train für Web, Flutter, Tokens und Verträge. | Ein Release-Tag bezeichnet einen gemeinsam geprüften Systemstand. |

---

## 3. Repository-Struktur

```text
orbit-design-system/
├─ tokens/
│  ├─ foundation.tokens.json
│  ├─ semantic.tokens.json
│  ├─ component.tokens.json            # nur belegte optionale Aliase
│  ├─ density.tokens.json
│  └─ brands/
│     ├─ orbit.light.tokens.json
│     ├─ orbit.dark.tokens.json
│     ├─ reference.light.tokens.json
│     └─ reference.dark.tokens.json
├─ contracts/
│  ├─ component.schema.json
│  └─ components/
├─ tooling/
│  ├─ generate.mjs
│  ├─ verify-token-parity.mjs
│  ├─ verify-contracts.mjs
│  ├─ verify-theme-parity.mjs
│  ├─ verify-contrast.mjs
│  ├─ capture-parity.mjs
│  └─ failure-injection/
├─ packages/
│  ├─ web/
│  │  ├─ tokens/                        # @orbit/tokens
│  │  └─ ui/                            # @orbit/ui
│  └─ flutter/
│     ├─ orbit_tokens/
│     └─ orbit_ui/
├─ galleries/
│  ├─ web/                              # Storybook
│  └─ flutter/                          # Widgetbook
├─ fixtures/
│  ├─ parity/                           # identische deterministische Inhalte
│  ├─ web-consumer/
│  └─ flutter-consumer/
├─ evidence/
│  └─ parity/                           # versionierte Abnahmeberichte
├─ dist/
│  └─ tokens.flat.json
├─ docs/
│  ├─ adr/
│  ├─ components/
│  ├─ decisions/
│  └─ slices/
├─ pnpm-workspace.yaml
├─ melos.yaml
└─ package.json
```

### Zuständigkeiten und Kollisionsgrenzen

| Bereich | Darf ändern | Darf nicht nebenläufig geändert werden mit |
| --- | --- | --- |
| `tokens/`, Generator | Token-/Tooling-Slice | Theme-, Generator- oder Tokenänderungen anderer Slices |
| `contracts/` | Contract-Slice oder jeweiliger Component-Slice | anderem Slice derselben Komponente |
| `packages/web/` | Web-Implementierung einer Komponente | zweitem Web-Slice derselben Komponente |
| `packages/flutter/` | Flutter-Implementierung einer Komponente | zweitem Flutter-Slice derselben Komponente |
| Galerien und Fixtures | jeweiliger Component-Slice | Änderungen derselben Fixture-ID |
| `evidence/` | Capture-Prozess oder Abnahme | manuellem Austausch ohne neue Capture-Metadaten |

Ein Component-Slice besitzt seinen Vertrag, beide Implementierungen, Stories,
Use-Cases und Evidenz vollständig. Web und Flutter dürfen intern parallel gebaut
werden, werden aber gemeinsam integriert und abgenommen.

---

## 4. Tokenmodell

### 4.1 Ebenen

```text
Foundation → Semantic → optional Component Alias → Brand Theme
                       ↘ Density-Rollen
```

| Ebene | Zweck | Direkte Verwendung im Komponentencode? |
| --- | --- | --- |
| Foundation | rohe Skalen und technische Ausgangswerte | nein |
| Semantic | plattformneutrale visuelle Rollen | ja |
| Component Alias | belegter komponentenspezifischer Anpassungspunkt | ja |
| Brand Theme | konkrete Markenwerte für Light und Dark | nein, nur Belegung |
| Density | Innenabstände, Gaps und Kontrollgrößen | ja, über semantische Rollen |

### 4.2 Dimensionen

```text
brand       = orbit | reference | später weitere Marken
colorMode   = light | dark
density     = compact | standard | comfortable
textScale   = Betriebssystem bzw. Browser, keine Tokenachse
```

Der Generator erzeugt pro Marke sechs flache Laufzeitsets. Ein zweites Theme
erzeugt ein zweites Theme-Package beziehungsweise eine zweite Konfiguration,
nicht weitere Zustände innerhalb jeder Anwendung.

### 4.3 Startrollen

```text
color.surface.{base,subtle,raised,overlay,inverse}
color.text.{primary,secondary,muted,inverted,accent,onAccent}
color.border.{subtle,default,strong,focus}
color.action.{primary,secondary,danger}.{bg,bgHover,bgPressed,fg,border}
color.status.{danger,warning,success,info}.{bg,fg,border}
color.chart.{1..6}

space.{0,1,2,3,4,5,6,8,10,12}          # stabile Layoutskala
density.control.{sm,md,lg}              # visuelle Kontrollhöhe
density.inset.{sm,md,lg}                # Komponenten-Innenabstand
density.gap.{sm,md,lg}                  # Komponenten-interner Abstand
size.hitTarget.min                       # unabhängig von visueller Höhe
size.icon.{sm,md,lg}

radius.{sm,md,lg,full}
font.family.{sans,mono}
font.size.{1..7}
font.weight.{regular,medium}
font.lineHeight.{tight,normal,relaxed}
font.tracking.{tight,normal}
motion.duration.{fast,base,slow}
motion.easing.{standard,enter,exit}
elevation.{0,1,2}
```

Die globale `space.*`-Skala bleibt über Densities stabil. Nur explizite
`density.*`-Rollen ändern sich. So wird ein Control kompakter, ohne ungewollt das
Seitenlayout und responsive Umbrüche zu verändern.

### 4.4 Generatorregeln

1. Alle Referenzen sind zur Build-Zeit auflösbar.
2. Zyklen, unbekannte Referenzen und fehlende `$type`-Angaben brechen den Build.
3. Jede Marke und jeder Farbmodus belegen denselben Pflichtrollensatz.
4. Component-Aliase benötigen eine Begründung im zugehörigen Vertrag.
5. Farbquellen werden in OKLCH gepflegt; Gamut-Mapping und sRGB-Konvertierung
   sind deterministisch im Generator implementiert.
6. CSS und Dart werden nicht als Text verglichen. Beide werden auf die
   kanonische flache Repräsentation normalisiert; Farben nutzen eine
   dokumentierte numerische Toleranz.
7. Generierte Dateien enthalten Generatorversion und Quell-Hash.

### 4.5 Generatorausgaben

**Web:** `tokens.css`, Tailwind-v4-`theme.css`, kontrollierter
`shadcn-compat.css`-Alias-Layer und typisierte `tokens.ts`.

**Flutter:** `orbit_tokens.g.dart`, `orbit_theme.g.dart` und sechs
Theme-Konfigurationen je Marke.

**Gemeinsam:** `tokens.flat.json` als kanonische Prüfrepräsentation und
`token-manifest.json` mit Rollen, Typen, Herkunft und Deprecations.

---

## 5. Komponentenvertrag

Jede gemeinsame Komponente besitzt genau einen maschinenlesbaren Vertrag. Er
beschreibt gemeinsame Semantik und ordnet plattformspezifische APIs zu, statt
identische Prop-Namen zu erzwingen.

```json
{
  "name": "Button",
  "since": "0.1.0",
  "parity": "contract-and-visual",
  "variants": {
    "variant": ["primary", "secondary", "ghost", "danger"],
    "size": ["sm", "md", "lg"]
  },
  "states": [
    "default",
    "hover",
    "pressed",
    "focusVisible",
    "disabled",
    "loading"
  ],
  "slots": ["leadingIcon", "label", "trailingIcon"],
  "behavior": {
    "activate": "invokes-once",
    "loading": "blocks-activation",
    "disabled": "not-activatable"
  },
  "a11y": {
    "role": "button",
    "focusVisible": true,
    "minHitTarget": "size.hitTarget.min"
  },
  "tokensUsed": [
    "color.action.primary.bg",
    "color.action.primary.fg",
    "density.control.md",
    "density.inset.md",
    "radius.md"
  ],
  "platforms": {
    "web": { "status": "supported", "apiSnapshot": "Button.web.json" },
    "flutter": { "status": "supported", "apiSnapshot": "Button.flutter.json" }
  },
  "fixtures": ["button-primary", "button-states", "button-long-label"]
}
```

Der Contract-Prüfer validiert Varianten, Zustände, Slots, Verhalten,
Plattformzuordnungen, Tokenverwendung, Fixture-Abdeckung, dokumentierte
`not-applicable`-Abweichungen und API-Snapshots gegen das jeweilige Mapping.

---

## 6. Paritäts- und Abnahmemodell

### 6.1 Was „gleich“ bedeutet

Eine Komponente gilt als paritätisch, wenn:

1. Inhalt, Varianten und fachliche Zustände übereinstimmen.
2. Hierarchie, Farben, Abstände, Radien und Größen visuell äquivalent sind.
3. Aktivierung, Disabled-, Loading-, Fehler- und Auswahlverhalten gleich sind.
4. Tastatur, Maus, Touch und Screenreader gemäß Plattformkonvention funktionieren.
5. Jede bewusste Abweichung im Vertrag und Abnahmebericht steht.

Unterschiede durch Font-Rasterung, Antialiasing, native Cursor oder
plattformtypische Fokusdarstellung sind zulässig, wenn Semantik und
Designabsicht erhalten bleiben.

### 6.2 Drei Prüfebenen

#### Ebene A — deterministische Regression pro Plattform

- Storybook rendert Web-Fixtures in Chromium.
- Widgetbook rendert dieselben Fixture-IDs in einem festgelegten Emulator.
- Beide erzeugen eigene Golden-/Screenshot-Baselines.
- Abweichungen zur jeweiligen Plattformbaseline brechen CI.

#### Ebene B — Cross-Platform-Paritätsbericht

`capture-parity.mjs` erzeugt je Fixture:

- Web- und Flutter-Screenshot,
- normalisierte Ausschnitte mit gleicher Canvasgröße,
- Side-by-side-Ansicht und halbtransparentes Overlay,
- Metadaten zu Theme, Density, Viewport, Browser, Emulator und Commit.

Automatisch verglichen werden nicht-textuelle Geometrie, Tokenfarben und
Schlüsselmaße. Direkte Pixel-Diffs über Rendering-Engines dienen als Hinweis,
nicht als alleiniges Gate.

Die Toleranzen werden in S0 anhand von drei Spike-Komponenten kalibriert und in
einem ADR fixiert. Vorgeschlagener Ausgangspunkt:

- Kontroll- und Außenmaße: maximal 2 px oder 3 %, der größere Wert gilt.
- Abstände und Radien: maximal 2 px.
- Tokenfarben: identischer Token und Ausgabefarbe innerhalb der dokumentierten
  Konvertierungstoleranz.
- Textumbruch: gleiche Zeilenzahl bei identischem Fixture und Canvas, außer
  dokumentierter Plattformabweichung.

#### Ebene C — menschliche visuelle und interaktive Abnahme

Vor Freigabe prüft ein Reviewer:

- Storybook im Browser in Light/Dark und mindestens Standard/Compact,
- Widgetbook im Emulator mit denselben Fixtures,
- Hover, Fokus und Tastatur im Browser,
- Touch, Text Scaling und Navigation im Emulator,
- Side-by-side- und Overlay-Bericht.

Die Abnahme endet mit `accepted`, `accepted-with-deviation` oder `rejected`.
Eine Abweichung benötigt Begründung, Plattform und Screenshotverweis.

### 6.3 Feste Capture-Umgebung

S1 pinnt Chromium-Version, Web-Viewport, CI-Image, Flutter-/Dart-Version,
Emulatorgerät, Betriebssystem, Auflösung, Device Pixel Ratio, Schriftdateien,
Locale und Screenshot-Namensschema. Animationen, Uhrzeit und Testdaten sind
deterministisch. Ohne passende Capture-Metadaten wird keine Baseline erneuert.

### 6.4 Interaktionsmatrix

| Fähigkeit | Web | Flutter |
| --- | --- | --- |
| Aktivierung | Klick, Enter, Space | Tap, Keyboard wenn unterstützt |
| Fokus | Tab-Reihenfolge, `focus-visible` | Focus Traversal, sichtbarer Fokus |
| Pointerzustände | Hover, Pressed | Hover auf Desktop, Pressed/Touch |
| Disabled | nicht aktivierbar, korrekte Semantik | nicht aktivierbar, korrekte Semantik |
| Loading | keine Doppelaktivierung | keine Doppelaktivierung |
| Text Scale | Browser-Zoom 200 % | festgelegte System-Textskalierung |
| RTL | `dir=rtl` | `Directionality.rtl` |
| Screenreader | Name und Rolle | Semantics-Label und Rolle |

---

## 7. Kernset und Beförderungsregel

### 7.1 Inventar vor Festlegung

S0 scannt die drei Flutter-Apps und geplante Web-Consumer. Erfasst werden
verwendetes Widget/Pattern, Consumeranzahl, Varianten, Zustände,
Accessibility-Anforderungen, Fremdbibliothek und Migrationsaufwand. Die
Startliste ist eine Hypothese, kein bereits freigegebener Katalog.

### 7.2 Vorgeschlagene Startliste

**Primitives:** Text, Icon, Surface, Stack, Inline, Divider  
**Actions:** Button, IconButton, Badge  
**Forms:** Field, Input, Textarea, Checkbox, Switch, RadioGroup, Select, Slider  
**Overlays:** Dialog, Sheet, Popover, Tooltip, DropdownMenu  
**Feedback:** Toast, Spinner, Skeleton, EmptyState  
**Navigation:** Tabs, Breadcrumb  
**Identity:** Avatar

### 7.3 Beförderung

Eine App-Komponente wandert in das System, wenn sie in mindestens zwei
Consumern benötigt wird oder eine strategische Ausnahme freigegeben wurde und
Vertrag, Plattformstatus sowie Wartungsverantwortung geklärt sind.
`not-applicable` ist erlaubt; zufälliges Fehlen einer Implementierung nicht.

---

## 8. Qualitätsgates

### 8.1 Schnelle Gates bei jedem Push

| Gate | Bricht bei |
| --- | --- |
| Format/Lint | Format-, Import- oder Literalverstoß |
| Typecheck/Analyze | TypeScript- oder Dart-Fehler |
| Unit/Widget Tests | fachlicher Verhaltensfehler |
| `generate:check` | Drift zwischen Quelle und generierter Ausgabe |
| Token-Parität | fehlender Schlüssel, Typ- oder normalisierter Wertfehler |
| Contract-Prüfung | fehlende Variante, Fixture, Plattformzuordnung oder API-Abdeckung |
| Theme-Parität | Marke oder Farbmodus belegt Pflichtrollen nicht vollständig |
| Theme-Divergenz | Reference Theme unterscheidet sich nicht nachweisbar von Orbit |
| Literal-Lint | unzulässiger Designwert oder direkter Fremdbibliotheksimport |
| Kontrast | semantische Farbpaarung verletzt die WCAG-Anforderung |

Literal-Lint verwendet eine Allowlist für technische Konstanten wie `0`,
Proportionen und mathematische Faktoren. Er verbietet nicht jede Zahl, sondern
nicht semantisch begründete Designwerte.

### 8.2 Vollständige Gates bei Pull Requests

- Storybook Interaction Tests und axe.
- Web-VRT für betroffene Fixtures über Light/Dark × drei Densities.
- Flutter Widget Tests und Goldens über dieselbe Matrix.
- Consumer-Fixtures für npm und Flutter.
- Bundle-/Package-Budget.
- Cross-Platform-Paritätsbericht für betroffene Komponenten.

### 8.3 Release-Gates

- vollständiger Kataloglauf in Browser und Emulator,
- Failure-Injection-Suite,
- manuelle Stichprobe der Cross-Platform-Berichte,
- Changelog und Migration Notes,
- Installation der Artefakte in beide Consumer-Fixtures,
- reproduzierbarer Build aus sauberem Checkout.

Failure Injection speist absichtlich defekte Tokens, Verträge, Literale und
Baselines ein. Das Gate ist grün, wenn jeder Defekt zuverlässig abgelehnt wird.

---

## 9. Junior-tauglicher Component-Workflow

Ein Auftrag umfasst genau eine Komponente oder einen klar abgegrenzten
Token-/Tooling-Slice.

### 9.1 Erforderliche Auftragseingaben

- Component-ID und verantwortlicher Reviewer,
- freigegebener Vertrag oder konkreter Contract-Änderungsauftrag,
- Varianten und Zustände,
- Fixture-IDs,
- erlaubte Tokenrollen,
- Referenzpattern,
- explizite Nicht-Ziele,
- auszuführende Kommandos.

Fehlt eine Angabe, beginnt die Implementierung nicht.

### 9.2 Ausführungsschritte

1. Eigenen Branch `codex/component-<name>` oder `feature/component-<name>` vom
   grünen Hauptbranch anlegen.
2. Vertrag lesen und Contract-Schema prüfen.
3. Deterministische Fixtures ohne zufällige Daten oder Netzwerkbilder anlegen.
4. Web-Komponente nur mit Orbit-Tokens und freigegebenen Wrappern implementieren.
5. Flutter-Komponente nach demselben Vertrag implementieren.
6. Storybook-Stories und Widgetbook-Use-Cases mit identischen Fixture-IDs bauen.
7. Unit-, Interaction-, Accessibility- und Widget-Tests ergänzen.
8. Lokale schnelle Gates ausführen.
9. Plattformbaselines und Cross-Platform-Bericht erzeugen.
10. Abweichungen dokumentieren; Baselines nie nur aktualisieren, damit CI grün wird.
11. Pull Request mit Checkliste und Evidenz öffnen.
12. Erst nach Review und visueller Abnahme mergen.

### 9.3 Definition of Done

- Vertrag validiert.
- Web- und Flutter-Status erfüllt oder `not-applicable` begründet.
- Varianten, Zustände und Interaktionen geprüft.
- Keine unzulässigen Literalwerte oder direkten Fremdbibliotheksimporte.
- Storybook und Widgetbook enthalten dieselben relevanten Fixtures.
- VRT und Goldens sind grün.
- Paritätsbericht wurde akzeptiert.
- Consumer-Fixtures bauen.
- Dokumentation enthält Nutzung, Accessibility und bekannte Abweichungen.

### 9.4 Sofort eskalieren statt improvisieren

Ein Junior stoppt und markiert den Slice `blocked`, wenn ein Token fehlt,
Vertrag und gewünschtes Verhalten widersprüchlich sind, eine Plattform das
Verhalten nicht sinnvoll abbildet, ein Fremdpaket direkt importiert werden
müsste, die Abweichung außerhalb der Toleranz liegt oder öffentliches API
außerhalb des Auftrags geändert werden müsste.

---

## 10. Umsetzungsphasen

Jede Phase endet mit einem sicheren Git-Checkpoint: einem grünen Commit auf dem
Hauptbranch mit der genannten Evidenz. Status aller Phasen in diesem Draft:
`pending`.

### S0 — Entscheidungen, Inventar und Spike

**Outcome:** Belegter Kernumfang, validierter Flutter-Unterbau und kalibrierte
Paritätsregeln.  
**Owner-Grenze:** nur `docs/`, Spike-Verzeichnisse und Inventarskripte; keine
Produktionspackages.  
**Abhängigkeit:** Freigabe dieses Plans.

Aufgaben:

1. ADRs A1–A11 anlegen.
2. Flutter-Apps und Web-Consumer inventarisieren.
3. Button, Input und Dialog als Wegwerf-Spike in Web und Flutter bauen.
4. `shadcn_ui` gegen mindestens eine Alternative oder Eigenwrapper bewerten.
5. Fixtures in Storybook und Widgetbook darstellen.
6. Browser- und Emulator-Screenshots erzeugen.
7. Geometrie-, Farb- und Texttoleranzen kalibrieren.
8. Kernset und Fremdbibliotheksentscheidung freigeben.

**Verification:** Spike baut; drei Komponenten sind in Browser und Emulator
bedienbar; Paritätsbericht und Entscheidungsprotokoll vorhanden.  
**Evidence:** Inventar, ADRs, Screenshots, Spike-Bericht.  
**Checkpoint:** `plan: ratify architecture and parity baseline`.

### S1 — Repository-Skelett und reproduzierbare CI

**Outcome:** Leere installierbare Packages und gepinnte Capture-Umgebung.  
**Owner-Grenze:** Root-Konfiguration, leere Packages, Galerien,
Consumer-Fixtures und CI.  
**Abhängigkeit:** S0.

Aufgaben: pnpm und Melos konfigurieren; Packages und Consumer-Fixtures anlegen;
Storybook und Widgetbook headless bauen; Browser und Emulator pinnen; Push-, PR-
und Release-Workflows trennen; 0.x-Release-Train und Changelog einrichten.

**Verification:** sauberer Checkout installiert und baut beide Toolchains;
Galerien und Consumer starten; CI grün.  
**Evidence:** CI-Run, Capture-Metadaten, Installationsprotokoll.  
**Checkpoint:** `build: establish web and flutter workspace baseline`.

### S2 — Tokenvertrag und Generator

**Outcome:** Orbit und Reference werden aus einer DTCG-Quelle für Web und Flutter
generiert.  
**Owner-Grenze:** `tokens/`, Generator und Token-Packages.  
**Abhängigkeit:** S1.

Aufgaben: DTCG-Schema und Rollen implementieren; Dimensionen getrennt
modellieren; CSS, TypeScript, Dart und Manifeste generieren; Normalisierung,
Gamut-Mapping, Kontrast und Parität prüfen; Reference Theme und Failure
Injections ergänzen.

**Verification:** Drift, fehlende Rolle, Referenzzyklus, Kontrastfehler und
identische Themes werden abgelehnt.  
**Evidence:** Flat Tokens, Manifeste, Prüfausgaben, Failure-Injection-Run.  
**Checkpoint:** `feat(tokens): generate parity-checked multi-brand outputs`.

### S3 — Komponentenverträge und Paritätsharness

**Outcome:** Ein Vertrag kann beide Plattformen und gemeinsame Fixtures prüfen.  
**Owner-Grenze:** `contracts/`, API-Snapshot-Tools und Capture-Harness.  
**Abhängigkeit:** S2.

Aufgaben: Contract-Schema und Plattform-Mappings definieren; API-Snapshots
erzeugen; Fixture-Manifeste abgleichen; Screenshots normalisieren; Side-by-side,
Overlay und Abnahmebericht bauen; Failure Injections ergänzen.

**Verification:** fehlende Variante, Fixture, Plattformzuordnung und API werden
abgelehnt; Spike-Fixtures erzeugen reproduzierbare Berichte.  
**Evidence:** Schema, Snapshots, drei Paritätsberichte.  
**Checkpoint:** `feat(contracts): verify component and visual parity`.

### S4 — Vertikaler Basisslice mit fünf Komponenten

**Outcome:** Text, Surface, Button, Input und Dialog sind beidseitig
produktionsnah nutzbar.  
**Owner-Grenze:** Verträge und Implementierungen genau dieser fünf Komponenten.  
**Abhängigkeit:** S3.

Reihenfolge: Text → Surface → Button → Input → Dialog. Jede Komponente erhält
einen eigenen PR nach Abschnitt 9.

**Verification:** alle Gates grün; Browser-/Emulator-Abnahme über beide
Farbmodi und drei Densities; Browserzoom und Flutter-Textskalierung geprüft.  
**Evidence:** fünf akzeptierte Paritätsberichte, Galerien, Consumer-Beispiele.  
**Checkpoint:** `feat(ui): complete cross-platform foundation set`.

**Entscheidungstor:** Ist Parität nicht akzeptabel, werden Vertrag, Unterbau oder
Versprechen geändert. Weitere Komponenten beginnen vorher nicht.

### S5 — Kernset in kleinen Component-Slices

**Outcome:** Das durch S0 belegte Kernset ist beidseitig verfügbar.  
**Owner-Grenze:** ein PR pro Komponente; höchstens zwei parallele Components ohne
gemeinsame Token- oder Primitive-Änderung.  
**Abhängigkeit:** akzeptiertes S4-Entscheidungstor.

Reihenfolge: Primitives und Actions → einfache Forms → Feedback → Navigation →
Overlays und komplexe Forms. Fehlende gemeinsame Tokens sind ein eigener
vorgelagerter Token-Slice.

**Verification:** Definition of Done pro Komponente; vollständige Matrix im
Release-Workflow.  
**Evidence:** Bericht pro Komponente, Katalogübersicht, Contract-Coverage.  
**Checkpoint:** `feat(ui): complete evidence-backed core catalog`.

### S6 — Pilotmigration einer Flutter-App und eines Web-Consumers

**Outcome:** Das System bewährt sich außerhalb der Galerien.  
**Owner-Grenze:** Pilotanwendungen plus ausschließlich belegte Ergänzungen.  
**Abhängigkeit:** S5.

Aufgaben: repräsentativen Ablauf je Plattform migrieren; Literal-Lints zunächst
warnend, dann blockierend aktivieren; Orbit gegen Reference austauschen; fehlende
Components nur über die Beförderungsregel aufnehmen.

**Verification:** Consumer ohne unzulässige Designliterale; Markenwechsel ändert
die gesamte Appearance; Interaktionen funktionieren im Browser und Emulator.  
**Evidence:** Vorher-/Nachher-Bericht, Screenshots, Migrationsnotizen.  
**Checkpoint:** `feat(pilot): validate token-only theming in real consumers`.

### S7 — Web/Flutter V1 Release Candidate

**Outcome:** Reproduzierbarer, dokumentierter und installierbarer V1-Kandidat.  
**Owner-Grenze:** Release-Metadaten und Dokumentation, keine neuen Komponenten.  
**Abhängigkeit:** S6.

Aufgaben: Release-Gates ausführen; APIs und Manifest einfrieren; Installation,
Theming, Migration und Contribution dokumentieren; Changelog und akzeptierte
Abweichungen veröffentlichen; Artefakte aus einem Tag in Consumer-Fixtures
installieren.

**Verification:** sauberer Checkout reproduziert Artefakte und Evidenz; alle
Gates grün; Release-Abnahme akzeptiert.  
**Evidence:** Release-Report, Artefakt-Hashes, Paritätsindex.  
**Checkpoint:** `release: orbit design system 0.1.0`.

### S8 — Weitere Apps und bedarfsgesteuerte Erweiterung

**Outcome:** Apps 2 und 3 migrieren ohne unkontrolliertes Wachstum.  
**Owner-Grenze:** eine App plus separat freigegebene Components.  
**Abhängigkeit:** S7.

DataTable, Charts und Drag-and-Drop beginnen erst bei belegtem Bedarf und
erhalten eigene Pläne. Ihr Vertrag darf `visual-only` oder
`platform-specific-api` festlegen.

**Verification:** Apps 2 und 3 verwenden veröffentlichte Packages; jede neue
gemeinsame Komponente erfüllt die Definition of Done und besitzt einen
nachgewiesenen Consumerbedarf.  
**Evidence:** Migrationsberichte, aktualisiertes Consumerinventar und akzeptierte
Paritätsberichte aller neu aufgenommenen Komponenten.  
**Checkpoint:** `feat(adoption): complete multi-app design-system rollout`.

---

## 11. Git- und Reviewregeln

- Hauptbranch ist jederzeit grün und releasefähig.
- Branches beginnen standardmäßig mit `codex/`, `feature/`, `fix/` oder `tooling/`.
- Ein PR enthält einen Slice oder eine Komponente.
- Öffentliche APIs, Tokenrollen und Contract-Schema benötigen Maintainer-Review.
- Generierte Dateien werden nur zusammen mit ihren Quellen committed.
- Baseline-Updates benötigen Vorher-/Nachher-Evidenz und Freigabe.
- `accepted-with-deviation` benötigt eine Verlinkung in Vertrag und Release-Report.
- Nach jedem Phasencheckpoint wird der Planstatus aktualisiert.

---

## 12. Risiken und Stop-Regeln

| Risiko | Gegenmaßnahme / Stop-Regel |
| --- | --- |
| Flutter-Library instabil oder schlecht themebar | S0-Spike; keine Festlegung vor Beweis; Wrapper bleibt zwingend. |
| Cross-Renderer-Diffs erzeugen Rauschen | Plattformbaselines sind harte Gates; Cross-Platform-Pixeldiff ist Evidenz, Geometrie und Verträge sind verbindlich. |
| Katalog wächst unkontrolliert | Zwei-Consumer-Regel oder dokumentierte Ausnahme. |
| Density verändert Layout | Nur `density.*` ändert sich; Layoutabstände bleiben stabil. |
| White Label benötigt Komponentenänderung | Semantic/Component Alias prüfen; Struktur als Recipe. |
| Junior muss Architektur erfinden | Slice stoppen; fehlende Entscheidung eskalieren. |
| CI wird zu langsam | schnelle Push-Gates, betroffene Matrix auf PR, vollständige Matrix beim Release. |
| Web oder Flutter bleibt ungenutzt | Track bewusst pausieren, nicht halb pflegen. |
| Bestehendes Wissen geht verloren | Altes Repository read-only erhalten und Übernahmen dokumentieren. |

---

## 13. Übernahme aus dem bestehenden Orbit-System

Selektiv übernehmen:

- DTCG-Tokenquellen als Ausgangsmaterial,
- bewährte Generator- und Theme-Prüfideen,
- Komponentenverträge und Accessibility-Erkenntnisse,
- Storybook-Stories als Referenzfundus,
- Review-Feedback, Zustandsmatrizen und gelöste Interaktionsfälle,
- ausgewählte Implementierungen nach neuer Contract- und Literal-Prüfung.

Nicht automatisch übernehmen:

- alle 266 Komponenten,
- Component Tokens ohne nachgewiesenen Bedarf,
- vier globale Laufzeitachsen,
- Vergleichskatalog und Dispositionsdokumente als Produktumfang,
- technische Schulden oder APIs nur aus Gründen der Rückwärtskompatibilität.

Das alte System ist Wissensquelle, kein Migrations-Backlog.

---

## 14. Zeitrahmen

Nach S0 wird anhand des echten Inventars neu geschätzt. Vorläufig für eine Person
mit AI-Unterstützung:

| Bereich | Erwartung |
| --- | --- |
| S0–S3: Beweis, Skelett, Tokens, Verträge und Harness | 5–7 Wochen |
| S4: fünf vertikale Basiskomponenten | 2–3 Wochen |
| S5: belegtes Kernset | 5–7 Wochen |
| S6: zwei Pilot-Consumer | 3–4 Wochen |
| S7: Release Candidate | 1–2 Wochen |

Gesamt bis zum belastbaren V1-Kandidaten: **16–23 Wochen**. Browser-/Emulator-
Parität, Accessibility und Pilotmigrationen sind explizite Liefergegenstände.

---

## 15. Freigabe

Dieser Plan ist `draft`. Vor S0 wird eine Entscheidung dokumentiert:

- **Accept:** Architektur, Paritätsmodell, Phasen und Grenzen sind freigegeben.
- **Revise:** benannte Abschnitte werden erneut bearbeitet.

Eine Freigabe startet noch keine Implementierung. Nach `Accept` wird der Plan auf
`approved` gesetzt, der Git-Checkpoint dokumentiert und S0 kann mit einem
expliziten Startauftrag beginnen.
