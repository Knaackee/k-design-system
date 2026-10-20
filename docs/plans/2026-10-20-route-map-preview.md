# Karten-Komponente: erste Web-Abnahme

Der Nutzer hat zunächst ausschließlich Storybook beauftragt. Flutter/Widgetbook,
Onzeit-Integration, Routing-Server-Reparatur, Commit und Deployment sind nicht
Teil dieses Schritts. Ausgangspunkt: sauberer `main`, fast-forward auf `65df4e2`.
Die Nutzerentscheidung, auf dem Hauptzweig zu arbeiten, bleibt bestehen.

## Umsetzung

- `KRouteMap` unter `packages/web/ui/src/patterns/route-map.tsx`, separat über
  `@k-design-system/ui/patterns/route-map` importierbar. Kein schwerer Kartenexport
  im allgemeinen Einstiegspunkt.
- MapLibre GL JS 6.15.0, ohne React-Wrapper. Host lädt
  `maplibre-gl/dist/maplibre-gl.css` und konfiguriert MapLibres Worker.
- KDS-Styles, Buttons, Icons und kontrollierte Auswahl von Marker und Liste.
- Host übergibt Style, Koordinaten und Stopps. Keine Adresssuche oder Routing-API
  innerhalb der Komponente.
- Storybook `Maps/Route`: drei Stopps, Dark Mode, nicht erreichbarer Stopp.
- Externe OpenFreeMap-Kartenquelle ausschließlich als Galerie-Quelle gewählt.
  Aufgezeichnete Valhalla-Geometrie aus dem lokalen Routing-Versuch vom 18. Oktober; Zwischenstopp und Uhrzeiten sind illustrative Fixtures.
- Kein Abruf von Nutzerstandorten, keine privaten Adressen.

## Prüfung

Web-Build und Storybook-Typecheck bestanden. Browserprüfung: Liste selektiert
genau einen Marker und eine Zeile; Markerklick aktualisiert die Liste zurück.
Visuelle Prüfung mit tatsächlich geladenen Kartenkacheln; Light und Dark.
Visual-Literal-Audit bestanden.

Der erste Gesamtcheck fand einen CSS-Import im JS-Einstieg, der den
Tree-Shaking-Test störte. CSS wurde in den Host verschoben und der allgemeine
Export entfernt. Der erneute Gesamtcheck und Storybook-Build werden separat
ausgewertet; kein pauschaler grüner Status daraus abzuleiten.

## Grenze und nächster Schritt

Vorläufige Web-Komponente, keine Plattformabnahme. Keine Standortauswahl,
Zonenbearbeitung, Live-Routing oder Offline-Kacheln implementiert.
Nächster Schritt: menschliche Sichtprüfung der Storybook-Ansicht, danach
entsprechenden Flutter-Vertrag und Widgetbook-Fixture umsetzen.
