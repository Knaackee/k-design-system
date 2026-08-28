# Button

> Status: technical baseline complete; visual acceptance pending

The generic Button proves the vertical token and gallery pipeline. It is not yet
the final approved Button design.

## Shared behavior

- Activates once through the platform-native button control.
- Disabled and loading states cannot activate.
- Loading retains its label and exposes progress visually.
- Web supports keyboard focus, hover, pressed and reduced motion.
- Flutter uses native Material focus, hover, pressed and semantics behavior.
- Flutter suppresses the Material ripple; token-driven state colors are the
  shared visual feedback on both platforms.

## Shared fixtures

- `button-primary`
- `button-states`

## Semantic tokens

- `color.action.primary.{background,hover,pressed,foreground}`
- `color.border.focus`
- `size.control`
- `size.hitTarget`
- `space.{controlGap,controlInsetInline}`
- `radius.control`
- `font.{family,size,weight}`
- `motion.fast`

## Review boundary

The next visual review may change Button styling and token values, but must not
bypass the generated token packages or diverge the shared fixture intent.
The `button-states` fixture is also the reference surface for independently
reviewing adaptive token axes before additional primitives are introduced.
