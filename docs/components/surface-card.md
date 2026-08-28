# Shape, elevation, surface, and card

## Intent

These primitives provide the restrained spatial hierarchy used by the default
theme. The reference direction follows Linear: in-flow surfaces are separated
primarily by subtle color and one-pixel borders. Shadows communicate actual
layering, not decoration.

## Shared contract

- Radius roles: `none`, `small`, `medium`, `large`, `extraLarge`, and `full`.
- Component roles: `card` resolves to 6 px and `overlay` resolves to 8 px.
- Border roles: `none`, `default`, and `strong`.
- Elevation roles: `none`, `low`, `medium`, and `overlay`.
- Surface tones: `canvas`, `raised`, and `subtle`.
- A Card is a semantic Surface with card radius, default border, token padding,
  and no elevation by default.

Elevation is intentionally sparse:

| Role      | Intended use                     |
| --------- | -------------------------------- |
| `none`    | Cards and other in-flow surfaces |
| `low`     | Floating utility controls        |
| `medium`  | Menus and popovers               |
| `overlay` | Dialogs and modal layers         |

## Token delivery

Shadow values are authored as DTCG composite shadow tokens. The generator emits
the same source as comma-separated CSS `box-shadow` layers and Flutter
`List<BoxShadow>` values. Consumers can override the semantic roles without
changing either component implementation.

Flutter borderless surfaces use `null` rather than a zero-width `BorderSide`,
because Flutter renders a zero-width border as a hairline.

## Review fixtures

The galleries expose matching fixtures:

- `shape-radius-scale`
- `elevation-levels`
- `surface-tones`
- `card-variants`

Review all fixtures in light and dark themes. Surface and Card must also respond
to the existing presentation, density, type-scale, input-mode, and window-class
configuration through their child content and semantic spacing tokens.

## References

- DTCG Design Tokens Format Module, composite shadow type:
  <https://www.designtokens.org/tr/2025.10/format/>
- Local Linear-parity references:
  `D:/Development/bullets/docs/mockups/linear-parity-web-core.html` and
  `D:/Development/bullets/docs/mockups/linear-parity-mobile-core.html`
