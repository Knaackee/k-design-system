# DiceBear avatar

`KDiceBearAvatar` generates avatars locally from DiceBear definitions. The
approved catalogue contains 57 styles: 42 CC0, 14 CC BY 4.0 and one MIT style.
CC BY artwork requires attribution; MIT artwork requires its license notice.
Catalogue metadata preserves creator, source and license details. The Avataaars
and Bottts families are excluded pending a separate license review.

## Configuration

The consuming application owns the seed, selected style and options. Every
option supported by the selected DiceBear style is forwarded to the engine.
Use the option descriptor to discover valid names, variants and ranges; not
every style has hair, eyes or a mouth. For example, Adventurer accepts:

```json
{
  "mouthVariant": ["variant01"],
  "hairVariant": ["short01"],
  "eyesVariant": ["variant02"],
  "hairColor": ["#884422"]
}
```

The seed is a separate component input. Randomized SVG IDs are disabled to keep
generation reproducible. Avatar size and surrounding appearance use the existing
avatar design tokens; artwork options are consumer content, not global tokens.

Web definitions load individually on demand. Flutter definitions are generated
from the same pinned catalogue and bundled locally, with parsed styles cached.
Neither platform sends seeds or customization data to an avatar service.

## Rendering boundary

The engines share SVG generation. The 19 animated styles opt in through
`animationVariant: ["medium"]` (also `fastest`, `fast`, `slow`, `slowest` and
`none`). Web uses the original SVG CSS in isolated shadow roots. Flutter parses
those same timelines and prepares SVG layers once, then applies transforms and
opacity natively. `motionPaused` freezes/resumes the current frame; platform
reduced-motion preferences disable motion. Flutter also respects `TickerMode`.
Use `kDiceBearAnimatedStyleIds` to discover the generated animated catalogue.

The native adapter supports the pinned DiceBear keyframe syntax. Custom CSS
animation directly on an SVG `<use>` is unsupported and fails explicitly; none
of the 19 official animated styles uses that structure. Font rendering and SVG
rasterization can still differ by platform. The default
`glass` and `marbles` styles use Gaussian-blur SVG filters that `flutter_svg`
does not render; those two currently look sharper in Flutter. The remaining 55
default styles decode without filter warnings. Identical SVG generation therefore
does not establish pixel-identical rendering for the full catalogue.

## Review

Matching fixtures: `dicebear-avatar-playground`, `dicebear-avatar-catalogue` and
`dicebear-avatar-animation`.
The playground exposes the style, seed and option map; the catalogue shows all
approved styles with their attribution. Flutter visual acceptance remains with
the user.

Verification (2026-10-13): `pnpm verify` passed, as did the additional widget
render/update test. All 57 default SVGs match the JavaScript fixtures byte for
byte; mouth, hair and eye variant fixtures match too. The release Widgetbook
playground and catalogue were opened in the Codex browser, and changing hair,
hair color and mouth visibly updated the avatar. No commit or publication was
requested for this slice.

Animation verification (2026-10-13): generated catalogue and Web animation
tests passed. Flutter tests cover all 19 animated scenes, layer rendering,
opacity, delay, pause, reduced motion, disabled tickers and clipping order.
The full verification program initially found two integration issues in the
new clipping test/helper; these were fixed and the remaining analyzer, full
Flutter test suite and both gallery builds passed on re-run. Both animation
fixtures were opened in the Codex browser and their pause controls exercised.
Human visual acceptance of motion remains pending.
