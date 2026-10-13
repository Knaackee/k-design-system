# KScreenSwitcher — Web preview

Approved scope: independent Web component and Storybook demo; Flutter follows visual acceptance.

Controlled API: `items` with stable IDs, titles, icons and arbitrary content; `activeId`, `mode` (`overview`, `screen`, `minimized`), `onStateChange`, `onCloseRequest`. All labels are external. Closing only requests removal; the consumer owns confirmation and persistence. Keep IDs unique. Content stays mounted until the consumer removes its item; inactive content is inert.

Appearance reuses surface, text, border, spacing and overlay tokens. CSS overrides: `--k-screen-switcher-perspective`, `--k-screen-switcher-tilt`, `--k-screen-switcher-step`, `--k-screen-switcher-card-height`, `--k-screen-switcher-duration`. Reduced motion disables transitions.

Story: Navigation/ScreenSwitcher/Workspace; fixture `screen-switcher-workspace`. Four editable screens, overview, minimize/reopen and close. Browser verified title persistence after minimize/reopen. Web build, typecheck and visual literal audit passed. Full verification log: `.dart_tool/screen-switcher-verify.log`.

Not a router or a data persistence layer. Retaining all screens trades memory for state preservation; consumers should keep the open-screen collection bounded. Physical touch-device/keyboard and Flutter parity still require validation. Next: user visual review of Storybook.
