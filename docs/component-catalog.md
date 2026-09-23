# Component catalog

Status: target catalog, 2026-09-16. This is a roadmap, not approval to implement
every entry. Actions and Toolbar are implemented. The current authorized Rapid
slice is Field, Input, SearchField, Checkbox, Select, Combobox, FilterChip and
FilterBar, with matching Web and Flutter fixtures and tests.

## Categories and scope

| Category     | Families                                                                                                                                                   | Delivery                                                                                                                  |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| Foundations  | Color, typography, density/spacing, radius, elevation, icon overview                                                                                       | Existing foundations; showcases, not additional components                                                                |
| Primitives   | Text, Icon, Surface, Stack, Inline, Container, Grid, Separator                                                                                             | Existing                                                                                                                  |
| Actions      | Button, IconButton, ButtonGroup, MenuButton, SplitButton                                                                                                   | Button, IconButton and MenuButton implemented                                                                             |
| Menus        | Menu, OverflowMenu, ContextMenu; groups and submenus                                                                                                       | Flat action menu, overflow and context menu with submenus implemented                                                     |
| Forms        | Field, Input, Textarea, SearchField, Checkbox, RadioGroup, Switch, Select, Combobox, MultiSelect, SegmentedControl, DatePicker, TimePicker, DateTimePicker | Field, Input, SearchField, Checkbox, Select, Combobox and the three pickers implemented; picker visual acceptance pending |
| Overlays     | Tooltip, Popover, Dialog, Drawer, BottomSheet                                                                                                              | Independent contracts required; internal menu/picker surfaces do not establish public Popover/Dialog APIs                 |
| Navigation   | Link, Tabs, Breadcrumb, Sidebar, NavigationItem/Section, BottomNavigation, Pagination                                                                      | After table foundations                                                                                                   |
| Data Display | Card, Badge, Avatar, List/ListItem, DescriptionList, Table, Accordion                                                                                      | Card exists; Table after inputs                                                                                           |
| Feedback     | InlineNotice, Toast, Progress, Spinner, Skeleton, EmptyState                                                                                               | Deliver alongside consumers that need them                                                                                |
| Patterns     | Toolbar, FilterBar/FilterChip, DataTable, PageHeader, AppShell, DetailInspector                                                                            | Toolbar, FilterBar and FilterChip implemented                                                                             |

NumberInput, Slider, FileUpload, TreeView and CommandPalette are deferred
candidates. Rich-text editing, Kanban, charts, virtualization and advanced
editable data grids require their own scope. KGrid is a layout primitive, not a
data grid. Menu items and icon glyphs are not separate component families.

## Catalog maintenance

Each delivered family has a stable category/name, contract, dependencies, matching
fixture IDs, Web/Flutter implementation status, supported states, responsive rules,
keyboard and semantic behavior, verification evidence and human acceptance status.
Proposed names are not frozen public APIs.

Both galleries use the same case-insensitive alphabetical category/folder order.
Keep folders visible for single-fixture families. New entries use the categories
above. Existing Primitives/Button and Primitives/Card URLs remain until a separate
coordinated migration; this document does not silently relocate existing stories.

## Delivery sequence

1. IconButton, flat MenuButton/OverflowMenu and wrapping Toolbar. Shared menu data
   includes stable IDs, labels, optional icons, disabled and destructive states,
   group boundaries and callbacks. Explicit overflow actions remain available at
   every width; no implicit removal of actions into an automatic overflow menu.
2. Field, Input/SearchField, Checkbox, Select/Combobox, then filter chips and bar.
3. DatePicker, TimePicker and DateTimePicker with configurable formats, locale,
   IANA time zone, bounds and clearing. DateTime values are UTC instants; local
   DST gaps and overlaps have explicit handling. See [picker contract](components/pickers.md).
4. Table and composed DataTable: sorting, selection, toolbar, filters, pagination,
   loading/error/empty states. Application owns fetching, domain queries and saved
   views. Advanced cell editing and virtualization follow demonstrated needs.
5. Sidebar/AppShell and adaptive Dialog/Drawer/BottomSheet/Inspector.
6. Remaining families according to actual consumer requirements.

For equal viewport, density, input mode, theme and text scale, match geometry and
appearance across platforms. Test phone, tablet and desktop, including mobile Web.
Define adaptations by available space and input needs, not by platform name.
Raster antialiasing differences require visual review; tests do not imply human
acceptance. Browser evidence does not replace native-device accessibility testing.

## Reference evidence

Bullets was inspected read-only, not executed or certified. Relevant paths under
`D:/Development/bullets`:

- `packages/web/src/features/issue-workspace/workspace-toolbar.tsx`: compact
  grouped actions, filters, view options and overflow.
- `packages/web/src/ui/work-item-overflow-menu.tsx`: shared action entries and
  visible/context menu presentations.
- `packages/web/src/features/issue-workspace/issue-table.tsx` and
  `packages/app/lib/features/projects/presentation/adaptive_issue_table.dart`:
  table interactions and adaptive rows.
- `packages/web/src/components/ui/adaptive-surface.tsx`: anchored and modal surfaces.
- `packages/app/lib/features/shell/shell_adaptive_sidebar.dart`: navigation sections
  and collapsed/expanded layout.

Use Bullets' visual restraint and interaction examples; keep issue/project logic,
permissions and query persistence outside the design system. Do not copy its
underlying library dependencies or assume existing accessibility is complete.

External sources, consulted 2026-09-16:

- [Carbon Data Table](https://carbondesignsystem.com/components/data-table/usage/):
  table toolbar, filtering, selection and pagination composition.
- [Atlassian components](https://atlassian.design/components/): component families
  and navigation coverage.
- [Spectrum Action Menu](https://opensource.adobe.com/spectrum-web-components/components/action-menu/):
  commands are distinct from value selection in a picker.
- [W3C toolbar pattern](https://www.w3.org/WAI/ARIA/apg/patterns/toolbar/) and
  [menu button pattern](https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/):
  keyboard navigation, roles and focus handling.

The requested reference “PETA” remains unidentified and is not used as evidence.

## Current slice acceptance and checks

Allowed paths: Web/Flutter UI packages, both gallery applications, component
documentation and affected test tooling. Reuse existing tokens and icon vectors;
no token axes, protected Plan/ADR body edits, dependency adoption or commits.

The actions slice is implemented and the control typography correction was
visually accepted by the user. The next authorized Rapid slice comprises Field,
Input, SearchField, Checkbox, Select, Combobox, FilterChip and FilterBar. Table and
DataTable remain for a separate joint review. See [forms contract](components/forms.md).

Verify input labels, errors, read-only and disabled states, mixed checkbox,
keyboard selection, local search and cancellation, filter removal and reset.
Compare matching fixtures at phone/tablet/desktop widths, densities, themes and
200% text. Run affected native/browser tests and finish with `pnpm verify`.
Record omissions explicitly before human visual acceptance.
