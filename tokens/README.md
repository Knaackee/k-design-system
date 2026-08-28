# Token sources

Platform-neutral DTCG token sources are the canonical design input. No platform
package is allowed to become the token source.

## Sources

- `foundation.tokens.json`: raw scales.
- `semantic.tokens.json`: roles consumed by components.
- `themes/*.tokens.json`: brand and color-mode overrides.
- `modes/*.tokens.json`: presentation, density, typography, input and window
  overrides. Each file may change existing semantic roles only.

## Generated projections

- Web CSS and TypeScript in `packages/web/tokens/src/generated`.
- Flutter `ThemeExtension` in
  `packages/flutter/k_design_tokens/lib/src/generated`.
- Normalized inspection data in `dist/tokens.flat.json`.

Run `pnpm generate` after changing sources. CI uses `pnpm generate:check` and
fails when committed projections no longer match their sources.

See
[the adaptive foundation decision](../docs/decisions/0001-adaptive-foundation.md)
for axis ownership, preset mappings and responsive boundaries.
