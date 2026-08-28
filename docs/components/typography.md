# Typography

## Contract

`KText` is the shared Web and Flutter text primitive. It exposes the same
visual roles on both platforms:

- `heading1` through `heading6`
- `body` and `bodySmall`
- `label` and `caption`

Web maps heading variants to real `h1`–`h6` elements by default. Flutter maps
them to semantics heading levels 1–6. Visual role and semantic level can be
composed independently on Web through the `as` property when a product needs a
different document structure.

## Font parity

Inter 4.1 is distributed with both UI packages under the SIL Open Font License
1.1. Web loads `InterVariable.woff2` through `@font-face`; Flutter declares
`InterVariable.ttf` as the package font
`packages/k_design_tokens/Inter`. Neither platform depends on a system fallback
or a runtime font download.

## Token ownership

Every role resolves family, size, line height, weight and letter spacing from
semantic tokens. The `compact` and `standard` type-scale modes override all
role sizes and line heights together. Accessibility text scaling remains a
separate runtime axis.

## Standards basis

- [W3C heading guidance](https://www.w3.org/WAI/tutorials/page-structure/headings/)
  defines the semantic level hierarchy used by both implementations.
- [Apple typography guidance](https://developer.apple.com/design/human-interface-guidelines/typography)
  supports a small, consistent set of typefaces and scalable text styles.
- [Flutter TextStyle guidance](https://api.flutter.dev/flutter/painting/TextStyle-class.html)
  explicitly warns that platform fallback fonts are inconsistent.
- [Inter 4.1](https://github.com/rsms/inter) is the shared, OFL-licensed font
  source. Both platforms use its variable weight and optical-size axes.
