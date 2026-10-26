# Kartenkomponenten in Widgetbook

## Auftrag

Die am 20. Oktober 2026 in Storybook abgestimmten Kartenkomponenten werden in
Flutter und Widgetbook übertragen. Die Komponenten gehören zum ausgelieferten
Design-System; Widgetbook enthält ausschließlich Beispiele und deren Daten.
Commit, Push und Deployment gehören nicht zu diesem Auftrag.

## Vergleichsflächen

| Storybook                        | Widgetbook             | Zu prüfen                                                           |
| -------------------------------- | ---------------------- | ------------------------------------------------------------------- |
| Maps / Map                       | Maps / Map             | Gemeinsamer Kartenstil, Theme und Bedienung                         |
| Maps / Map Overlays              | Maps / Map Overlays    | Pins, Logos, eigene Inhalte, Auswahl, Routen und Verkehrssegmente   |
| Draggable Pins / Long Press Pins | Gleichnamige Beispiele | Aktivierung, Vergrößerung, Ablegen und abgelehnte Änderung          |
| Maps / Day view                  | Maps / Day view        | Rechte Seitenleiste, mobiles Sheet, Zeitlinie, Auswahl und Aktionen |
| Maps / Location Picker           | Maps / Location Picker | Auswahl, Suche, Pill, Kamera, Pin und Hinweis                       |

## Abgrenzung

Die Adresssuche und Standortauswahl der Galerie verwenden feste Beispieldaten.
Die Tagesansicht zeigt feste Termine und Prognosen; sie berechnet keine Route.
Geocoding, echte Standortberechtigung und Routing-Provider werden vom Consumer
bereitgestellt. Eigene Pin-Inhalte werden als Flutter-Widgets übergeben und
können auch Rive enthalten.

Die visuelle Abnahme erfolgt in Widgetbook. Eine spätere Integration in Onzeit
und die Prüfung auf echten Android-/iOS-Geräten sind getrennte Schritte.

## Prüfstand

Flutter-Paket und Widgetbook: statische Analyse ohne Befunde.
18 gezielte Karten-, Overlay-, Tagesansichts- und Picker-Tests bestanden.
Im Codex-Browser geprüft: Verkehrssegmente und Pin-Anker, rechte Tablet-Seitenleiste,
Kartenunschärfe sowie direktes Wiederöffnen der vorausgefüllten Adresssuche.

Der vollständige Repository-Check ist nicht grün: Der Style-Audit beanstandet
noch den konfigurierbaren Long-Press-Standard von 400 ms, der der Web-Komponente
entspricht. Die Audit-Baseline wurde nicht zur Unterdrückung geändert.

Widgetbook ist zur visuellen Human Acceptance geöffnet. Native Geräte und echte
GPS-/Geocoding-Dienste wurden in diesem Schritt nicht geprüft. Eine endgültige
Pixelparität ist erst nach visueller Abnahme bestätigt.

Widgetbook-Release-Build erfolgreich. Der Build meldet bestehende Warnungen zur
Wasm-Kompatibilität von isolate_contactor und einem Cupertino-Font; gebaut wurde
das reguläre JavaScript-Webziel.

### Ergänzung: Consumer-gesteuertes Tages-Sheet

Am 20. Oktober 2026 lokal beauftragt und umgesetzt, ohne Commit/Push/Deployment:
Web und Flutter exportieren KMapDaySheetController mit fraction, state,
isAttached/isSheet, animateTo und snapTo. Der tatsächliche Öffnungsgrad wird
während manueller Bewegung und Animation gemeldet. Bestehende panelState-Werte
werden weiter unterstützt; unveränderte Props setzen eine freie Position nicht
zurück. Mindesthöhe und konfigurierte Grenzen bleiben wirksam.

Die Galerie-Beispiele verkleinern das Sheet bei einem Eintragsklick auf angeforderte
45 Prozent und fokussieren die Karte. Die ausgewählte Zeile bleibt sichtbar.
Die schwebende Beschriftung über der Karte wurde entfernt. Alle Eintragstexte
kommen vom Consumer; interne Status- und Prognoseformulierungen sind über Labels
oder Renderer überschreibbar. Die Desktop-Seitenleiste bleibt unverändert.

Geänderte Bereiche: Web map-day-view und Sheet-Helper/Controller, Flutter
k_map_day_* einschließlich Controller/Motion, beide Galerie-Fixtures und Tests.
Verifiziert: sechs Flutter-Tests, fünf Web-Tests, Storybook-Typecheck, gezielte
Dart-Analyse sowie Auswahl/Verkleinerung und sichtbare Selektion in beiden
Browser-Galerien. Der vollständige Check wird separat im temporären Log
kds-day-sheet-verify.log festgehalten; kein vollständiges Grün daraus ableiten.
Nächster Schritt: visuelle Abnahme durch den Nutzer. Native Geräte wurden für
diese Ergänzung nicht geprüft. Kein neuer Token und keine Audit-Baseline geändert.
