import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'button_fixtures.dart';
import 'compact_tool_activity_fixture.dart';
import 'login_showcase.dart';
import 'dashboard_shell_fixture.dart';
import 'chart_fixture.dart';
import 'chart_family_fixture.dart';
import 'candlestick_fixture.dart';
import 'timeline_fixture.dart';
import 'gantt_fixture.dart';
import 'action_fixtures.dart';
import 'context_menu_fixture.dart';
import 'form_fixtures.dart';
import 'textarea_fixture.dart';
import 'dictation_fixture.dart';
import 'radio_fixture.dart';
import 'table_fixtures.dart';
import 'data_table_fixtures.dart';
import 'data_table_overflow_fixture.dart';
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
import 'chat_composer_fixture.dart';
import 'ask_tools_fixture.dart';
import 'workflow_fixture.dart';
import 'editor_fixtures.dart';
import 'command_palette_fixture.dart';
import 'animated_icon_fixture.dart';
import 'theme_switcher_fixture.dart';
import 'user_menu_fixture.dart';
import 'notification_fixture.dart';
import 'orbit_fixture.dart';
import 'activity_fixture.dart';

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
          name: 'Showcase',
          children: [
            WidgetbookFolder(
              name: 'Dashboard App Shell',
              children: [
                WidgetbookUseCase(
                  name: 'Workspace',
                  builder: (_) => const DashboardShellFixture(),
                ),
                WidgetbookUseCase(
                  name: 'Expanded',
                  builder: (_) => const DashboardShellFixture(
                    initialMode: KSidebarMode.expanded,
                  ),
                ),
                WidgetbookUseCase(
                  name: 'With inspector',
                  builder: (_) =>
                      const DashboardShellFixture(initialInspector: true),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Login',
              children: [
                WidgetbookUseCase(
                  name: 'Assetry',
                  builder: (_) => const LoginShowcase(),
                ),
              ],
            ),
          ],
        ),
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
              name: 'Orbit',
              children: [
                WidgetbookUseCase(
                  name: 'orbit-team-projects',
                  builder: (_) => const OrbitFixture(),
                ),
                WidgetbookUseCase(
                  name: 'orbit-communication',
                  builder: (_) => const OrbitFixture(communication: true),
                ),
                WidgetbookUseCase(
                  name: 'orbit-deterministic',
                  builder: (_) => const OrbitFixture(freeze: true),
                ),
                WidgetbookUseCase(
                  name: 'orbit-deep-hierarchy',
                  builder: (_) => const OrbitFixture(deep: true),
                ),
                WidgetbookUseCase(
                  name: 'orbit-adaptive-spacing',
                  builder: (_) => const OrbitFixture(spacing: true),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Gantt',
              children: [
                WidgetbookUseCase(
                  name: 'gantt-reference',
                  builder: (_) => const GanttFixture(),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Timeline',
              children: [
                WidgetbookUseCase(
                  name: 'timeline-reference',
                  builder: (_) => const TimelineFixture(),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Charts',
              children: [
                for (final variant in [
                  'bar',
                  'bar-horizontal',
                  'bar-stacked',
                  'area',
                  'area-stacked',
                  'donut',
                  'pie',
                ])
                  WidgetbookUseCase(
                    name: 'chart-$variant',
                    builder: (_) => ChartFamilyFixture(variant: variant),
                  ),
                WidgetbookUseCase(
                  name: 'chart-candlestick',
                  builder: (_) => const CandlestickFixture(),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'LineChart',
              children: [
                WidgetbookUseCase(
                  name: 'chart-line-reference',
                  builder: (_) => const ChartFixture(),
                ),
                for (final scenario in ['empty', 'gaps', 'large'])
                  WidgetbookUseCase(
                    name: 'chart-line-$scenario',
                    builder: (_) => ChartFixture(scenario: scenario),
                  ),
              ],
            ),
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
              name: 'CommandPalette',
              children: [
                WidgetbookUseCase(
                  name: 'command-palette-actions',
                  builder: (_) => const CommandPaletteFixture(),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'UserMenu',
              children: [
                WidgetbookUseCase(
                  name: 'user-menu-account',
                  builder: (_) => const UserMenuFixture(),
                ),
                WidgetbookUseCase(
                  name: 'user-menu-long-identity',
                  builder: (_) => const UserMenuFixture(longIdentity: true),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'ThemeSwitcher',
              children: [
                WidgetbookUseCase(
                  name: 'theme-switcher-appearance',
                  builder: (_) => const ThemeSwitcherFixture(),
                ),
              ],
            ),
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
            WidgetbookFolder(
              name: 'Toast',
              children: [
                WidgetbookUseCase(
                  name: 'toast-notification',
                  builder: (_) => const NotificationFixture(),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Snackbar',
              children: [
                WidgetbookUseCase(
                  name: 'snackbar-message',
                  builder: (_) => const NotificationFixture(snackbar: true),
                ),
              ],
            ),
            for (final entry in const [
              ('Progress', 'progress-states', 'progress'),
              ('Skeleton', 'skeleton-loading', 'skeleton'),
              ('Spinner', 'spinner-loading', 'spinner'),
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
            WidgetbookFolder(
              name: 'Dictation',
              children: [
                WidgetbookUseCase(
                  name: 'dictation-controls',
                  builder: (_) => const DictationFixture(),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Textarea',
              children: [
                WidgetbookUseCase(
                  name: 'textarea-states',
                  builder: (_) => const TextareaFixture(),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Editors',
              children: [
                WidgetbookUseCase(
                  name: 'markdown',
                  builder: (_) =>
                      const EditorFixture(markdown: true, dictation: true),
                ),
                WidgetbookUseCase(
                  name: 'markdown-mobile',
                  builder: (_) => const EditorFixture(
                    markdown: true,
                    mobile: true,
                    dictation: true,
                  ),
                ),
                WidgetbookUseCase(
                  name: 'markdown-editor-dictation',
                  builder: (_) =>
                      const EditorFixture(markdown: true, dictation: true),
                ),
                WidgetbookUseCase(
                  name: 'code',
                  builder: (_) => const EditorFixture(markdown: false),
                ),
                WidgetbookUseCase(
                  name: 'code-mobile',
                  builder: (_) =>
                      const EditorFixture(markdown: false, mobile: true),
                ),
              ],
            ),
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
              name: 'RadioGroup',
              children: [
                WidgetbookUseCase(
                  name: 'radio-group-options',
                  builder: (context) => const RadioFixture(),
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
                WidgetbookUseCase(
                  name: 'select-multiple',
                  builder: (context) => const MultiSelectFixture(),
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
              name: 'Workflow',
              children: [
                WidgetbookUseCase(
                  name: 'workflow-responsive',
                  builder: (context) => WorkflowFixture(
                    presentation: context.knobs.object
                        .dropdown<KWorkflowPresentation>(
                          label: 'Presentation',
                          options: KWorkflowPresentation.values,
                          initialOption: KWorkflowPresentation.auto,
                          labelBuilder: (value) => value.name,
                        ),
                    showTechnicalEventsInCompact: context.knobs.boolean(
                      label: 'Show technical events in compact',
                      initialValue: false,
                    ),
                  ),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'AgentUI',
              children: [
                WidgetbookUseCase(
                  name: 'chat-composer-controls',
                  builder: (_) => const ChatComposerFixture(),
                ),
                WidgetbookUseCase(
                  name: 'chat-composer-mobile',
                  builder: (_) => const ChatComposerFixture(mobile: true),
                ),
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
                  name: 'agent-ui-compact-tools',
                  builder: (_) => const CompactToolActivityFixture(),
                ),
                WidgetbookUseCase(
                  name: 'agent-ui-compact-tools-phone',
                  builder: (_) => const CompactToolActivityFixture(phone: true),
                ),
                WidgetbookUseCase(
                  name: 'agent-ui-project-selection',
                  builder: (_) =>
                      const CompactToolActivityFixture(question: true),
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
                WidgetbookUseCase(
                  name: 'agent-ui-text-question',
                  builder: (_) => const AskToolsFixture(
                    kind: AskToolsFixtureKind.textQuestion,
                  ),
                ),
                WidgetbookUseCase(
                  name: 'agent-ui-multiple-choice',
                  builder: (_) => const AskToolsFixture(
                    kind: AskToolsFixtureKind.multipleChoice,
                  ),
                ),
                WidgetbookUseCase(
                  name: 'agent-ui-confirmation',
                  builder: (_) => const AskToolsFixture(
                    kind: AskToolsFixtureKind.confirmation,
                  ),
                ),
                WidgetbookUseCase(
                  name: 'agent-ui-form',
                  builder: (_) =>
                      const AskToolsFixture(kind: AskToolsFixtureKind.form),
                ),
                WidgetbookUseCase(
                  name: 'agent-ui-external-action',
                  builder: (_) => const AskToolsFixture(
                    kind: AskToolsFixtureKind.externalAction,
                  ),
                ),
                WidgetbookUseCase(
                  name: 'agent-ui-attachment-request',
                  builder: (_) => const AskToolsFixture(
                    kind: AskToolsFixtureKind.attachmentRequest,
                  ),
                ),
                WidgetbookUseCase(
                  name: 'agent-ui-ask-tools',
                  builder: (_) => const AskToolsFixture(),
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
              name: 'Activity',
              children: [
                WidgetbookUseCase(
                  name: 'activity-completed',
                  builder: (_) => const ActivityFixture(),
                ),
                WidgetbookUseCase(
                  name: 'activity-phone',
                  builder: (_) => const ActivityFixture(phone: true),
                ),
                WidgetbookUseCase(
                  name: 'activity-empty',
                  builder: (_) => const ActivityFixture(empty: true),
                ),
                WidgetbookUseCase(
                  name: 'activity-day-status',
                  builder: (_) => const ActivityFixture(statusView: true),
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
                  name: 'data-table-virtual-headers',
                  builder: (_) =>
                      const DataTableVirtualFixture(showHeader: true),
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
                  name: 'data-table-overflow',
                  builder: (_) => const DataTableOverflowFixture(),
                ),
                WidgetbookUseCase(
                  name: 'data-table-headers',
                  builder: (_) => const DataTableFixture(showHeader: true),
                ),
                WidgetbookUseCase(
                  name: 'data-table-grouped-headers',
                  builder: (_) =>
                      const DataTableFixture(grouped: true, showHeader: true),
                ),
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
              name: 'AnimatedIcon',
              children: [
                WidgetbookUseCase(
                  name: 'animated-icon-morphing',
                  builder: (_) => const AnimatedIconFixture(),
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Link',
              children: [
                WidgetbookUseCase(
                  name: 'link-variants',
                  builder: (_) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const KText('Links', variant: KTextVariant.heading4),
                        const SizedBox(height: 16),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('Read the '),
                            KLink(
                              label: 'component documentation',
                              onPressed: () {},
                            ),
                            const Text(' for details.'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        KLink(
                          label: 'Standalone action',
                          variant: KLinkVariant.standalone,
                          onPressed: () {},
                        ),
                        KLink(
                          label: 'External resource',
                          variant: KLinkVariant.standalone,
                          external: true,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
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
