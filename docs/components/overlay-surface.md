# Overlay surface

`color.surface.overlay` is the background role for dialogs and bottom sheets.
Its source default references `color.surface.raised`, preserving the supplied
themes. Inputs continue to use the raised surface, so a consumer can distinguish
form controls from the surrounding sheet without private component styling.

Web uses `--k-color-surface-overlay`; Flutter uses
`KDesignTokens.copyWith(colorSurfaceOverlay: ...)` in the host token transform.
Both projections resolve this semantic alias during generation; a host changing
both surfaces must set both values in its CSS theme or Flutter transform.
No existing token is removed or renamed.

`KSurface` exposes `tone="overlay"` on Web and `KSurfaceTone.overlay` on Flutter
for compositions requiring the same background. Changing this tone does not
change radius, border, padding, elevation or the theme inherited by child controls.

Verification covers default equality, independent override and interpolation,
and both Flutter overlay variants keeping input backgrounds unchanged. Matching
compact-sheet gallery fixtures demonstrate the consumer override; visual
acceptance remains separate from these automated checks.
