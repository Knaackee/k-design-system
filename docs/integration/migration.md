# Migrating an existing application

Migration is incremental. The application remains usable while shared
foundations and components replace local equivalents in bounded slices.

## 1. Establish the dependency boundary

Add the submodule at `vendor/k-design-system`, install the local packages and run
the empty Web or Flutter consumer example first. Record the accepted submodule
commit in the host repository.

Do not begin by copying components from the design-system galleries. Depend on
the public packages so future updates remain reviewable.

## 2. Map the existing UI

Inventory:

- current colors, typography, spacing, radii, elevation and motion;
- local primitives and reusable components;
- product-only screens and business behavior;
- keyboard, focus, touch and accessibility requirements;
- light/dark themes, density modes and responsive breakpoints.

Map visual values to existing semantic or component tokens. Keep the mapping in
host-owned Web CSS or a Flutter token transform. Do not rewrite shared defaults
to reproduce one product. If a requested change could reasonably be either a
host override or a new shared default, stop and obtain an explicit scope choice.

## 3. Migrate foundations before compositions

Adopt in this order unless a smaller product slice provides better evidence:

1. token defaults, fonts and app theme;
2. Text, Icon, Surface and layout primitives;
3. actions and form controls;
4. overlays and navigation;
5. data display and reusable patterns;
6. complete screens and application shells.

Replace one bounded area at a time. Preserve domain state and events in the host.
Avoid a second local wrapper unless it adds product semantics rather than merely
renaming the design-system API.

## 4. Handle a missing component

First decide whether the component is product-specific or reusable. A reusable
component belongs in the submodule and must complete Web/Flutter implementation,
gallery fixtures, focused checks and human visual acceptance before the host uses
it. A product-specific composition can remain in the application while using
design-system primitives and tokens.

## 5. Verify each slice

For every migrated area compare old and new behavior at relevant themes,
densities, viewports, text scales and input modes. Verify keyboard and screen
reader semantics, touch targets, loading/error/empty states and event wiring.
Run both package checks and the host application's production build.

Keep rollback simple: each host commit should update a bounded UI area and pin a
known design-system commit. Do not combine a broad product refactor with a
submodule upgrade.

## Completion criteria

Migration is complete when the application imports only public package APIs,
stores all product branding in host configuration, has no duplicate reusable
primitives, passes its production checks and pins a reviewed design-system
commit.
