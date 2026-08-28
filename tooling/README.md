# Tooling

`generate-tokens.mjs` validates DTCG token nodes, resolves references, rejects
cycles and unknown references, then produces Web, Flutter and normalized JSON
projections. Generated outputs must never be edited by hand.

```bash
pnpm generate
pnpm generate:check
pnpm test:tooling
```
