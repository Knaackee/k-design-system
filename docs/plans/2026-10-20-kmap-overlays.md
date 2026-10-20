# KMap: Pins und Routensegmente — Storybook-Slice

Stand: 20. Oktober 2026. Akzeptierter Umfang: ausschließlich Web/Storybook.

## Öffentlicher Vertrag

Import: `@k-design-system/ui/patterns/map`, CSS: `@k-design-system/ui/maps.css`.

- `pins`: stabile ID, `[longitude, latitude]`, zugänglicher Name, optional Icon, Bild-URL, Farbe, Größe und Form (`pin`, `circle`, `square`). Keine feste Anzahlbegrenzung; keine Zusage für unbegrenzt viele DOM-Marker.
- `selectedPinId` kontrolliert die Auswahl, alternativ `defaultSelectedPinId`. Events: `onPinClick(id)` und `onSelectionChange(id)`.
- `draggable` ist je Pin standardmäßig false. `onPinMove({ id, position, source })` meldet Drag-Ende oder Pfeiltastenänderungen. Die Anwendung muss die neue Position übernehmen; ansonsten gilt weiter die übergebene Position. Keine automatische Routenneuberechnung. Shift + Pfeiltaste vergrößert den Schritt.
- `routes`: stabile ID, bereits berechnete Koordinaten, Farbe, Breite, gestrichelte Linie. `selectedRouteId` hebt eine Route hervor.
- `segments`: IDs je Route eindeutig; `startIndex` und `endIndex` beziehen sich inklusiv auf die Elterngeometrie. Abschnitte aufsteigend, ohne Überlappungen; gemeinsame Endpunkte erlaubt. Lücken behalten die Grundlinie. Farbe, Breite und Strichelung pro Abschnitt überschreibbar. `traffic` kann `free`, `slow` oder `congested` sein; explizite Farbe gewinnt.
- Standardfarben erben KDS-Marken-/Statusfarben. CSS-Overrides: `--k-map-route-color`, `--k-map-traffic-free`, `--k-map-traffic-slow`, `--k-map-traffic-congested`.
- `fitContent` passt optional alle Geometrien ein; `fitPadding` bestimmt den Rand. Für interaktives Verschieben im Beispiel ausgeschaltet, damit die Kamera nicht nach jeder Bewegung springt.

## Anbindung externer Daten

KMap benötigt keine API-Zugänge und enthält keine Anbieterlogik. Der Host dekodiert und normalisiert Antworten. Valhalla verwendet Shape-Indizes (etwa `begin_shape_index` / `end_shape_index`) und typischerweise Polyline-Präzision 6. TomTom Routing v1 liefert für Sections `startPointIndex` / `endPointIndex`; Traffic-Sections müssen angefordert werden. Indexbezug pro Leg beziehungsweise gesamter Route und Koordinatenreihenfolge beim jeweiligen Adapter ausdrücklich beachten. Manöver sind keine Verkehrsdaten: Stauzustände niemals daraus erfinden. Ein Adapter für einen bestimmten Anbieter ist noch nicht umgesetzt.

Quellen:

- https://github.com/valhalla/valhalla/blob/master/docs/docs/api/route/api-reference.md
- https://valhalla.github.io/valhalla/api/decoding/
- https://docs.tomtom.com/routing-api/documentation/tomtom-maps/v1/calculate-route

## Prüfumfang

Storybook: Pins, Logo-Pins, Routen, Pins mit Route, Verkehr/Routensegmente, Pins verschieben. Geometrie, ID- und Segmentvalidierung durch Node-Tests abgedeckt. Route-Fixtures sind illustrative Linien, keine berechneten Straßenrouten. Flutter, Anbieteradapter, Clustering und Lasttests sind nicht Bestandteil dieses Slice. Keine Veröffentlichung, kein Deployment.

Ergänzung: `renderPin(pin, { selected, draggable, dragging })` ist ein freier React-Slot für die visuelle Darstellung, auch für consumerseitige Rive-Komponenten. KMap fügt keine Rive-Abhängigkeit hinzu und übernimmt den zugänglichen Button sowie Position/Drag. Der Slot enthält keine weiteren interaktiven Elemente. Storybook „Consumer-Inhalte“ zeigt diesen Vertrag mit einem SVG.

## Verifikation dieser Revision

- `pnpm build:web`, `pnpm typecheck:web`, `pnpm audit:styles`, `pnpm build:storybook`: bestanden.
- `pnpm test:web-ui`: 16/16 bestanden, einschließlich Segmentgrenzen und Geometrievalidierung.
- Browser: Pin-Auswahl mit `onSelectionChange`/`onPinClick`, Mausverschieben mit übernommener Position, Logoformen, Consumer-SVG-Slot und grün/gelb-orange/rote Segmente geprüft.
- Kein nativer Flutter-Test, kein Rive-Laufzeittest und kein Anbieter-Livetest in diesem Web-Slice. Kein vollständiger Monorepo-Verify-Lauf behauptet.
- Nächster Schritt: visuelle Abnahme der Storybook-Beispiele durch den Nutzer.

## Anheben und Absetzen (20. Oktober 2026)

- �ffentliche KMap-Option `pinDrag`: `activation` (`drag` / `longPress`), `longPressMs` (400), `scale` (1.15), `durationMs` (160). �berschreibung je Pin mit `drag`. Skalierung 1 oder Dauer 0 deaktivieren den jeweiligen Effekt.
- Ereignisse `onPinDragStart`, `onPinDrag`, `onPinDragEnd`; die endg�ltige Entscheidung erfolgt �ber `onPinMove`. Verbraucher wie Rive erhalten zus�tzlich `dragging` im Render-Slot.
- Animation um den Kartenanker; reduzierte Bewegung wird respektiert. Long Press bricht vor Aktivierung bei mehr als 8 Pixel Bewegung ab. Pointer-Abbruch oder Escape setzt zur�ck.
- Gemeinsame Implementierung unter `packages/web/ui/src/maps/map-pin.tsx`; Storybook enth�lt nur Consumer-Konfiguration, Events und eine optionale Host-Antwortsimulation.
- Web/Storybook-Slice; echte Touchger�te und Rive-Laufzeit sind noch nicht Teil der Verifikation.

Verifikation Drag-Slice: Web-Build, TypeScript, Style-Audit und Storybook-Build bestanden; 17/17 Web-Tests bestanden. Browserprüfung: direktes Ziehen/Übernehmen, Long Press mit Start-/End-/Move-Events, verzögerte Ablehnung mit Rückkehr zur ursprünglichen Position. Screenshot: `artifacts/ui/kmap-pin-long-press.png` im Onzeit-Workspace. Native Touch-/Flutter-Abnahme steht aus. Kein Commit, Push oder Deployment.
