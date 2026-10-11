# Audio edge glow

`KAudioEdgeGlow` adds decorative audio-reactive fields along a bounded surface's edges. The consumer owns the character color, normalized microphone level and lifecycle (`inactive`, `capturing`, `processing`). Inactive renders nothing; capturing responds to level and optional `voiceDetected`; processing retains quiet perimeter motion without microphone energy.

Web fills a `position: relative` parent. Flutter belongs in `Positioned.fill` inside a bounded `Stack`. Both ignore pointer input and exclude their decoration from accessibility. Consumers retain responsibility for an accessible capture status/control.

The four overlapping blurred sweep layers reproduce the approved EAR aurora reference, using lighter/base/darker tones derived from the supplied character color. Energy uses a small noise floor and 70 ms attack / 260 ms release smoothing. No brand color or audio-device logic is owned by the package.

`reducedMotion` freezes travel while continuing to display current energy. OS reduced-motion preferences are always respected. Animation pauses when the browser document/app is hidden; Flutter also respects `TickerMode`.

Matching Storybook and Widgetbook fixture IDs: `audio-edge-glow-quiet`, `audio-edge-glow-speaking`, `audio-edge-glow-processing`, `audio-edge-glow-reduced-motion`, `audio-edge-glow-inactive`.

Web uses Canvas 2D conic gradients and blur filters; Flutter uses sweep shaders and mask blur. These rendering engines can differ slightly at blurred boundaries. No new token axes are introduced: geometry is intrinsic to the approved visual effect, and its palette is consumer-derived.
