# Component catalog

Status: release-candidate catalog, updated 2026-11-05. This records public package
coverage and remaining candidates; a gallery fixture alone is not a public API.

## Categories and scope

| Category     | Families                                                                                                                                                                     | Delivery                                                                                                                                                                |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Foundations  | Color, typography, density/spacing, radius, elevation, icon overview                                                                                                         | Existing foundations; showcases, not additional components                                                                                                              |
| Primitives   | Text, Icon, Surface, Stack, Inline, Container, Grid, Separator                                                                                                               | Existing                                                                                                                                                                |
| Actions      | Button, IconButton, ButtonGroup, MenuButton, SplitButton                                                                                                                     | Button, IconButton, MenuButton on Web and Flutter. ButtonGroup and SplitButton not built                                                                                |
| Menus        | Menu, OverflowMenu, ContextMenu; groups and submenus                                                                                                                         | Overflow and context menu with groups and submenus on Web and Flutter                                                                                                   |
| Forms        | Field, Input, Textarea, SearchField, Checkbox, RadioGroup, Switch, Select, Combobox, MultiSelect, SegmentedControl, Slider, InputOTP, DatePicker, TimePicker, DateTimePicker | All listed except MultiSelect, on Web and Flutter (`KInputOtp`, `KRadioGroup`, `KSegmentedControl`, `KTextarea`). Picker and SegmentedControl visual acceptance pending |
| Overlays     | Tooltip, Popover, Dialog, AlertDialog, Drawer, BottomSheet                                                                                                                   | Popover, Dialog, AlertDialog, ResponsiveDrawer, BottomSheet on Web and Flutter. Tooltip not built as a K component                                                      |
| Navigation   | Link, Tabs, Breadcrumb, NavigationMenu, Sidebar, NavigationItem/Section, BottomNavigation, Pagination                                                                        | All listed on Web and Flutter: Link, Tabs, Breadcrumb, NavigationMenu, Sidebar, BottomNavigation as `KMobileAppBar`, Pagination, plus `KBackButton` (Decision 0012)     |
| Data Display | Card, Badge, Avatar, Attachment, Carousel, Kbd, List/ListItem, DescriptionList, Table, Accordion, Charts, Timeline, Gantt, Orbit                                             | All listed except DescriptionList, on Web and Flutter; List/ListItem as `KList`/`KListItem` (Decision 0012)                                                             |
| Feedback     | Alert, Toast, Progress, Spinner, Skeleton, EmptyState                                                                                                                        | Alert, Toast, Progress, Spinner, Skeleton on Web and Flutter; sound and haptics providers (Decision 0013). EmptyState not built                                         |
| Patterns     | Toolbar, FilterBar/FilterChip, DataTable, Questionnaire, PageHeader, AppShell, DetailInspector                                                                               | Toolbar, FilterBar, FilterChip, DataTable, Questionnaire, `KPageHeader`, `KAppShell`, SettingsPage on Web and Flutter. DetailInspector not built                        |

NumberInput, FileUpload, TreeView and CommandPalette are deferred
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

RobotHead recovery (10 November 2026): `KRobotHead` is restored from the preserved
local working state and exported for Web and Flutter. Four shapes, nine states,
consumer tracking/reaction events and optional audio input are available. See the
[RobotHead contract](components/robot-head.md) and matching `Data display/RobotHead`
gallery fixtures. Native performance optimization and renewed visual acceptance
are separate from restoring the existing component.

Email draft review (12 November 2026): Web and Flutter export the controlled, directly editable `KAgentEmailDraft` for sender, recipients, subject, Markdown and attachments. It emits host callbacks and performs no provider operation. `draftId` scopes disclosure state; delivery, validation, attachment source selection and upload remain host-owned. Storybook and Widgetbook share fixture IDs `agent-email-draft`, `agent-email-draft-validation`, `agent-email-draft-sending`, `agent-email-draft-sent` and `agent-email-draft-discarded`. The Web composition is accepted; Widgetbook visual parity is under active review. There is no preview/edit mode switch. Existing input and editor defaults are preserved by opt-in inline/prose variants. Targeted contract, editing and layout tests cover both implementations; final gallery evidence is recorded in the consuming Assist phase plan. Consumer integration, real sending and publication remain pending separate acceptance.

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

The current Rapid slice delivers the basic component families documented in
[basic components](components/basic-components.md). Compare matching fixtures at
phone/tablet/desktop widths, densities, themes and 200% text. Run affected
native/browser checks and record omissions before human visual acceptance.
