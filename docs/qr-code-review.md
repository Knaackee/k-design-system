# QR code gallery review

Scope: reusable KQrCode in Web and Flutter, gallery review only. No Onzeit integration, publication or commit authorized in this slice.

## API and composition

- Variants: classic, soft, portrait, card.
- Independent moduleShape: square, rounded, dots, fluid.
- Independent eyeShape: square, rounded, circle.
- Host supplies data, accessible label, color, size, optional image and card title/caption. No business text or routing is embedded in the component.
- Web imageUrl corresponds to Flutter ImageProvider; both use native rendering and public KStack/KInline/KText/KButton composition. Spacing uses control and section roles.
- English API keys, matching qr-code-playground gallery fixture. Gallery copy is sample content.
- QR encoding uses qrcode on Web and qr on Dart. Equivalent appearance does not imply identical mask selection or module matrices. Shared downloadable SVG/PNG generation remains outside this gallery slice.

## Scanning constraints

High error correction, four-module quiet zone, opaque white background even in dark mode. Very light foreground colors are darkened. Technical black/white QR constants intentionally do not follow inverted surface tokens. The visual-literal audit flags these constants; no baseline was silently relaxed.

Finder shapes are explicit; other structural patterns remain square. Portrait occupies 16% of symbol width plus a small white border. Finite fixture decode tests are not a scan guarantee for arbitrary data, sizes, photography or printing. Physical scanner and print validation remain required before production use.

## Evidence

- Web component build and Web/Storybook type checks passed.
- 145 Web decode/color tests passed: three URLs, four variants, four module shapes, three eye shapes. Portrait tests remove the complete image footprint to model lost data.
- Scoped Flutter analysis passed; widget tests cover variants, module and eye shapes in a narrow layout.
- Storybook and Widgetbook opened and visually inspected; Flutter dot and round-eye selection exercised.
- Widgetbook release build passed before the final shape expansion; final shapes verified in the running debug gallery and scoped analysis.
- Full pnpm verify hits the existing style-audit baseline findings plus the documented QR technical-color literals. Full verification is not green; no release readiness claimed.
- Widgetbook main.dart contained non-UTF-8 separators; these were normalized to UTF-8 while adding the fixture. Existing oversized gallery registry was not refactored.

Next: human review of the two galleries; then refine selected presets and verify real-device scanning before host integration.
