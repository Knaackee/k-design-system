# Consumer theming

K Design System projects one platform-neutral DTCG source to live Web custom
properties and a typed Flutter `ThemeExtension`. The default values reproduce
the accepted Orbit UI. Consumers can change the appearance without replacing
component behavior, state ownership or accessibility semantics.

## Token tiers

- Foundation tokens are context-free source scales. Applications normally do
  not override them directly.
- Semantic tokens describe reusable intent such as surfaces, text, focus,
  spacing, shape, elevation, opacity and motion.
- Component tokens describe independently customizable component parts. Their
  defaults remain aliases to semantic roles.

Component tokens are appropriate for a narrow change such as the floating
Mobile App Bar radius. Semantic tokens are appropriate for a system-wide change
such as removing rounding or changing disabled opacity.

## Web

Import the generated token stylesheet once. Override custom properties on the
application root or a smaller subtree:

```css
.square-theme {
  --k-radius-small: 0px;
  --k-radius-control: 0px;
  --k-radius-card: 0px;
  --k-radius-overlay: 0px;
  --k-radius-full: 0px;
}

.compact-navigation {
  --k-component-mobile-app-bar-container-radius-floating: 12px;
}
```

Component aliases in the generated CSS use `var(...)`, so later semantic
overrides continue to cascade unless a component property is explicitly set in
the same scope.

## Flutter

Install a transformed generated token set through `kDesignTheme`:

```dart
MaterialApp(
  theme: kDesignTheme(
    tokenTransform: (tokens) => tokens.copyWith(
      radiusSmall: 0,
      radiusControl: 0,
      radiusCard: 0,
      radiusOverlay: 0,
      radiusFull: 0,
    ),
  ),
);
```

Generated `copyWith` preserves semantic-to-component dependencies. An explicit
component override in the same call wins:

```dart
tokens.copyWith(
  radiusFull: 0,
  componentMobileAppBarBadgeRadius: 7,
);
```

## Accessibility responsibilities

Visual size and hit-target tokens are separate. Keep touch targets at least the
provided touch-mode default, retain visible focus treatment, and verify contrast
when overriding foreground, background or scrim colors. Motion overrides must
continue to respect each platform's reduced-motion setting.

## Source enforcement

`pnpm audit:styles` rejects new unapproved raw colors, radii, shadows,
typography, opacity and animation timing in handwritten component-package
source. The small checked-in exception file contains only documented structural
interaction constants; it is not a source of design defaults.

Native-only elevation aliases preserve the accepted Flutter shadows during the
migration. Web retains its accepted elevation defaults. Both remain externally
themeable, and this documented projection difference avoids an accidental visual
redesign.
