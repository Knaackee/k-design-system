# Basic components

Alert, AlertDialog, Attachment, Avatar, Badge, Breadcrumb, Carousel, Drawer,
InputOTP, Kbd, NavigationMenu, Pagination, Popover, Progress, Questionnaire,
Skeleton, Slider, Spinner, Switch, Tabs and Toast are available from the Web and
Flutter UI packages. Their matching gallery fixtures are the visual contract for
equal theme, density, text scale and viewport.

Consumers own all product content and side effects. Components accept custom
labels, icons or widgets and emit activation, selection, confirmation or index
changes without owning navigation, persistence, upload work or application data.

- Alert supports neutral, info, success, warning and error tones, optional icon,
  description and action.
- AlertDialog composes the public dialog, provides localized default actions and
  accepts custom labels, media and action content. It prevents incidental
  outside dismissal.
- Attachment supports media, description, actions, normalized progress from 0
  through 1, size and upload state. Its optional loading indicator has a token
  styled spinner default and can be replaced by consumer content. Activation is
  optional.
- Avatar supports configurable images, derived or custom fallback content,
  status content, three sizes and overlapping groups.
- Badge supports primary, secondary, outline, ghost and destructive variants
  with optional leading and trailing content.
- Breadcrumb marks the final item as current and leaves routing to callbacks or
  links.
- Carousel supports mouse, touch, stylus and trackpad paging, configurable
  previous/next controls, keyboard arrows and index-change callbacks. Consumers
  can place interactive media or a lightbox trigger inside each slide.
- Responsive Drawer presents the same consumer content as a side panel on wide
  viewports and a bottom sheet on compact viewports. Its breakpoint, side,
  labels, actions and dismissal behavior are configurable.
- InputOTP keeps one accessible input while rendering configurable segmented
  slots, separators, length, validation and numeric or text entry.
- Kbd and KbdGroup display configurable shortcut content.
- NavigationMenu, Pagination and Tabs expose consumer-owned items, labels,
  active state and change callbacks without owning routing.
- Popover accepts arbitrary trigger and panel content. Progress, Skeleton and
  Spinner expose loading and feedback states with consumer-owned labels.
- Questionnaire accepts arbitrary step content, navigation labels and lifecycle
  callbacks. Slider and Switch are controlled inputs. Toast accepts arbitrary
  title, description, actions and dismissal behavior.

Accessibility labels are consumer-configurable. Text remains visible at 200%
scale; compact Alerts move their action below the message rather than clipping.
