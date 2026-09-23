# Sidebar

The Web package exposes a composable Sidebar family for persistent navigation,
compact icon rails and composition inside the existing responsive Drawer.

- `KSidebar` owns controlled or uncontrolled `expanded`, `rail` and `hidden`
  display modes.
- `KSidebarHeader`, `KSidebarBody` and `KSidebarFooter` provide fixed regions
  around an independently scrolling navigation body.
- `KSidebarGroup` supports optional labels, badges, actions and controlled or
  uncontrolled disclosure.
- `KSidebarSubgroup` provides nested, independently controlled disclosure rows
  for teams, projects and other hierarchical navigation. The row itself toggles
  the subgroup, so a trailing disclosure icon is not required.
- `KSidebarItem` accepts consumer-owned leading, badge, trailing and action
  slots, links or callbacks, nesting depth and active/disabled state. The badge
  slot accepts a plain aligned count or a styled `KBadge` with any supported
  variant. Its action slot is independent, so an overflow menu can replace a
  plain count, a styled badge or an otherwise empty trailing area on hover.
- `KSidebarExpandedContent` and `KSidebarRailContent` let consumers provide
  mode-specific content without duplicating the Sidebar.
- `KSidebarToggle` changes between full and rail modes while external controls
  may also hide the Sidebar entirely.

Content, labels, routing, actions and state remain consumer-owned. Appearance,
density, focus treatment and motion use the shared design tokens. The same
content can be passed to `KResponsiveDrawer`; responsive presentation is not
hard-coded into the Sidebar itself.

The gallery includes a workspace navigation, a full-width Drawer composition
and a simpler settings navigation assembled from the same primitives and the
existing `KSearchField`.
