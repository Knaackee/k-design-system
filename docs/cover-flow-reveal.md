# KCoverFlow reveal

Matching fixture: `cover-flow-reveal` in Storybook and Widgetbook.

| Property         | Web / Flutter default | Meaning                                                              |
| ---------------- | --------------------- | -------------------------------------------------------------------- |
| reveal           | false                 | Enable the entrance, opt-in                                          |
| revealKey        | 0                     | Change to replay without replacing card content                      |
| revealDurationMs | 1100                  | Per-card duration in milliseconds                                    |
| revealStaggerMs  | 200                   | Delay per distance from selected card                                |
| revealDistance   | 36                    | Initial vertical offset, CSS px / logical pixels                     |
| revealScale      | 0.94                  | Initial scale, clamped to 0.1–1                                      |
| onRevealComplete | optional callback     | Current run completed, including reduced-motion immediate completion |

The selected card enters first; equally distant neighbors enter together.
Curve: cubic-bezier(0.22, 1, 0.36, 1). Opacity, vertical translation and scale
animate inside the cover transform, preserving perspective and selection.
Normal selection changes do not replay. Updating reveal parameters or item count
restarts the run; disabling reveal cancels it. Disposing cancels pending callbacks.
Reduced motion (explicit or system) displays content immediately. Navigation and
caption do not animate. Sound and celebration remain consumer compositions.

Verification: Web build and TypeScript checks pass. Flutter cover-flow tests cover
replay, retained content, reduced motion, selection and drag. Full `pnpm verify`
stops at existing style-audit baseline differences in menu surface, showcase grid
and celebration files; these unrelated files were not changed.
