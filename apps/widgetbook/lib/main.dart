import 'user_dashboard_review.dart';
import 'onzeit_overhaul_gallery.dart';
import 'booking_page_management_fixture.dart';
import 'offer_overview_fixture.dart';
import 'catalog_editor_fixture.dart';
import 'home_overview_fixture.dart';
import 'onboarding_navigation_fixture.dart';
import 'plan_picker_fixture.dart';
import 'sortable_tree_fixture.dart';
import 'qr_code_fixture.dart';
import 'showcase_grid_fixture.dart';
import 'celebration_fixture.dart';
import 'image_cropper_fixture.dart';
import 'payment_setup_fixture.dart';
import 'files_home_fixture.dart';
import 'screen_switcher_prototype.dart';
import 'cover_flow_fixture.dart';
import 'agent_switcher_settings_fixture.dart';
import 'call_bar_fixture.dart';
import 'screen_switcher_reference_fixture.dart';
import 'browser_permissions_fixture.dart';
import 'browser_permission_ask_fixture.dart';
import 'browser_cards_fixture.dart';
import 'personal_agent_browser_fixture.dart';
import 'agent_cursor_fixture.dart';
import 'audio_edge_glow_fixture.dart';
import 'activity_dot_fixture.dart';
import 'files_fixture.dart';
import 'chat_presentations_fixture.dart';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'motion_fixture.dart';
import 'back_button_fixture.dart';
import 'geometry_parity_fixture.dart';
import 'package:widgetbook/widgetbook.dart';

import 'button_fixtures.dart';
import 'chat_bubble_fixture.dart';
import 'neutral_design_fixture.dart';
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
import 'adaptive_dialog_fixture.dart';
import 'sheet_scroll_handoff_fixture.dart';
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
import 'admin_workspace_fixture.dart';
import 'settings_grouped_fixture.dart';
import 'management_overview_fixture.dart';
import 'avatar_editor_fixture.dart';
import 'usage_details_fixture.dart';
import 'agent_ui_fixtures.dart';
import 'agent_question_dictation_fixture.dart';
import 'chat_composer_fixture.dart';
import 'agent_chat_switcher_fixture.dart';
import 'agent_chat_workspace_fixture.dart';
import 'web_search_fixture.dart';
import 'foley_sounds_fixture.dart';
import 'sound_onboarding_fixture.dart';
import 'agent_switcher_variants_fixture.dart';
import 'ask_tools_fixture.dart';
import 'workflow_fixture.dart';
import 'workflow_session_fixture.dart';
import 'editor_fixtures.dart';
import 'command_palette_fixture.dart';
import 'animated_icon_fixture.dart';
import 'theme_switcher_fixture.dart';
import 'language_switcher_fixture.dart';
import 'user_menu_fixture.dart';
import 'notification_fixture.dart';
import 'orbit_fixture.dart';
import 'activity_fixture.dart';
import 'dicebear_avatar_fixture.dart';
import 'integrations_fixture.dart';
import 'map_fixture.dart';
import 'map_day_fixture.dart';
import 'map_location_picker_fixture.dart';
import 'map_overlays_fixture.dart';
import 'map_zone_editor_fixture.dart';

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
          Viewports.none,
          ViewportData(
            name: 'Small phone · 320',
            width: 320,
            height: 568,
            pixelRatio: 1,
            platform: TargetPlatform.android,
          ),
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
            name: 'Phone · 390',
            width: 390,
            height: 844,
            pixelRatio: 1,
            platform: TargetPlatform.android,
          ),
          ViewportData(
            name: 'Large phone · 430',
            width: 430,
            height: 932,
            pixelRatio: 1,
            platform: TargetPlatform.android,
          ),
          ViewportData(
            name: 'Tablet · 768',
            width: 768,
            height: 1024,
            pixelRatio: 1,
            platform: TargetPlatform.android,
          ),
          ViewportData(
            name: 'Desktop · 1280',
            width: 1280,
            height: 900,
            pixelRatio: 1,
            platform: TargetPlatform.windows,
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
          ViewportData(
            name: 'Full HD · 1920',
            width: 1920,
            height: 1080,
            pixelRatio: 1,
            platform: TargetPlatform.windows,
          ),
        ]),
        KDesignConfigurationAddon(),
        KLanguageAddon(),
        TextScaleAddon(initialScale: 1, min: 1, max: 3, divisions: 8),
      ],
      directories: galleryDirectories(),
    );
  }
}

/// Every gallery node, sorted. Shared by the app and the phone gate test.
List<WidgetbookNode> galleryDirectories() => sortGalleryNodes([
  WidgetbookCategory(
    name: 'Review',
    children: [
      ...onzeitOverhaulGallery().children!,
      WidgetbookComponent(
        name: 'GeometryParity',
        useCases: [
          WidgetbookUseCase(
            name: 'reference',
            builder: (_) => const GeometryParityFixture(),
          ),
        ],
      ),
    ],
  ),
  WidgetbookCategory(
    name: 'Maps',
    children: [
      WidgetbookFolder(
        name: 'Map Overlays',
        children: [
          WidgetbookUseCase(name: 'Pins', builder: buildMapOverlaysPins),
          WidgetbookUseCase(
            name: 'Logo Pins',
            builder: buildMapOverlaysLogoPins,
          ),
          WidgetbookUseCase(
            name: 'Custom Pins',
            builder: buildMapOverlaysCustomPins,
          ),
          WidgetbookUseCase(name: 'Routes', builder: buildMapOverlaysRoutes),
          WidgetbookUseCase(
            name: 'Pins And Route',
            builder: buildMapOverlaysPinsAndRoute,
          ),
          WidgetbookUseCase(
            name: 'Traffic Segments',
            builder: buildMapOverlaysTrafficSegments,
          ),
          WidgetbookUseCase(
            name: 'Draggable Pins',
            builder: buildMapOverlaysDraggablePins,
          ),
          WidgetbookUseCase(
            name: 'Long Press Pins',
            builder: buildMapOverlaysLongPressPins,
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'Day view',
        children: [
          WidgetbookUseCase(name: 'Day', builder: buildMapDayDesktop),
          WidgetbookUseCase(name: 'Tablet', builder: buildMapDayTablet),
          WidgetbookUseCase(name: 'Mobile', builder: buildMapDayMobile),
        ],
      ),
      WidgetbookFolder(
        name: 'Location Picker',
        children: [
          WidgetbookUseCase(
            name: 'Desktop',
            builder: buildMapLocationPickerDesktop,
          ),
          WidgetbookUseCase(
            name: 'Mobile',
            builder: buildMapLocationPickerMobile,
          ),
          WidgetbookUseCase(
            name: 'Custom leading',
            builder: buildMapLocationPickerCustomLeading,
          ),
          WidgetbookUseCase(
            name: 'Bare pin',
            builder: buildMapLocationPickerBarePin,
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'Zone Editor',
        children: [
          WidgetbookUseCase(
            name: 'Desktop',
            builder: buildMapZoneEditorDesktop,
          ),
          WidgetbookUseCase(name: 'Mobile', builder: buildMapZoneEditorMobile),
          WidgetbookUseCase(
            name: 'Fullscreen · Desktop',
            builder: buildMapZoneEditorFullscreenDesktop,
          ),
          WidgetbookUseCase(
            name: 'Fullscreen · Mobile',
            builder: buildMapZoneEditorFullscreenMobile,
          ),
          WidgetbookUseCase(
            name: 'Fullscreen · Empty',
            builder: buildMapZoneEditorFullscreenEmpty,
          ),
          WidgetbookUseCase(
            name: 'Areas only',
            builder: buildMapZoneEditorAreasOnly,
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'Map',
        children: [
          WidgetbookUseCase(name: 'Map', builder: MapFixtureSession().build),
        ],
      ),
    ],
  ),
  WidgetbookCategory(
    name: 'Components',
    children: [
      WidgetbookFolder(
        name: 'AgentCursor',
        children: [
          for (final variant in [
            'Default',
            'WithAvatar',
            'Clicking',
            'DarkSurface',
            'ReducedMotion',
            'Hidden',
          ])
            WidgetbookUseCase(
              name: variant,
              builder: (_) => AgentCursorFixture(variant: variant),
            ),
        ],
      ),
    ],
  ),
  WidgetbookCategory(
    name: 'Showcase',
    children: [
      WidgetbookFolder(
        name: 'Files',
        children: [
          WidgetbookUseCase(
            name: 'files-home',
            builder: (_) => const FilesHomeFixture(),
          ),
          WidgetbookUseCase(
            name: 'files-home-empty',
            builder: (_) => const FilesHomeFixture(empty: true),
          ),
          WidgetbookUseCase(
            name: 'files-workspace',
            builder: (_) => const FilesHomeFixture(workspace: true),
          ),
          WidgetbookUseCase(
            name: 'files-review',
            builder: (_) => const FilesFixture(),
          ),
          WidgetbookUseCase(
            name: 'tab-strip-review',
            builder: (_) => const TabStripFixture(),
          ),
          WidgetbookUseCase(
            name: 'storage-review',
            builder: (_) => const FilesStorageFixture(),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'Dashboard App Shell',
        children: [
          WidgetbookUseCase(
            name: 'Workspace',
            builder: (_) => const DashboardShellFixture(),
          ),
          WidgetbookUseCase(
            name: 'Expanded',
            builder: (_) =>
                const DashboardShellFixture(initialMode: KSidebarMode.expanded),
          ),
          WidgetbookUseCase(
            name: 'With inspector',
            builder: (_) => const DashboardShellFixture(initialInspector: true),
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
            builder: (_) => const ExtendedComponentFixture(kind: 'drawer'),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'Popover',
        children: [
          WidgetbookUseCase(
            name: 'popover-content',
            builder: (_) => const ExtendedComponentFixture(kind: 'popover'),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'AlertDialog',
        children: [
          WidgetbookUseCase(
            name: 'alert-dialog-confirmation',
            builder: (_) => const BasicComponentFixture(kind: 'alert-dialog'),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'BottomSheet',
        children: [
          WidgetbookUseCase(
            name: 'bottom-sheet-scroll-handoff',
            builder: (_) => const SheetScrollHandoffFixture(),
          ),
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
            name: 'adaptive-dialog',
            builder: (_) => const AdaptiveDialogFixture(),
          ),
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
        name: 'DiceBear Avatar',
        children: [
          WidgetbookUseCase(
            name: 'dicebear-avatar-animation',
            builder: (context) {
              final styleId = context.knobs.object.dropdown<String>(
                label: 'Style',
                options: kDiceBearAnimatedStyleIds,
                initialOption: 'critters',
              );
              final speed = context.knobs.object.dropdown<String>(
                label: 'Animation speed',
                options: const [
                  'none',
                  'slowest',
                  'slow',
                  'medium',
                  'fast',
                  'fastest',
                ],
                initialOption: 'fastest',
              );
              try {
                return DiceBearAvatarFixture(
                  styleId: styleId,
                  seed: context.knobs.string(
                    label: 'Seed',
                    initialValue: 'K Design System',
                  ),
                  options: {
                    ...parseDiceBearOptions(
                      context.knobs.string(
                        label: 'Options JSON',
                        initialValue: '{}',
                      ),
                    ),
                    'animationVariant': [speed],
                  },
                  motionPaused: context.knobs.boolean(
                    label: 'Paused',
                    initialValue: false,
                  ),
                );
              } on FormatException catch (error) {
                return Center(child: KText(error.message));
              }
            },
          ),
          WidgetbookUseCase(
            name: 'dicebear-avatar-playground',
            builder: (context) {
              final styleId = context.knobs.object.dropdown<String>(
                label: 'Style',
                options: kDiceBearStyleIds,
                initialOption: 'adventurer',
              );
              final seed = context.knobs.string(
                label: 'Seed',
                initialValue: 'K Design System',
              );
              final optionsSource = context.knobs.string(
                label: 'Options JSON',
                initialValue: '{}',
              );
              final size = context.knobs.object.dropdown<KAvatarSize>(
                label: 'Size',
                options: KAvatarSize.values,
                initialOption: KAvatarSize.large,
                labelBuilder: (value) => value.name,
              );
              try {
                return DiceBearAvatarFixture(
                  styleId: styleId,
                  seed: seed,
                  options: parseDiceBearOptions(optionsSource),
                  size: size,
                );
              } on FormatException catch (error) {
                return Center(child: Text(error.message));
              }
            },
          ),
          WidgetbookUseCase(
            name: 'dicebear-avatar-catalogue',
            builder: (_) => const DiceBearAvatarCatalogueFixture(),
          ),
        ],
      ),
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
        name: 'Image cropper',
        children: [
          WidgetbookUseCase(
            name: 'image-cropper-avatar',
            builder: (_) => const ImageCropperFixture(),
          ),
          WidgetbookUseCase(
            name: 'image-cropper-square',
            builder: (_) =>
                const ImageCropperFixture(shape: KImageCropShape.square),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'ProgressDots',
        children: [
          WidgetbookUseCase(
            name: 'onboarding-navigation-touch',
            builder: (_) => const OnboardingNavigationFixture(),
          ),
          WidgetbookUseCase(
            name: 'steps',
            builder: (context) => Center(
              child: KProgressDots(
                count: 4,
                activeIndex: context.knobs.int.slider(
                  label: 'Active index',
                  initialValue: 1,
                  min: 0,
                  max: 3,
                ),
                label: 'Einrichtung',
              ),
            ),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'QrCode',
        children: [
          WidgetbookUseCase(
            name: 'qr-code-playground',
            builder: (_) => const QrCodeFixture(),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'CoverFlow',
        children: [
          WidgetbookUseCase(
            name: 'cover-flow-reveal',
            builder: (_) => const CoverFlowFixture(reveal: true),
          ),
          WidgetbookUseCase(
            name: 'cover-flow-characters',
            builder: (_) => const CoverFlowFixture(),
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
        name: 'LanguageSwitcher',
        children: [
          WidgetbookUseCase(
            name: 'language-switcher-default',
            builder: (_) => const LanguageSwitcherFixture(),
          ),
          WidgetbookUseCase(
            name: 'language-switcher-flags',
            builder: (_) => const LanguageSwitcherFixture(flags: true),
          ),
          WidgetbookUseCase(
            name: 'language-switcher-disabled',
            builder: (_) => const LanguageSwitcherFixture(disabled: true),
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
        name: 'Activity dot',
        children: [
          WidgetbookUseCase(
            name: 'activity-dot-playground',
            builder: buildActivityDotPlayground,
          ),
          WidgetbookUseCase(
            name: 'agents-collapsed-activity',
            builder: buildCollapsedAgentsActivity,
          ),
          WidgetbookUseCase(
            name: 'activity-dot-states',
            builder: (_) => const ActivityDotStatesFixture(),
          ),
          WidgetbookUseCase(
            name: 'activity-dot-consumer-theme',
            builder: buildActivityDotConsumerTheme,
          ),
          WidgetbookUseCase(
            name: 'activity-dot-reduced-motion',
            builder: (_) => const Center(
              child: KActivityDot(
                state: KActivityDotState.working,
                label: 'Working activity',
                size: 16,
                coreSize: 8,
                ringWidth: 2,
                reducedMotion: true,
              ),
            ),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'Audio edge glow',
        children: [
          WidgetbookUseCase(
            name: 'audio-edge-glow-quiet',
            builder: (_) => const AudioEdgeGlowFixture(),
          ),
          WidgetbookUseCase(
            name: 'audio-edge-glow-speaking',
            builder: (_) => const AudioEdgeGlowFixture(audioLevel: .35),
          ),
          WidgetbookUseCase(
            name: 'audio-edge-glow-processing',
            builder: (_) => const AudioEdgeGlowFixture(
              state: KAudioEdgeGlowState.processing,
            ),
          ),
          WidgetbookUseCase(
            name: 'audio-edge-glow-reduced-motion',
            builder: (_) => const AudioEdgeGlowFixture(
              audioLevel: .35,
              reducedMotion: true,
            ),
          ),
          WidgetbookUseCase(
            name: 'audio-edge-glow-inactive',
            builder: (_) =>
                const AudioEdgeGlowFixture(state: KAudioEdgeGlowState.inactive),
          ),
        ],
      ),
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
        name: 'BackButton',
        children: [
          WidgetbookUseCase(
            name: 'back-button',
            builder: (_) => const BackButtonFixture(),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'ScreenSwitcher',
        children: [
          WidgetbookUseCase(
            name: 'screen-switcher-prototype',
            builder: (_) => const ScreenSwitcherPrototypeDemo(),
          ),
          WidgetbookUseCase(
            name: 'screen-switcher-reference',
            builder: (_) => const ScreenSwitcherReferenceFixture(),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'MobileAppBar',
        children: [
          WidgetbookUseCase(
            name: 'mobile-app-bar-floating-glass',
            builder: (_) => const MobileAppBarFixture(),
          ),
          WidgetbookUseCase(
            name: 'mobile-app-bar-fixed',
            builder: (_) =>
                const MobileAppBarFixture(variant: KMobileAppBarVariant.fixed),
          ),
          WidgetbookUseCase(
            name: 'mobile-app-bar-fixed-line',
            builder: (_) => const MobileAppBarFixture(
              variant: KMobileAppBarVariant.fixedLine,
            ),
          ),
          WidgetbookUseCase(
            name: 'mobile-app-bar-action',
            builder: (_) =>
                const MobileAppBarFixture(variant: KMobileAppBarVariant.action),
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
            builder: (_) => const BasicComponentFixture(kind: 'breadcrumb'),
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
            builder: (_) => const EditorFixture(markdown: false, mobile: true),
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
            builder: (context) => buildPickerFixture(context, 'date-time'),
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
        name: 'HomeOverview',
        children: [
          WidgetbookUseCase(
            name: 'active-day',
            builder: (_) => const HomeOverviewFixture(),
          ),
          WidgetbookUseCase(
            name: 'new-account',
            builder: (_) => const HomeOverviewFixture(newAccount: true),
          ),
          WidgetbookUseCase(
            name: 'mobile',
            builder: (_) => const HomeOverviewFixture(maxWidth: 390),
          ),
          WidgetbookUseCase(
            name: 'tablet',
            builder: (_) => const HomeOverviewFixture(maxWidth: 1024),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'PlanPicker',
        children: [
          WidgetbookUseCase(
            name: 'single-monthly',
            builder: (_) => const PlanPickerFixture(),
          ),
          WidgetbookUseCase(
            name: 'single-annual',
            builder: (_) => const PlanPickerFixture(annual: true),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'SortableTree',
        children: [
          for (final kind in [
            'categories',
            'mobile',
            'tablet',
            'ungrouped',
            'flat',
            'deep',
            'empty',
          ])
            WidgetbookUseCase(
              name: 'sortable-tree-$kind',
              builder: (_) => SortableTreeFixture(kind: kind),
            ),
        ],
      ),
      WidgetbookFolder(
        name: 'Celebration',
        children: [
          WidgetbookUseCase(
            name: 'celebration-profile-reveal',
            builder: (context) => const CelebrationFixture(),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'ShowcaseGrid',
        children: [
          for (final kind in [
            'hero',
            'mobile',
            'dark',
            'grid-only',
            'reduced-motion',
          ])
            WidgetbookUseCase(
              name: 'showcase-grid-$kind',
              builder: (_) => ShowcaseGridFixture(kind: kind),
            ),
        ],
      ),
      WidgetbookFolder(
        name: 'PaymentSetup',
        children: [
          WidgetbookUseCase(
            name: 'payment-setup-needs-correction',
            builder: (_) => const PaymentSetupFixture(
              state: KPaymentSetupState.needsCorrection,
            ),
          ),
          WidgetbookUseCase(
            name: 'payment-setup-connected',
            builder: (_) =>
                const PaymentSetupFixture(state: KPaymentSetupState.connected),
          ),
          WidgetbookUseCase(
            name: 'payment-setup-action-required',
            builder: (_) => const PaymentSetupFixture(
              state: KPaymentSetupState.actionRequired,
            ),
          ),
          WidgetbookUseCase(
            name: 'payment-setup-pending',
            builder: (_) =>
                const PaymentSetupFixture(state: KPaymentSetupState.pending),
          ),
          WidgetbookUseCase(
            name: 'payment-setup-ready',
            builder: (_) =>
                const PaymentSetupFixture(state: KPaymentSetupState.ready),
          ),
          WidgetbookUseCase(
            name: 'payment-setup-long-content',
            builder: (_) => const PaymentSetupFixture(
              state: KPaymentSetupState.needsCorrection,
              longContent: true,
            ),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'Integrations',
        children: [
          WidgetbookUseCase(
            name: integrationFixtureIds.marketplace,
            builder: (_) => const IntegrationsMarketplaceFixture(),
          ),
          WidgetbookUseCase(
            name: integrationFixtureIds.chatConnection,
            builder: (_) => const IntegrationChatConnectionFixture(),
          ),
          WidgetbookUseCase(
            name: integrationFixtureIds.connectionStates,
            builder: (_) => const IntegrationConnectionStatesFixture(),
          ),
          WidgetbookUseCase(
            name: integrationFixtureIds.adminCatalog,
            builder: (_) => const IntegrationAdminCatalogFixture(),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'Chat Presentations',
        children: [
          WidgetbookUseCase(
            name: 'review',
            builder: (_) => const ChatPresentationsFixture(),
          ),
          WidgetbookUseCase(
            name: 'in-chat',
            builder: (_) => const ChatPresentationsFixture(initialChat: true),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'WebSearch',
        children: [
          WidgetbookUseCase(
            name: 'review',
            builder: (_) => const WebSearchFixture(),
          ),
          WidgetbookUseCase(
            name: 'mobile',
            builder: (_) => const WebSearchFixture(mobile: true),
          ),
          WidgetbookUseCase(
            name: 'running',
            builder: (_) =>
                const WebSearchFixture(state: KWebSearchState.running),
          ),
          WidgetbookUseCase(
            name: 'animated-loading',
            builder: (_) => const WebSearchFixture(
              state: KWebSearchState.running,
              animatedLoading: true,
            ),
          ),
          WidgetbookUseCase(
            name: 'empty',
            builder: (_) => const WebSearchFixture(empty: true),
          ),
          WidgetbookUseCase(
            name: 'error',
            builder: (_) =>
                const WebSearchFixture(state: KWebSearchState.failed),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'FoleySounds',
        children: [
          WidgetbookUseCase(name: 'review', builder: buildFoleySoundsReview),
          WidgetbookUseCase(
            name: 'onboarding',
            builder: (_) => const SoundOnboardingFixture(),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'ChatBubble',
        useCases: [
          WidgetbookUseCase(
            name: 'basic',
            builder: (_) => const ChatBubbleFixture(),
          ),
          WidgetbookUseCase(
            name: 'custom-content',
            builder: (_) => const ChatBubbleFixture(customContent: true),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'BrowserPermissions',
        children: [
          WidgetbookUseCase(
            name: 'Rule Management',
            builder: (_) => const BrowserPermissionsFixture(),
          ),
          WidgetbookUseCase(
            name: 'Empty',
            builder: (_) => const BrowserPermissionsFixture(empty: true),
          ),
          WidgetbookUseCase(
            name: 'Mobile Rules',
            builder: (_) => const BrowserPermissionsFixture(mobile: true),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'BrowserPermissionAsk',
        children: [
          WidgetbookUseCase(
            name: 'browser-permission',
            builder: (_) => const BrowserPermissionAskFixture(),
          ),
          WidgetbookUseCase(
            name: 'browser-permission-once-only',
            builder: (_) => const BrowserPermissionAskFixture(
              state: BrowserPermissionAskState.onceOnly,
            ),
          ),
          WidgetbookUseCase(
            name: 'browser-permission-manual',
            builder: (_) => const BrowserPermissionAskFixture(
              state: BrowserPermissionAskState.manual,
            ),
          ),
          WidgetbookUseCase(
            name: 'browser-permission-submitted',
            builder: (_) => const BrowserPermissionAskFixture(
              state: BrowserPermissionAskState.submitted,
            ),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'BrowserWorkspace',
        children: [
          WidgetbookUseCase(
            name: 'Human Control',
            builder: (_) => const BrowserCardsFixture(
              key: ValueKey('browser-human'),
              initialControl: true,
            ),
          ),
          WidgetbookUseCase(
            name: 'Disconnected',
            builder: (_) => const BrowserCardsFixture(
              key: ValueKey('browser-disconnected'),
              disconnected: true,
            ),
          ),
          WidgetbookUseCase(
            name: 'Watching',
            builder: (_) => const BrowserCardsFixture(),
          ),
          WidgetbookUseCase(
            name: 'Mobile',
            builder: (_) => const BrowserCardsFixture(mobile: true),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'PersonalAgentBrowser',
        children: [
          for (final scenario in [
            'review',
            'permission',
            'human-control',
            'disconnected',
          ])
            WidgetbookUseCase(
              name: scenario,
              builder: (context) => PersonalAgentBrowserFixture(
                key: ValueKey(scenario),
                scenario: scenario,
                fullWidth: context.knobs.boolean(
                  label: 'Full content width',
                  initialValue: false,
                ),
              ),
            ),
        ],
      ),
      WidgetbookFolder(
        name: 'CallBar',
        children: [
          for (final state in [
            'connecting',
            'listening',
            'speaking',
            'muted',
            'ending',
          ])
            WidgetbookUseCase(
              name: 'call-bar-$state',
              builder: (_) =>
                  CallBarFixture(key: ValueKey(state), state: state),
            ),
          WidgetbookUseCase(
            name: 'chat-call-speaking',
            builder: (_) =>
                const CallBarFixture(state: 'speaking', composition: true),
          ),
          WidgetbookUseCase(
            name: 'chat-call-mobile',
            builder: (_) => const SizedBox(
              width: 390,
              child: CallBarFixture(composition: true),
            ),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'AgentChatWorkspace',
        children: [
          WidgetbookUseCase(
            name: AgentChatWorkspaceFixtureNames.empty,
            builder: (_) => const AgentChatWorkspaceFixture(
              kind: AgentChatWorkspaceFixtureKind.empty,
            ),
          ),
          WidgetbookUseCase(
            name: AgentChatWorkspaceFixtureNames.fullScreen,
            builder: (_) => const AgentChatWorkspaceFixture(),
          ),
          WidgetbookUseCase(
            name: AgentChatWorkspaceFixtureNames.needsInput,
            builder: (_) => const AgentChatWorkspaceFixture(
              kind: AgentChatWorkspaceFixtureKind.needsInput,
            ),
          ),
          WidgetbookUseCase(
            name: AgentChatWorkspaceFixtureNames.offline,
            builder: (_) => const AgentChatWorkspaceFixture(
              kind: AgentChatWorkspaceFixtureKind.offline,
            ),
          ),
          WidgetbookUseCase(
            name: AgentChatWorkspaceFixtureNames.mobile,
            builder: (_) => const AgentChatWorkspaceFixture(
              kind: AgentChatWorkspaceFixtureKind.mobile,
            ),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'Workflow',
        children: [
          WidgetbookUseCase(
            name: 'workflow-session-review',
            builder: (_) => const WorkflowSessionFixture(),
          ),
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
            name: 'agent-chat-switcher',
            builder: (_) => const AgentChatSwitcherFixture(),
          ),
          WidgetbookUseCase(
            name: 'agent-switcher-custom-content',
            builder: (context) => AgentSwitcherShowcaseFixture(
              showConnections: context.knobs.boolean(
                label: 'Show connections',
                initialValue: true,
              ),
              showActivity: context.knobs.boolean(
                label: 'Show activity',
                initialValue: true,
              ),
              showUnread: context.knobs.boolean(
                label: 'Show unread',
                initialValue: true,
              ),
              customColors: context.knobs.boolean(
                label: 'Custom colors',
                initialValue: true,
              ),
            ),
          ),
          WidgetbookUseCase(
            name: 'agent-switcher-reorder',
            builder: (_) =>
                const AgentSwitcherShowcaseFixture(reorderable: true),
          ),
          WidgetbookUseCase(
            name: 'agent-switcher-settings',
            builder: (_) => const AgentSwitcherSettingsFixture(),
          ),
          WidgetbookUseCase(
            name: 'chat-composer-controls',
            builder: (_) => const ChatComposerFixture(),
          ),
          WidgetbookUseCase(
            name: 'chat-composer-mobile',
            builder: (_) => const ChatComposerFixture(mobile: true),
          ),
          WidgetbookUseCase(
            name: 'chat-composer-compact-voice',
            builder: (_) => const VoiceComposerFixture(),
          ),
          WidgetbookUseCase(
            name: 'chat-composer-compact-voice-mobile',
            builder: (_) => const VoiceComposerFixture(mobile: true),
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
            builder: (_) => const CompactToolActivityFixture(question: true),
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
            builder: (_) =>
                const AskToolsFixture(kind: AskToolsFixtureKind.textQuestion),
          ),
          WidgetbookUseCase(
            name: 'agent-ui-text-question-dictation',
            builder: (_) => const AgentQuestionDictationFixture(),
          ),
          WidgetbookUseCase(
            name: 'agent-ui-multiple-choice',
            builder: (_) =>
                const AskToolsFixture(kind: AskToolsFixtureKind.multipleChoice),
          ),
          WidgetbookUseCase(
            name: 'agent-ui-confirmation',
            builder: (_) =>
                const AskToolsFixture(kind: AskToolsFixtureKind.confirmation),
          ),
          WidgetbookUseCase(
            name: 'agent-ui-form',
            builder: (_) =>
                const AskToolsFixture(kind: AskToolsFixtureKind.form),
          ),
          WidgetbookUseCase(
            name: 'agent-ui-external-action',
            builder: (_) =>
                const AskToolsFixture(kind: AskToolsFixtureKind.externalAction),
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
        name: 'BookingPageManagement',
        children: [
          for (final v in ['overview', 'dark', 'mobile', 'mobile-dark'])
            WidgetbookUseCase(
              name: v,
              builder: (_) => BookingPageManagementFixture(
                dark: v.contains('dark'),
                mobile: v.contains('mobile'),
              ),
            ),
        ],
      ),
      WidgetbookFolder(
        name: 'OfferOverview',
        children: [
          for (final v in [
            'overview',
            'dark',
            'mobile',
            'mobile-dark',
            'empty',
          ])
            WidgetbookUseCase(
              name: v,
              builder: (_) => OfferOverviewFixture(
                dark: v.contains('dark'),
                empty: v == 'empty',
              ),
            ),
        ],
      ),
      WidgetbookFolder(
        name: 'CatalogEditor',
        children: [
          for (final v in [
            'service',
            'product',
            'service-dark',
            'product-dark',
            'stock',
            'recommendations',
          ])
            WidgetbookUseCase(
              name: v,
              builder: (_) => CatalogEditorFixture(
                product: v.startsWith('product') || v == 'stock',
                dark: v.endsWith('dark'),
                panel: ['stock', 'recommendations'].contains(v) ? v : null,
              ),
            ),
        ],
      ),
      WidgetbookFolder(
        name: 'ManagementOverview',
        children: [
          for (final variant in [
            'overview',
            'dark',
            'draft',
            'empty',
            'long-labels',
          ])
            WidgetbookUseCase(
              name: variant,
              builder: (_) => ManagementOverviewFixture(
                published: !['draft', 'empty'].contains(variant),
                empty: variant == 'empty',
                longLabels: variant == 'long-labels',
                forceDark: variant == 'dark',
              ),
            ),
        ],
      ),
      WidgetbookFolder(
        name: 'UserDashboard',
        children: [
          for (final entry in const [
            ('full-day', 'full'),
            ('free-day', 'free'),
            ('setup', 'fresh'),
            ('ready', 'ready'),
          ])
            WidgetbookUseCase(
              name: entry.$1,
              builder: (_) => UserDashboardReview(
                key: ValueKey(entry.$2),
                scenario: entry.$2,
              ),
            ),
        ],
      ),
      WidgetbookFolder(
        name: 'AdminWorkspace',
        children: [
          for (final page in const [
            'overview',
            'navigation',
            'customers',
            'access',
            'growth',
            'subscriptions',
            'waitlist',
            'invitations',
            'applications',
            'partners',
            'operations',
            'assistant',
            'audit',
          ])
            WidgetbookUseCase(
              name: page,
              builder: (_) => AdminWorkspaceFixture(initialPage: page),
            ),
        ],
      ),

      WidgetbookFolder(
        name: 'SettingsGrouped',
        children: [
          for (final page in [
            'overview',
            'profile',
            'appearance',
            'language',
            'payments',
            'integrations',
            'about',
            'access',
            'access-empty',
            'assistant',
            'server',
          ])
            WidgetbookUseCase(
              name: page,
              builder: (_) => SettingsGroupedFixture(
                initialPage: page == 'overview'
                    ? 'profile'
                    : page == 'access-empty'
                    ? 'access'
                    : page,
                emptyAccess: page == 'access-empty',
                overview: page == 'overview',
              ),
            ),
        ],
      ),
      WidgetbookFolder(
        name: 'AvatarEditor',
        children: [
          WidgetbookUseCase(
            name: 'gallery',
            builder: (_) => const AvatarEditorFixture(),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'NeutralDesign',
        children: [
          WidgetbookUseCase(
            name: 'controls-and-dialog',
            builder: (_) => const NeutralDesignFixture(),
          ),
          WidgetbookUseCase(
            name: 'settings',
            builder: (_) => const SettingsPageFixture(),
          ),
        ],
      ),
      WidgetbookFolder(
        name: 'UsageDetails',
        children: [
          WidgetbookUseCase(
            name: 'usage-details-subscription',
            builder: (_) => const UsageDetailsFixture(),
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
            builder: (_) =>
                const CalendarFixture(initialView: KCalendarView.threeDay),
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
            builder: (_) => const DataTableVirtualFixture(showHeader: true),
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
        name: 'Motion',
        children: [
          WidgetbookUseCase(
            name: 'motion-roles',
            builder: (_) => const MotionRolesFixture(),
          ),
        ],
      ),
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
          WidgetbookUseCase(name: 'icon-lucide', builder: buildIconLucide),
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
                      KLink(label: 'component documentation', onPressed: () {}),
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
          WidgetbookUseCase(name: 'button-states', builder: buildButtonStates),
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
            name: 'typography-balanced-mobile',
            builder: buildTypographyBalancedMobile,
          ),
          WidgetbookUseCase(
            name: 'typography-balanced-tablet',
            builder: buildTypographyBalancedTablet,
          ),
          WidgetbookUseCase(
            name: 'typography-balanced-large-text',
            builder: buildTypographyBalancedLargeText,
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
          WidgetbookUseCase(name: 'surface-tones', builder: buildSurfaceTones),
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
          WidgetbookUseCase(name: 'card-variants', builder: buildCardVariants),
        ],
      ),
    ],
  ),
]);
