import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'button_fixtures.dart';
import 'action_fixtures.dart';
import 'context_menu_fixture.dart';
import 'form_fixtures.dart';
import 'table_fixtures.dart';
import 'data_table_fixtures.dart';
import 'data_table_cells_fixture.dart';
import 'disclosure_fixtures.dart';
import 'overlay_fixtures.dart';
import 'currency_fixtures.dart';
import 'data_table_virtual_fixture.dart';
import 'kanban_fixtures.dart';
import 'calendar_fixtures.dart';
import 'picker_fixtures.dart';
import 'symbol_picker_fixtures.dart';
import 'typography_fixtures.dart';
import 'color_fixtures.dart';
import 'foundation_fixtures.dart';
import 'configuration_addon.dart';
import 'gallery_navigation.dart';
import 'additional_primitive_fixtures.dart';
import 'basic_component_fixtures.dart';
import 'extended_component_fixtures.dart';
import 'sidebar_fixtures.dart';
import 'mobile_app_bar_fixture.dart';
import 'settings_page_fixtures.dart';
import 'agent_ui_fixtures.dart';

export 'foundation_fixtures.dart' show buildCardVariants, buildSurfaceTones;
export 'configuration_addon.dart';

void main() => runApp(const KDesignWidgetbook());

class KDesignWidgetbook extends StatelessWidget {
  const KDesignWidgetbook({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      lightTheme: kDesignTheme(),
      darkTheme: kDesignTheme(brightness: Brightness.dark),
      header: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('K Design System'),
      ),
      addons: [
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Orbit Light', data: kDesignTheme()),
            WidgetbookTheme(
              name: 'Orbit Dark',
              data: kDesignTheme(brightness: Brightness.dark),
            ),
            WidgetbookTheme(
              name: 'Reference Light',
              data: kDesignTheme(brand: KBrand.reference),
            ),
            WidgetbookTheme(
              name: 'Reference Dark',
              data: kDesignTheme(
                brand: KBrand.reference,
                brightness: Brightness.dark,
              ),
            ),
          ],
        ),
        ViewportAddon(const [
          ViewportData(
            name: 'Compact · 375',
            width: 375,
            height: 812,
            pixelRatio: 1,
            platform: TargetPlatform.android,
          ),
          ViewportData(
            name: 'Medium · 700',
            width: 700,
            height: 900,
            pixelRatio: 1,
            platform: TargetPlatform.android,
          ),
          ViewportData(
            name: 'Expanded · 1024',
            width: 1024,
            height: 900,
            pixelRatio: 1,
            platform: TargetPlatform.windows,
          ),
          ViewportData(
            name: 'Large · 1440',
            width: 1440,
            height: 1000,
            pixelRatio: 1,
            platform: TargetPlatform.windows,
          ),
          ViewportData(
            name: 'Extra large · 1680',
            width: 1680,
            height: 1050,
            pixelRatio: 1,
            platform: TargetPlatform.windows,
          ),
        ]),
        KDesignConfigurationAddon(),
        KLanguageAddon(),
        TextScaleAddon(initialScale: 1, min: 1, max: 2, divisions: 4),
      ],
      directories: sortGalleryNodes([
        WidgetbookCategory(
          name: 'Overlays',
          children: [
            WidgetbookFolder(
              name: 'Drawer',
              children: [
                WidgetbookUseCase(
                  name: 'drawer-responsive',
                  builder: (_) =>
                      const ExtendedComponentFixture(kind: 'drawer'),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Popover',
              children: [
                WidgetbookUseCase(
                  name: 'popover-content',
                  builder: (_) =>
                      const ExtendedComponentFixture(kind: 'popover'),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'AlertDialog',
              children: [
                WidgetbookUseCase(
                  name: 'alert-dialog-confirmation',
                  builder: (_) =>
                      const BasicComponentFixture(kind: 'alert-dialog'),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'BottomSheet',
              children: [
                WidgetbookUseCase(
                  name: 'bottom-sheet-modal',
                  builder: (_) => const OverlayFixture(sheet: true),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Dialog',
              children: [
                WidgetbookUseCase(
                  name: 'dialog-modal',
                  builder: (_) => const OverlayFixture(),
                ),
              ],
            ),
          ],
        ),
        WidgetbookCategory(
          name: 'Data display',
          children: [
            WidgetbookFolder(
              name: 'Kbd',
              children: [
                WidgetbookUseCase(
                  name: 'kbd-shortcuts',
                  builder: (_) => const ExtendedComponentFixture(kind: 'kbd'),
                ),
              ],
            ),
            for (final entry in const [
              ('Attachment', 'attachment-states', 'attachment'),
              ('Avatar', 'avatar-variants', 'avatar'),
              ('Badge', 'badge-variants', 'badge'),
              ('Carousel', 'carousel-slides', 'carousel'),
            ])
              WidgetbookFolder(
                name: entry.$1,
                children: [
                  WidgetbookUseCase(
                    name: entry.$2,
                    builder: (_) => BasicComponentFixture(kind: entry.$3),
                  ),
                ],
              ),
            WidgetbookFolder(
              name: 'Table',
              children: [
                WidgetbookUseCase(
                  name: 'table-basic',
                  builder: (context) => const TableFixture(),
                ),
                WidgetbookUseCase(
                  name: 'table-cells',
                  builder: (context) => const TableFixture(cells: true),
                ),
              ],
            ),
          ],
        ),
        WidgetbookCategory(
          name: 'Actions',
          children: [
            WidgetbookFolder(
              name: 'ContextMenu',
              children: [
                WidgetbookUseCase(
                  name: 'context-menu-actions',
                  builder: (_) => const ContextMenuFixture(),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'IconButton',
              children: [
                WidgetbookUseCase(
                  name: 'icon-button-actions',
                  builder: (context) => const ActionFixture(kind: 'icon'),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'MenuButton',
              children: [
                WidgetbookUseCase(
                  name: 'menu-button-actions',
                  builder: (context) => const ActionFixture(kind: 'menu'),
                ),
              ],
            ),
          ],
        ),
        WidgetbookCategory(
          name: 'Feedback',
          children: [
            for (final entry in const [
              ('Progress', 'progress-states', 'progress'),
              ('Skeleton', 'skeleton-loading', 'skeleton'),
              ('Spinner', 'spinner-loading', 'spinner'),
              ('Toast', 'toast-notification', 'toast'),
            ])
              WidgetbookFolder(
                name: entry.$1,
                children: [
                  WidgetbookUseCase(
                    name: entry.$2,
                    builder: (_) => ExtendedComponentFixture(kind: entry.$3),
                  ),
                ],
              ),
            WidgetbookFolder(
              name: 'Alert',
              children: [
                WidgetbookUseCase(
                  name: 'alert-states',
                  builder: (_) => const BasicComponentFixture(kind: 'alert'),
                ),
              ],
            ),
          ],
        ),
        WidgetbookCategory(
          name: 'Navigation',
          children: [
            WidgetbookFolder(
              name: 'MobileAppBar',
              children: [
                WidgetbookUseCase(
                  name: 'mobile-app-bar-floating-glass',
                  builder: (_) => const MobileAppBarFixture(),
                ),
                WidgetbookUseCase(
                  name: 'mobile-app-bar-fixed',
                  builder: (_) => const MobileAppBarFixture(
                    variant: KMobileAppBarVariant.fixed,
                  ),
                ),
                WidgetbookUseCase(
                  name: 'mobile-app-bar-action',
                  builder: (_) => const MobileAppBarFixture(
                    variant: KMobileAppBarVariant.action,
                  ),
                ),
                WidgetbookUseCase(
                  name: 'mobile-app-bar-floating-dock',
                  builder: (_) => const MobileAppBarFixture(
                    variant: KMobileAppBarVariant.floatingDock,
                  ),
                ),
                WidgetbookUseCase(
                  name: 'mobile-app-bar-labeled',
                  builder: (_) => const MobileAppBarFixture(
                    variant: KMobileAppBarVariant.labeled,
                  ),
                ),
                WidgetbookUseCase(
                  name: 'mobile-app-bar-collapsible',
                  builder: (_) => const MobileAppBarFixture(
                    variant: KMobileAppBarVariant.collapsible,
                  ),
                ),
                WidgetbookUseCase(
                  name: 'mobile-app-bar-contextual',
                  builder: (_) => const MobileAppBarFixture(
                    variant: KMobileAppBarVariant.contextual,
                  ),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Sidebar',
              children: [
                WidgetbookUseCase(
                  name: 'sidebar-expanded',
                  builder: (_) => const SidebarFixture(),
                ),
                WidgetbookUseCase(
                  name: 'sidebar-rail',
                  builder: (_) =>
                      const SidebarFixture(initialMode: KSidebarMode.rail),
                ),
                WidgetbookUseCase(
                  name: 'sidebar-settings',
                  builder: (_) => const SidebarFixture(settings: true),
                ),
                WidgetbookUseCase(
                  name: 'sidebar-in-drawer',
                  builder: (_) => const SidebarFixture(drawer: true),
                ),
              ],
            ),
            for (final entry in const [
              ('NavigationMenu', 'navigation-menu-links', 'navigation-menu'),
              ('Pagination', 'pagination-pages', 'pagination'),
              ('Tabs', 'tabs-panels', 'tabs'),
            ])
              WidgetbookFolder(
                name: entry.$1,
                children: [
                  WidgetbookUseCase(
                    name: entry.$2,
                    builder: (_) => ExtendedComponentFixture(kind: entry.$3),
                  ),
                ],
              ),
            WidgetbookFolder(
              name: 'Breadcrumb',
              children: [
                WidgetbookUseCase(
                  name: 'breadcrumb-navigation',
                  builder: (_) =>
                      const BasicComponentFixture(kind: 'breadcrumb'),
                ),
              ],
            ),
          ],
        ),
        WidgetbookCategory(
          name: 'Forms',
          children: [
            for (final entry in const [
              ('InputOTP', 'input-otp-code', 'otp'),
              ('Slider', 'slider-range', 'slider'),
              ('Switch', 'switch-toggle', 'switch'),
            ])
              WidgetbookFolder(
                name: entry.$1,
                children: [
                  WidgetbookUseCase(
                    name: entry.$2,
                    builder: (_) => ExtendedComponentFixture(kind: entry.$3),
                  ),
                ],
              ),
            WidgetbookFolder(
              name: 'EmojiPicker',
              children: [
                WidgetbookUseCase(
                  name: 'emoji-picker-reactions',
                  builder: (_) => const SymbolPickerFixture(emoji: true),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'IconPicker',
              children: [
                WidgetbookUseCase(
                  name: 'icon-picker-icons',
                  builder: (_) => const SymbolPickerFixture(),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'CurrencyInput',
              children: [
                WidgetbookUseCase(
                  name: 'currency-input-states',
                  builder: (_) => const CurrencyFixture(),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'DatePicker',
              children: [
                WidgetbookUseCase(
                  name: 'date-picker-states',
                  builder: (context) => buildPickerFixture(context, 'date'),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'TimePicker',
              children: [
                WidgetbookUseCase(
                  name: 'time-picker-states',
                  builder: (context) => buildPickerFixture(context, 'time'),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'DateTimePicker',
              children: [
                WidgetbookUseCase(
                  name: 'date-time-picker-states',
                  builder: (context) =>
                      buildPickerFixture(context, 'date-time'),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Field',
              children: [
                WidgetbookUseCase(
                  name: 'field-states',
                  builder: (context) => const FormFixture(kind: 'field'),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Input',
              children: [
                WidgetbookUseCase(
                  name: 'input-states',
                  builder: (context) => const FormFixture(kind: 'input'),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'SearchField',
              children: [
                WidgetbookUseCase(
                  name: 'search-field-states',
                  builder: (context) => const FormFixture(kind: 'search-field'),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Checkbox',
              children: [
                WidgetbookUseCase(
                  name: 'checkbox-states',
                  builder: (context) => const FormFixture(kind: 'checkbox'),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Select',
              children: [
                WidgetbookUseCase(
                  name: 'select-states',
                  builder: (context) => const FormFixture(kind: 'select'),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Combobox',
              children: [
                WidgetbookUseCase(
                  name: 'combobox-states',
                  builder: (context) => const FormFixture(kind: 'combobox'),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'FilterChip',
              children: [
                WidgetbookUseCase(
                  name: 'filter-chip-states',
                  builder: (context) => const FormFixture(kind: 'filter-chip'),
                ),
              ],
            ),
          ],
        ),
        WidgetbookCategory(
          name: 'Patterns',
          children: [
            WidgetbookFolder(
              name: 'AgentUI',
              children: [
                WidgetbookUseCase(
                  name: 'agent-ui-conversation',
                  builder: (_) => const AgentUiFixture(),
                ),
                WidgetbookUseCase(
                  name: 'agent-ui-messages',
                  builder: (context) => AgentUiFixture(
                    kind: AgentUiFixtureKind.messages,
                    metadataMode: context.knobs.object
                        .dropdown<KChatMessageMetadataMode>(
                          label: 'Message metadata',
                          options: KChatMessageMetadataMode.values,
                          initialOption: KChatMessageMetadataMode.grouped,
                          labelBuilder: (value) => value.name,
                        ),
                    showTimestamps: context.knobs.boolean(
                      label: 'Show timestamps',
                      initialValue: true,
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'agent-ui-tools',
                  builder: (_) =>
                      const AgentUiFixture(kind: AgentUiFixtureKind.tools),
                ),
                WidgetbookUseCase(
                  name: 'agent-ui-approval',
                  builder: (_) =>
                      const AgentUiFixture(kind: AgentUiFixtureKind.approval),
                ),
                WidgetbookUseCase(
                  name: 'agent-ui-question',
                  builder: (_) =>
                      const AgentUiFixture(kind: AgentUiFixtureKind.question),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'SettingsPage',
              children: [
                WidgetbookUseCase(
                  name: 'settings-page-responsive',
                  builder: (_) => const SettingsPageFixture(),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Questionnaire',
              children: [
                WidgetbookUseCase(
                  name: 'questionnaire-steps',
                  builder: (_) =>
                      const ExtendedComponentFixture(kind: 'questionnaire'),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Calendar',
              children: [
                WidgetbookUseCase(
                  name: 'calendar-day',
                  builder: (_) =>
                      const CalendarFixture(initialView: KCalendarView.day),
                ),
                WidgetbookUseCase(
                  name: 'calendar-three-day',
                  builder: (_) => const CalendarFixture(
                    initialView: KCalendarView.threeDay,
                  ),
                ),
                WidgetbookUseCase(
                  name: 'calendar-week',
                  builder: (_) => const CalendarFixture(),
                ),
                WidgetbookUseCase(
                  name: 'calendar-month',
                  builder: (_) =>
                      const CalendarFixture(initialView: KCalendarView.month),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Kanban',
              children: [
                WidgetbookUseCase(
                  name: 'kanban-board',
                  builder: (_) => const KanbanFixture(),
                ),
                WidgetbookUseCase(
                  name: 'kanban-selection',
                  builder: (_) => const KanbanFixture(selection: true),
                ),
                WidgetbookUseCase(
                  name: 'kanban-mobile',
                  builder: (_) => const KanbanFixture(),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'DataTableVirtual',
              children: [
                WidgetbookUseCase(
                  name: 'data-table-virtual',
                  builder: (_) => const DataTableVirtualFixture(),
                ),
                WidgetbookUseCase(
                  name: 'data-table-external',
                  builder: (_) => const DataTableVirtualFixture(external: true),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'DataTable',
              children: [
                WidgetbookUseCase(
                  name: 'data-table-cells',
                  builder: (_) => const DataTableCellsFixture(),
                ),
                WidgetbookUseCase(
                  name: 'data-table-rows',
                  builder: (context) => const DataTableFixture(),
                ),
                WidgetbookUseCase(
                  name: 'data-table-groups',
                  builder: (context) => const DataTableFixture(grouped: true),
                ),
                WidgetbookUseCase(
                  name: 'data-table-single-column',
                  builder: (context) =>
                      const DataTableFixture(grouped: true, singleColumn: true),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'FilterBar',
              children: [
                WidgetbookUseCase(
                  name: 'filter-bar-filters',
                  builder: (context) => const FormFixture(),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Toolbar',
              children: [
                WidgetbookUseCase(
                  name: 'toolbar-actions',
                  builder: (context) => const ActionFixture(),
                ),
              ],
            ),
          ],
        ),
        WidgetbookCategory(
          name: 'Primitives',
          children: [
            WidgetbookFolder(
              name: 'Accordion',
              children: [
                WidgetbookUseCase(
                  name: 'accordion-sections',
                  builder: (_) => const DisclosureFixture(accordion: true),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Disclosure',
              children: [
                WidgetbookUseCase(
                  name: 'disclosure-states',
                  builder: (_) => const DisclosureFixture(),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Container',
              children: [
                WidgetbookUseCase(
                  name: 'container-bounds',
                  builder: buildContainerBounds,
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Grid',
              children: [
                WidgetbookUseCase(
                  name: 'grid-responsive',
                  builder: buildGridResponsive,
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Icon',
              children: [
                WidgetbookUseCase(
                  name: 'icon-lucide',
                  builder: buildIconLucide,
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Separator',
              children: [
                WidgetbookUseCase(
                  name: 'separator-orientations',
                  builder: buildSeparatorOrientations,
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Button',
              children: [
                WidgetbookUseCase(
                  name: 'button-primary',
                  builder: buildButtonPrimary,
                ),
                WidgetbookUseCase(
                  name: 'button-variants',
                  builder: buildButtonVariants,
                ),
                WidgetbookUseCase(
                  name: 'button-states',
                  builder: buildButtonStates,
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Typography',
              children: [
                WidgetbookUseCase(
                  name: 'typography-primary',
                  builder: buildTypographyPrimary,
                ),
                WidgetbookUseCase(
                  name: 'typography-scale',
                  builder: buildTypographyScale,
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Colors',
              children: [
                WidgetbookUseCase(
                  name: 'colors-semantic-roles',
                  builder: buildSemanticColors,
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Shape',
              children: [
                WidgetbookUseCase(
                  name: 'shape-radius-scale',
                  builder: buildRadiusScale,
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Elevation',
              children: [
                WidgetbookUseCase(
                  name: 'elevation-levels',
                  builder: buildElevationLevels,
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Surface',
              children: [
                WidgetbookUseCase(
                  name: 'surface-tones',
                  builder: buildSurfaceTones,
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Layout',
              children: [
                WidgetbookUseCase(
                  name: 'layout-composition',
                  builder: buildLayoutComposition,
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Card',
              children: [
                WidgetbookUseCase(
                  name: 'card-variants',
                  builder: buildCardVariants,
                ),
              ],
            ),
          ],
        ),
      ]),
    );
  }
}
