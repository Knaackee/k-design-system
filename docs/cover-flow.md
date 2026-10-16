# KCoverFlow — Web and Flutter preview

16 October 2026. Consumer-configurable design-system component in Storybook and Widgetbook, awaiting human visual acceptance. No application integration or publication yet.

Content is supplied through `items: { id, label, content }[]`. IDs must be unique and stable. The consumer can control selection with `selectedIndex` / `onIndexChange`, or supply `initialIndex`. Item width, viewport height, side angle, depth, side spacing, perspective, caption, controls, styles and reduced motion are configurable. Labels are supplied by the consumer for localization.

The front item faces the user; neighbors turn into depth by default. `sideAngle: 0` keeps neighbors frontal. `sideOffset` controls the first neighbor's horizontal displacement as a percentage of cover width; `sideScale` controls its relative size before perspective. The character example uses angle 0, offset 100, scale 0.72 and depth 180. Neighbors may intentionally peek from clipped viewport edges; the selected image is fitted proportionally with `object-fit: contain`. Consumers supply appropriately sized custom content (including Rive) within the provided cover area.

Drag/swipe follows the pointer and settles to the closest item. Side covers select on click; arrows and Home/End work on the focused viewport. Vertical touch scrolling is preserved. Reduced-motion settings disable transitions. No automatic rotation. Inactive content is inert, and a live caption announces selection. Empty and single-item collections are valid. Only the visible neighborhood is mounted to limit animation cost.

Storybook: `Data display/CoverFlow`, characters and twelve arbitrary covers. Character SVGs are unchanged copies from Assist's owned `packages/web/public/brand/orbit-{sun,saturn,comet}.svg`; they are gallery content, not embedded component defaults. No dependence on the running Assist server.

Reference: Apple's iTunes 7 Cover Flow announcement (https://www.apple.com/uk/newsroom/2006/09/12Apple-Announces-iTunes-7-with-Amazing-New-Features/), and WAI carousel guidance (https://www.w3.org/WAI/ARIA/apg/patterns/carousel/). The geometry and timing here are our configurable interpretation, not a claim of Apple's exact internal animation specification.

`contentPadding` adds configurable inner space in pixels (default 16). Explicit shrinkable grid tracks prevent intrinsic image dimensions from expanding the content area. `clipSides` controls horizontal clipping (default true); vertical overflow is not clipped by the viewport. Images preserve their aspect ratio. The comet SVG includes the complete tail and feet; it is fully visible when selected in the character preview.

Flutter now exports `KCoverFlow` / `KCoverFlowItem` with equivalent geometry, padding, clipping, controlled selection, keyboard navigation and swipe behavior. Consumers provide a widget per cover; the gallery uses the same SVGs with `BoxFit.contain`. Flutter height is a logical-pixel value instead of a CSS length. Widgetbook exposes the geometry through knobs under `Data display/CoverFlow/cover-flow-characters`. Focused widget tests cover navigation, bounded mounting, empty data, horizontal swipe and preservation of vertical gestures. Assist integration remains pending visual acceptance.

For a small animated catalog, opt into `keepMounted` (default false) to prepare and retain all covers.
`visibleNeighbors` (default 3) limits visibility independently. Flutter disables hidden tickers.
Retained covers preserve their off-center transform so entry follows the correct side.
