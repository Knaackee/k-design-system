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

## Shared fixtures

- `button-primary`
- `button-states`

## Semantic tokens

- `color.action.primary.{background,hover,pressed,foreground}`
- `color.border.focus`
- `size.control`
- `space.{controlGap,controlInsetInline}`
- `radius.control`
- `font.{family,size,weight}`
- `motion.fast`

## Review boundary

The next visual review may change Button styling and token values, but must not
bypass the generated token packages or diverge the shared fixture intent.
