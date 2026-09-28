# Dashboard App Shell — Umsetzung und Änderungsnachweis

Stand: 2026-09-28. Regular, Umsetzung läuft; noch keine menschliche Abnahme.

## Freigegebene Präzisierung

Der freigegebene Plan `docs/plans/2026-09-28-dashboard-shell-showcase.md`
bleibt unverändert (SHA256
`23fc3896113e11f65cd427e8d6cbfb40a946fd5893cf2525656d7f5c2a388a11`).
Der Nutzer hatte zunächst beide Sidebars als Floating-Overlays gewünscht und
für links einen festen 56-Pixel-Platz bestätigt. Anschließend korrigierte er:

> Ich muss mich korrigieren, die linke Sidebar darf gerne wieder den Content verschieben, aber die rechte Sidebar sollte als Overlay bestehen bleiben.

Diese letzte Entscheidung gilt: Links beansprucht die Sidebar je nach Zustand
56 oder 248 Pixel und verschiebt den Hauptinhalt. Rechts wird immer ein Overlay
verwendet, mobil ein Bottom Sheet. Nur das Öffnen und Schließen der rechten
Detailleiste darf die Hauptinhaltsgeometrie nicht verändern.

Zusätzliche API-Freigabe: Beim Browservergleich wurde festgestellt, dass
Flutter-Drawer den äußersten Widgetbook-Navigator verwenden und damit die
Galerie statt nur die App-Vorschau überdecken. Der Nutzer genehmigte auf die
konkrete Rückfrage zur optionalen Navigator-Auswahl:

> Ja, sauber im Designsystem ergänzen (empfohlen)

Die bestehenden Standardaufrufe behalten ihr bisheriges Routing. Die App-Shell
verwendet einen eigenen Navigator und die explizite lokale Auswahl. Diese
Erweiterung wird mit Regressionstests für Routing und Responsive-Verhalten
geprüft. Web benötigt keine neue API: Das Storybook-Iframe bildet bereits
einen eigenen Dokument-/Overlay-Bereich.

Zusätzliche Interaktionsvorgabe des Nutzers:

> Ein Klick eines Items in der linken Sidebar sollte dann aber nicht die Sidebar wieder schließen automatisch. Nur noch der User schließt sie.

Der eingestellte Sidebar-Modus bleibt bei Menüauswahl, Breadcrumb-Navigation
und beim Settings-Rückweg erhalten. Nur der Toggle ändert den Modus. Auch der
mobile Navigations-Drawer bleibt nach einer Auswahl offen und wird ausdrücklich
über Schließen, Zurück/Escape oder den Hintergrund geschlossen.

## Umsetzung

- Bestehende K-Komponenten, öffentliche APIs und semantische Tokens werden
  wiederverwendet; keine neuen Abhängigkeiten.
- Sidebar-App-Icon als Rail-Toggle; Pfeil zum Einklappen. Flutter erhält dieselben
  optionalen Toggle-Inhalte wie Web; bestehende Standardpfeile bleiben erhalten.
- Dashboard, Projekte, Projektdetail und bestehende Settings-Seite in beiden
  Galerien. Demo-Zustand bleibt lokal; keine Assetry-Daten werden verändert.
- Notizen werden pro Projekt gehalten und über Responsive-Wechsel erhalten.
- Flutter SidebarBody besitzt seinen ScrollController, damit Drawer-Nutzung
  keinen fehlenden oder mehrfach gebundenen PrimaryScrollController erzeugt.

## Prüfung

- Letzter vollständiger Prüfstand vor der mobilen Nachbesserung: `pnpm verify`
  erfolgreich; Protokoll `tmp/dashboard-shell-final-verify.log` im Host.
- Aktuelle Änderung auf ausdrücklichen Nutzerwunsch: Mobile Menüauswahl schließt
  den linken Drawer; Desktop-Navigation behält ihren Modus. Das ersetzt die
  zuvor gewünschte Regel, auch mobil geöffnet zu bleiben.
- Web: Shell auf `100dvh` begrenzt, Hauptinhalt scrollt unabhängig von Sidebar
  und Header. Linker Drawer 248 px breit, Footer am unteren Viewportrand.
- Web und Flutter verwenden oben den vorhandenen `KThemeSwitcher` für Light,
  Dark und System. Das Theme gilt auch für Overlays.
- Aktuell bestanden: Storybook-Typecheck und zwölf Flutter-Shell-Tests. Darunter
  mobiles Schließen, Desktop-Modus, Theme im Inspector, Viewportwechsel,
  Projektnotizen und eingebettete Navigator-Grenzen.
- Codex-Browser: Web und Flutter schließen nach Projects-Auswahl; Web-Dark-Drawer
  übernimmt das Theme, Footer-Unterkante 844 px bei 845 px Viewporthöhe.
- Flutter-Drawer-Geometrie bleibt offen: Vorhandene API erzwingt Scroll-Body;
  Breite, Innenabstand und optional nicht scrollender Body zur Freigabe angefragt.
  Kein unbelegter plattformübergreifender Fertigstatus.
- Neuer Gesamtcheck scheiterte zunächst ausschließlich an der Formatierung
  dieses Änderungsnachweises; anschließend wird derselbe Check wiederholt.
- Web-Regression als `apps/storybook/src/dashboard-shell-browser.test.mjs`
  hinterlegt; Interaktionen über Codex-Browser statt separatem Browser ausgeführt.
- Keine native iOS-/Android-Hardwareprüfung oder automatische Pixelbilddifferenz.
  Menschliche visuelle Abnahme steht aus. Bestehende Buildwarnungen unverändert.

Abschließender Gesamtcheck: pnpm verify erfolgreich (Exit 0), einschließlich
aller Tests sowie Storybook- und Widgetbook-Releasebuilds. Protokoll im Host:
tmp/dashboard-shell-mobile-theme-verify.log. Die API-Freigabe für die verbleibende
Flutter-Drawer-Geometrie ist weiterhin offen.

Logo-Nachbesserung: Web und Flutter zeigen im mobilen Drawer direkt Orbit-Logo
und Namen neben dem Schließen-Button; der doppelte Sidebar-Kopf entfällt.
Codex-Browser: Mobil, Desktop ausgeklappt und Icon-Leiste in beiden Galerien
geprüft. Storybook-Typecheck und zwölf Flutter-Shell-Tests bestanden. Der letzte
Gesamtcheck bleibt der oben dokumentierte Stand vor dieser lokalen Kopfänderung.
Die zuvor angefragte Flutter-Drawer-Geometrie bleibt offen.

Web-Footer-Korrektur: KSidebar ordnet Header, Body und Footer explizit den
Grid-Zeilen 1, 2 und 3 zu. Ohne Header hatte der Footer zuvor die wachsende
zweite Zeile belegt; seine Unterkante allein war daher kein ausreichender Test.
Regression prüft jetzt die Position des Settings-Buttons. Das X wird nur im
linken Showcase-Drawer ausgeblendet; Escape und Backdrop bleiben aktiv.
Codex-Screenshot bestätigt Settings unten und fehlendes X. Typecheck, Format
und Testskript-Syntax bestanden. Flutter-API-Erweiterung weiterhin nicht freigegeben.

Flutter-Parität nach Nutzerauftrag: Die Aufforderung, die geöffnete Widgetbook-
Ansicht wie die bereits korrekte Webversion zu korrigieren, wurde als Freigabe
der zuvor angefragten Drawer-Erweiterung umgesetzt. KResponsiveDrawer besitzt
optionale Side-Drawer-Parameter sideWidth, sideContentInset, sideScrollable und
sideShowCloseButton. Bestehende Aufrufe und Bottom-Sheet-Layouts behalten ihre
Standardwerte. Die Navigation nutzt 248 px, volle Resthöhe ohne äußeren Scroll-
Body, keinen Innenabstand und kein X. Menüauswahl und Backdrop schließen weiterhin.
KSidebarBody und Footer verwenden die gleichen Abstände wie Web; Footer mit
Trennlinie. Die 400-px-Begrenzung wurde entfernt. 21 gezielte Flutter-Tests grün,
inklusive 248-px-Breite, Settings-Position und fehlendem X; Gesamtcheck läuft.

## Nächster Schritt

Die Flutter-Drawer-Anpassung ist umgesetzt; keine API-Freigabe dafür mehr offen.
Codex-Browser bestätigt mobil 248-px-Sidebar, Logo oben, kein X, Settings unten
und Schließen bei Menüauswahl sowie Backdrop-Klick. Die bestehende KSidebar
wird weiterverwendet. Web wurde in diesem Schritt nicht verändert.

Abschließender Gesamtcheck: pnpm verify erfolgreich (Exit 0), inklusive aller
Tests und Galerie-Releasebuilds. Protokoll im Host:
tmp/dashboard-shell-flutter-parity-verify.log. Menschliche visuelle Abnahme
steht aus; kein automatischer Pixelbildvergleich behauptet.

Der Nutzer hat am 28.09.2026 den geprüften Showcase zur Übernahme in Assetry
freigegeben und ausdrücklich Commit und Push aller Designsystem-Änderungen
beauftragt. Die visuelle Abnahme ist damit erfolgt. Nächster Schritt ist die
Web-Integration in Assetry im ausdrücklich gewählten Rapid-Modus.
