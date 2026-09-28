---
title: "Dashboard App Shell und Sidebar-App-Icon"
date: 2026-09-28
---

# Dashboard App Shell und Sidebar-App-Icon

## Auftrag und Status

Regular, vom Nutzer am 28.09.2026 gewählt. Entwurf zur Planfreigabe;
noch keine Implementierung oder Human Acceptance dieses Schritts.
Basis: K Design System master b7530d8; Branch codex/dashboard-shell-showcase.
Assetrys begonnene Consumer-Migration bleibt erhalten.

## Zielbild

Ein universeller Showcase unter Showcase / Dashboard App Shell in Storybook
und Widgetbook zeigt Navigation, Breadcrumbs, Dashboard, Detailansicht und
Settings als zusammenhängenden Ablauf. Bestehende öffentliche K-Komponenten
und Tokens werden verwendet. Keine neue monolithische AppShell-API.

## Entscheidungen

- Eingeklappt steht oben genau ein App-Icon als Button zum Ausklappen.
  Kein zusätzlicher Ausklapp-Pfeil und kein konkurrierender Menü-Trigger.
- Ausgeklappt erscheinen App-Identität und der bisherige Einklapp-Pfeil.
  App-Icon wird vom Consumer geliefert, nicht aus einem Browser-Favicon gelesen.
- Der Icon-Button bleibt per Tastatur bedienbar, mit eindeutigem Accessible Name,
  Tooltip und Fokusdarstellung. Nach Zustandswechsel bleibt Fokus nachvollziehbar.
- Web verwendet vorhandenes KSidebarToggle.railContent. Flutter erhält äquivalente
  optionale Inhaltsparameter; ohne Parameter bleibt das bisherige Verhalten erhalten.
  Kein neuer Token und keine zusätzliche Abhängigkeit.
- Settings ersetzt im Showcase die Hauptnavigation durch die bereits vorhandene
  Settings-Navigation. Zurück zur App stellt vorherige Seite und Sidebar-Modus her.
- Settings-Formulare bleiben lokale Demo-Zustände; Speichern zeigt ehrliche lokale
  Rückmeldung. Keine echten Konten, Netzwerkmutationen oder persistierte Zugangsdaten.
- Showcase-Komposition bleibt in den Galerien. Gemeinsame Primitive bleiben in den
  UI-Paketen. Kein Kopieren von Galeriecode nach Assetry.
- Kein separates ADR erforderlich: additive Inhaltsoption und Komposition innerhalb
  der bestehenden Paket-, Token- und Consumer-Grenzen, ohne Architekturwechsel.

## Umsetzung in Reihenfolge

1. Sidebar-Header in den vorhandenen Web-/Flutter-Fixtures auf App-Icon-Expansion
   umstellen; Flutter-Toggle um optionale Inhalte ergänzen. Bestehende Defaults testen.
2. Dashboard-App-Shell-Fixtures mit gleicher Fixture-ID und Demo-Daten hinzufügen:
   Übersicht mit wenigen Kennzahlen, navigierbare Liste/Detailansicht, Breadcrumbs,
   Seitenaktionen und bestehende Settings-Seite mit funktionierendem Rückweg.
3. Desktop: expanded/rail. Mobile: vorhandener Responsive Drawer mit Öffnen,
   Schließen, Escape/Zurück und Fokus-Rückkehr; keine gequetschte Desktop-Sidebar.
4. Bestehende Settings-Fixtures wiederverwenden, minimale Callback-Erweiterung für
   Rücknavigation. Standalone-Galerie bleibt nutzbar. Keine zweite Settings-Implementierung.
5. Beide Galerien prüfen und zur visuellen Abnahme zeigen. Erst danach separat die
   vereinbarte Assetry-Integration des akzeptierten Verhaltens fortsetzen.

## Optionale rechte Detailleiste

Vom Nutzer ergänzt: optionale rechte Sidebar als Inspector zur aktuellen Auswahl.
Desktop mit ausreichend Platz: rechts neben dem Inhalt; schmaler Desktop/Tablet:
vorhandener Drawer; Mobile: vorhandenes Bottom Sheet. Gleicher Detailinhalt und
Auswahlzustand, nur eine aktive Präsentation. Öffnen erfolgt explizit über eine
Details-Aktion; Schließen verwirft weder Auswahl noch lokale Eingaben.
Breitenwechsel erhält Zustand und erzeugt keine doppelten Fokusziele. Overlays
verwenden vorhandene Fokusführung, Accessible Names und Schließen/Zurück-Verhalten.
Showcase zeigt Varianten mit und ohne Inspector sowie mobile Bottom-Sheet-Ansicht.
Fokussierte Tests ergänzen Öffnen/Schließen, Fokus-Rückkehr, Viewportwechsel und
Zustandserhalt. Keine neue Inspector-Primitive, sofern vorhandene K-Komponenten
das Verhalten abdecken; fehlende Verträge vor Implementierung offenlegen.

## Pfade und Umfang

- packages/web/ui/src/navigation/sidebar.tsx nur bei nachgewiesenem Fokus-/Semantikbedarf.
- packages/flutter/k_design_ui/lib/src/navigation/k_sidebar.dart und fokussierte Tests.
- apps/storybook/src/sidebar-fixture.tsx, settings-page-fixture.tsx und neue Shell-Fixtures.
- apps/widgetbook/lib/sidebar_fixtures.dart, settings_page_fixtures.dart, main.dart,
  neue Shell-Fixtures und Tests.
- Dokumentation/Galerie-Indizes für diesen Slice. Keine Assetry-Produktlogik,
  Datenbank, neuen Imports oder Auth-Änderungen. Keine Baseline-Updates zur Fehlerkaschierung.

## Verifikation und Abnahme

- Fokussierte Web-Interaktionschecks und Flutter-Widgettests: App-Icon öffnet,
  Pfeil schließt, keine doppelten Rail-Trigger, Accessible Names, Fokus,
  Breadcrumb-Navigation, Settings-Rückweg und erhaltene Seitenauswahl.
- Viewports 375, 768 und 1280; Light/Dark, kein horizontaler Seitenüberlauf.
- Keine funktionslosen versprochenen Aktionen: Demo-Funktionen bleiben lokal und
  sichtbar als Demo erkennbar; nicht implementierte Funktionen werden nicht angeboten.
- Finales Programm: pnpm verify im Designsystem; Browserprüfung beider Galerien.
  Bekannte Abhängigkeitswarnungen bleiben sichtbar; neue Probleme werden gemeldet.
- Menschliche visuelle Abnahme vor Consumer-Integration. Commit/Push nur mit
  gesonderter gültiger Freigabe für diesen Slice, keine implizite Veröffentlichung.

## Recherche

Mobbin-MCP am 28.09.2026: LangChain zeigt Hauptnavigation links, Breadcrumb-Zeile
oben und darunter Tabs, Filter und Inhalte. Übernommen wird die Gliederung,
nicht die Produktlogik oder das konkrete Branding.
https://mobbin.com/screens/29a07073-8852-4096-9170-884e9b70fe9c

Codebefund: Web-Toggle besitzt expandedContent/railContent. Flutter-Toggle besitzt
bisher nur Labels und feste Pfeil-Icons. Beide Settings-Fixtures sind vorhanden;
Back to app ist bislang nicht mit einer App-Ansicht verbunden.
