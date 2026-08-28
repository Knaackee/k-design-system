# Semantic colors

Components consume semantic color roles, never foundation palette values.

## Brand roles

- `color.brand.primary.*`
- `color.brand.secondary.*`

## Status roles

- `color.status.info.*`
- `color.status.success.*`
- `color.status.warning.*`
- `color.status.error.*`

Each role provides `accent`, `background`, `foreground` and `border`. This lets
a consumer replace an entire appearance without changing a component contract.
The generated-token test enforces WCAG AA 4.5:1 contrast for every foreground
and background pair in every included theme.

The accessibility gate follows
[WCAG 2.2 contrast minimum](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum):
normal text requires at least 4.5:1 contrast and large text at least 3:1. K
Design System intentionally applies the stricter 4.5:1 threshold to every role
fixture.
