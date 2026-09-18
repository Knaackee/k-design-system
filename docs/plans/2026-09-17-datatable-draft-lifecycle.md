---
title: "DataTable: kontrollierter Entwurfs-Lifecycle"
date: 2026-09-17
---

# DataTable: kontrollierter Entwurfs-Lifecycle

## Ziel und Status

Entwurf im Regular-Modus. Neue DataTable-Zeilen erhalten auf Web und Flutter einen
klaren, von außen kontrollierbaren Entwurfs-Lifecycle. Noch keine Umsetzung oder
Planfreigabe. Die bestehenden genehmigten Dokumente bleiben unverändert.

## 1. Öffentlichen Lifecycle festlegen

Einen optionalen, wiederverwendbaren Entwurfsvertrag ergänzen: stabile Zeilen-ID,
Default-Snapshot, aktuelle Werte, Startzelle sowie Zustände unverändert, geändert,
speichernd und Speicherfehler. Erfolgreiches Speichern beendet den Entwurf.
Der Konsument kontrolliert den Zustand außerhalb recycelter Zellen.

Konfigurierbar sind Default-Erzeugung, Snapshot/Kopie, fachlicher Wertvergleich,
Startzelle und Speicherstrategie. Lifecycle-Callbacks melden Erzeugen, Änderungen,
Speicheranforderung, erfolgreichen Abschluss, Abbruch und Fehler mit Zeilen-ID,
Werten und Auslöser. Asynchrone Speicherung muss unterstützt werden; ein Fehler
behält Werte und Entwurf. Veraltete Antworten dürfen neuere Änderungen nicht
überschreiben. Pro Speicheranforderung gibt es genau einen Abschluss.

## 2. Lösch- und Speicherregeln vereinheitlichen

- Fokuswechsel innerhalb einer Zeile oder ihrer Auswahl beendet keinen Entwurf.
- Beim Verlassen darf nur ein unveränderter, neuer, ungespeicherter Entwurf
  automatisch verschwinden. Maßgeblich ist der Wertvergleich, nicht Fokus allein.
- Geänderte Entwürfe bleiben bis zur erfolgreichen Speicherung erhalten.
- Explizites Escape verwirft einen neuen ungespeicherten Entwurf auch nach
  Änderungen. Ein geöffnetes Dropdown verarbeitet Escape zuerst selbst.
- Bestehende beziehungsweise gespeicherte Zeilen werden dadurch niemals gelöscht.
- Während einer laufenden Speicherung kein zweiter Save und kein lokales
  Verwerfen, das einen bereits erfolgreichen Server-Save verschleiern könnte.

Vorschlag zur Bestätigung: Demo und Standard verwenden explizites Speichern per
Enter außerhalb geöffneter Auswahlen. Alternativ kann der Konsument Speichern beim
Verlassen der Zeile aktivieren. Validierung und erfolgreiche Speicherbestätigung
liegen immer beim Konsumenten. Diese Demo-Entscheidung ist vor Umsetzung offen.

## 3. Darstellung und Integration stabilisieren

Neue Entwürfe bleiben bis zur Bestätigung an ihrem Erzeugungsort, auch wenn ein
Dropdown den Gruppierungswert verändert. Erst anschließend gelten neue Gruppe,
Sortierung und Filter. Bei externen Datenfenstern bleiben serverseitige Daten
unverändert; lokale Entwürfe werden separat am Erzeugungsort dargestellt.

Zellinhalt und Beschriftungen bleiben frei komponierbar. Fokus, Popups und modale
Picker benötigen explizite Zuordnung zum Entwurf; Popup-Schließen allein ist kein
Zeilenabbruch. Gruppenwechsel, Einklappen und Recycling dürfen weder Werte noch
aktive Editoren still verlieren. Beide Galerien zeigen denselben Ablauf und
sichtbare Lifecycle-Rückmeldungen ohne Backend-Abhängigkeit.

## 4. Verifikation und Abnahme

Vor der Implementierung Regressionen für den bisherigen Ablauf ergänzen:
Titel zu Dropdown per Klick/Tab, geänderter Status bei leerem Titel, Popup-Abbruch,
Zeilenwechsel, Escape vor/nach Speicherung, Rückkehr zu Defaults und bestehende
Zeilen. Dazu verzögerter/fehlgeschlagener Save, doppelte Bestätigung, veraltete
Antworten, Filter/Gruppenwechsel, Einklappen und Virtualisierung prüfen.

Gezielte Web-Modell-/Browsertests und Flutter-Widgettests zuerst, abschließend
`pnpm verify` sowie Interaktionstests in Storybook und frisch gebautem Widgetbook.
Visuelle Stichproben bei 375/700/1024 Pixeln, allen Dichten und 100/200 Prozent
Textskalierung. Native Screenreader-/Geräteabdeckung separat ausweisen; keine
Kapazitätsgarantie oder Großdaten-Benchmarks. Danach visuelle Nutzerabnahme.

## Grenzen und Entscheidungen

Erlaubte Pfade: beide UI-Pakete und deren Tests, beide Galerien, passende
Tooling-Tests und Komponentendokumentation. Kein Backend, kein neuer Tabellenmotor,
keine Tokens, keine sonstigen Tabellenfeatures und kein Commit ohne Auftrag.

[ADR 0004](../decisions/0004-virtualized-datatable-engines.md) bleibt Grundlage:
KTable bleibt darstellend, Daten/Persistenz bleiben beim Konsumenten. Der
kontrollierte Lifecycle ergänzt diesen Vertrag. Sollte seine konkrete API davon
abweichen, ist vor Umsetzung ein ergänzender ADR erforderlich.

Fokusbasierte Löschung allein und ausschließlich galerieinterne Sonderlogik
werden verworfen: Beides deckt den wiederverwendbaren Bibliotheksvertrag nicht ab.

Quellen: [MUI Editing Events](https://mui.com/x/react-data-grid/editing/editing-events/)
und [MUI Editing Persistence](https://mui.com/x/react-data-grid/editing/persistence/).
